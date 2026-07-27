import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../data/database/app_database.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import 'card_rewards_store.dart';
import 'rewards_provider.dart';

class MilesScreenData {
  final double totalMiles;
  final int programCount;
  final List<MilesWalletData> airlinePrograms;
  final List<MilesWalletData> bankPrograms;
  final List<MilesWalletData> otherPrograms;
  final TravelGoal? travelGoal;

  const MilesScreenData({
    required this.totalMiles,
    required this.programCount,
    required this.airlinePrograms,
    required this.bankPrograms,
    required this.otherPrograms,
    this.travelGoal,
  });
}

// Miles core provider
final milesScreenProvider = FutureProvider.autoDispose<MilesScreenData>((ref) async {
  try {
    final db = ref.watch(appDatabaseProvider);
    final storage = ref.watch(secureStorageProvider);
    final userId = await storage.getUserId();

    if (userId == null) {
      return const MilesScreenData(
        totalMiles: 0,
        programCount: 0,
        airlinePrograms: [],
        bankPrograms: [],
        otherPrograms: [],
      );
    }

    final statements = await db.getStatementsByUser(userId);
    final ccStatements = statements.where((s) => s.accountType == 'credit_card').toList();

    // Clean up legacy hardcoded 'kf_wallet' entry
    await (db.delete(db.milesWallet)..where((t) => t.id.equals('kf_wallet'))).go();

    if (ccStatements.isEmpty) {
      await db.transaction(() async {
        await db.delete(db.milesWallet).go();
      });
    } else {
      // Delete stale bank miles wallets before syncing canonical wallets
      await (db.delete(db.milesWallet)..where((t) => t.programType.equals('bank'))).go();

      // Automatically derive and sync miles wallets from credit cards with miles statements
      final rawCards = await db.getCreditCardsByUser(userId);
      
      // Group cards by normalized key
      String _norm(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final Map<String, CreditCard> consolidatedCards = {};
      for (final card in rawCards) {
        final key = '${_norm(card.bankName)}_${_norm(card.cardName)}_${_norm(card.lastFour ?? '')}';
        if (!consolidatedCards.containsKey(key) || card.createdAt > consolidatedCards[key]!.createdAt) {
          consolidatedCards[key] = card;
        }
      }

      for (final card in consolidatedCards.values) {
        if (card.rewardType == 'miles' || card.rewardType == 'points' || card.cardName.contains('PremierMiles')) {
          final savedRewards = await CardRewardsDataStore.loadRewards(card.id);
          double endingMiles = 0.0;
          int statementDate = card.createdAt;

          if (savedRewards != null && savedRewards['milesEnding'] != null) {
            endingMiles = double.tryParse(savedRewards['milesEnding'].toString()) ?? 0.0;
          }

          final cardStatements = ccStatements.where((s) => 
            s.bankOrCard == card.bankName || 
            s.bankOrCard == card.id || 
            s.fileName.toLowerCase().contains(card.bankName.toLowerCase()) ||
            (card.bankName.toLowerCase().contains('citi') && s.fileName.toLowerCase().contains('citi'))
          ).toList();
          final targetStatements = cardStatements.isNotEmpty ? cardStatements : ccStatements;
          if (targetStatements.isNotEmpty) {
            final latest = targetStatements.reduce((a, b) => ((a.periodEnd ?? a.uploadedAt) > (b.periodEnd ?? b.uploadedAt)) ? a : b);
            statementDate = latest.periodEnd ?? latest.uploadedAt;
          }

          if (endingMiles > 0) {
            final cardNameClean = card.cardName.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
            final programName = '${card.bankName} $cardNameClean'.replaceAll(RegExp(r'\s+'), ' ').trim();
            final walletId = 'bank_miles_${_norm(programName)}';

            await db.upsertMilesWallet(
              MilesWalletCompanion.insert(
                id: walletId,
                userId: userId,
                programName: programName,
                programType: 'bank',
                balance: Value(endingMiles),
                lastUpdated: statementDate,
              ),
            );
          }
        }
      }
    }

    final list = await db.getMilesWalletByUser(userId);
    final goal = await db.getTravelGoalByUser(userId);

    final airline = list.where((item) => item.programType == 'airline').toList();
    final bank = list.where((item) => item.programType == 'bank').toList();
    final other = list.where((item) => item.programType == 'other').toList();
    final total = list.fold<double>(0.0, (sum, item) => sum + item.balance);

    return MilesScreenData(
      totalMiles: total,
      programCount: list.length,
      airlinePrograms: airline,
      bankPrograms: bank,
      otherPrograms: other,
      travelGoal: goal,
    );
  } catch (e) {
    return const MilesScreenData(
      totalMiles: 0.0,
      programCount: 0,
      airlinePrograms: [],
      bankPrograms: [],
      otherPrograms: [],
    );
  }
});

// Miles write operations
class MilesOperations {
  final AppDatabase _db;
  final Ref _ref;

  MilesOperations(this._db, this._ref);

  Future<void> addLoyaltyProgram({
    required String programName,
    required String programType, // 'airline' | 'bank'
    required int balance,
  }) async {
    final storage = _ref.read(secureStorageProvider);
    final userId = await storage.getUserId() ?? 'unknown_user';

    await _db.upsertMilesWallet(
      MilesWalletCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        programName: programName,
        programType: programType,
        balance: Value(balance.toDouble()),
        lastUpdated: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );

    _ref.invalidate(milesScreenProvider);
  }

  Future<void> upsertTravelGoal({
    required String destination,
    required int targetMiles,
  }) async {
    final storage = _ref.read(secureStorageProvider);
    final userId = await storage.getUserId() ?? 'unknown_user';

    await _db.upsertTravelGoal(
      TravelGoalsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        destination: destination,
        airline: 'Any Airline',
        cabinClass: 'business',
        milesRequired: targetMiles.toDouble(),
        milesCurrent: const Value(0.0),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );

    _ref.invalidate(milesScreenProvider);
  }

  Future<void> updateLoyaltyProgram({
    required String id,
    required String userId,
    required String programName,
    required String programType,
    required double balance,
  }) async {
    await _db.upsertMilesWallet(
      MilesWalletCompanion.insert(
        id: id,
        userId: userId,
        programName: programName,
        programType: programType,
        balance: Value(balance),
        lastUpdated: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );

    _ref.invalidate(milesScreenProvider);
  }

  Future<void> deleteLoyaltyProgram(String id) async {
    await (_db.delete(_db.milesWallet)..where((t) => t.id.equals(id))).go();
    _ref.invalidate(milesScreenProvider);
  }
}

final milesOperationsProvider = Provider((ref) {
  return MilesOperations(ref.watch(appDatabaseProvider), ref);
});
