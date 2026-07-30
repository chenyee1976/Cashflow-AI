import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../data/database/app_database.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import '../../../data/services/gemini_extraction_service.dart';
import 'draft_statement_service.dart';
import '../statement/cashflow_provider.dart';
import '../../dashboard/dashboard_provider.dart';
import '../../account/account_provider.dart';

class UploadedStatementItem {
  final String id;
  final String fileName;
  final String status; // 'Awaiting review' | 'Processed'
  final int transactionCount;
  final String institution;
  final String fileType; // 'bank' | 'credit_card'

  const UploadedStatementItem({
    required this.id,
    required this.fileName,
    required this.status,
    required this.transactionCount,
    required this.institution,
    required this.fileType,
  });
}

class UploadState {
  final List<UploadedStatementItem> recentUploads;
  final bool isUploading;
  
  const UploadState({
    this.recentUploads = const [],
    this.isUploading = false,
  });

  UploadState copyWith({
    List<UploadedStatementItem>? recentUploads,
    bool? isUploading,
  }) {
    return UploadState(
      recentUploads: recentUploads ?? this.recentUploads,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;
  UploadNotifier(this._ref) : super(const UploadState()) {
    Future.microtask(() => loadStatements());
  }

  Future<void> loadStatements() async {
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      final db = _ref.read(appDatabaseProvider);
      final storage = _ref.read(secureStorageProvider);
      final userId = await storage.getUserId() ?? 'chenyee_user';

      List<Statement> list = [];
      int retries = 20;
      while (true) {
        try {
          list = await DatabaseMutex.run(() => db.getStatementsByUser(userId));
          break;
        } catch (e) {
          if (retries > 0) {
            retries--;
            await Future.delayed(const Duration(milliseconds: 200));
          } else {
            rethrow;
          }
        }
      }

      // Sort descending by uploadedAt inside Dart memory safely
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      
      print('loadStatements count: ${list.length} for user: $userId');
      final allTxs = await DatabaseMutex.run(() => db.getTransactionsByUser(userId));
      final Map<String, int> txCountMap = {};
      for (final tx in allTxs) {
        if (tx.statementId != null) {
          txCountMap[tx.statementId!] = (txCountMap[tx.statementId!] ?? 0) + 1;
        }
      }

      final mapped = list.map((item) {
        // Always prefer the actual count of transactions in the DB.
        // Fall back to the stored transactionCount only if no DB transactions exist.
        final dbCount = txCountMap[item.id] ?? 0;
        final actualCount = dbCount > 0 ? dbCount : item.transactionCount;

        return UploadedStatementItem(
          id: item.id,
          fileName: item.fileName,
          status: item.status ?? 'Processed',
          transactionCount: actualCount,
          institution: item.bankOrCard ?? 'Unknown',
          fileType: item.fileType,
        );
      }).toList();

      state = state.copyWith(recentUploads: mapped);
    } catch (e, s) {
      print('loadStatements failed with exception: $e\n$s');
      state = state.copyWith(recentUploads: const []);
    }
  }

  Future<String> addStatementDraft({
    required String fileName,
    required String fileType,
    required String institution,
    Uint8List? fileBytes,
  }) async {
    final db = _ref.read(appDatabaseProvider);
    final storage = _ref.read(secureStorageProvider);
    final userId = await storage.getUserId() ?? 'chenyee_user';
    final statementId = const Uuid().v4();

    final rawKey = await storage.getGeminiApiKey();
    final geminiKey = (rawKey != null && rawKey.trim().isNotEmpty)
        ? rawKey.trim()
        : SecureStorageService.defaultGeminiApiKey;

    print('DEBUG addStatementDraft: keyLength=${geminiKey.length}, fileBytesLen=${fileBytes?.length}');
    DraftStatementData? draftData;

    if (fileBytes != null) {
      try {
        String mimeType = 'image/png';
        if (fileName.toLowerCase().endsWith('.pdf')) {
          mimeType = 'application/pdf';
        } else if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        }
        final service = GeminiExtractionService(geminiKey);
        draftData = await service.extractData(fileBytes: fileBytes, mimeType: mimeType);
        print('Real-time Gemini AI extraction succeeded!');
      } catch (e) {
        print('Real-time Gemini extraction failed, creating fallback draft for manual review: $e');
        final isCard = fileType.toLowerCase().contains('card') || fileType.toLowerCase().contains('credit');
        draftData = DraftStatementData(
          accounts: [
            ExtractedAccountDraft(
              bank: isCard ? 'Credit Card Bank' : 'Bank',
              name: fileName,
              num: '****',
              balance: '0.00',
              currency: 'SGD',
              balanceAsOf: DateTime.now(),
            )
          ],
          cardDraft: isCard
              ? ExtractedCreditCardDraft(
                  issuer: 'Card Issuer',
                  cardType: 'Visa',
                  cardName: fileName,
                  cardNumber: '****',
                  hasMiles: false,
                  milesOpening: '0',
                  milesEarned: '0',
                  milesBonus: '0',
                  milesRedeemed: '0',
                  milesEnding: '0',
                  milesRates: [],
                  hasCashback: false,
                  cashbackEarned: '0.00',
                  cashbackRates: [],
                  totalSpend: '0.00',
                  paymentDueDate: DateTime.now().add(const Duration(days: 30)),
                )
              : null,
          transactions: [],
        );
      }
    }

    if (draftData == null) {
      throw Exception('Gemini AI extraction failed or is running in offline mode. No data uploaded.');
    }

    // 2. Save draft content to local persistent storage
    await DraftStatementService.saveDraft(
      statementId,
      draftData,
    );

    // 3. Create Statement row in SQLite with 'Awaiting review' status
    await db.insertStatement(
      StatementsCompanion.insert(
        id: statementId,
        userId: userId,
        fileName: fileName,
        filePath: '',
        fileType: fileType,
        fileSizeBytes: 1024 * 100, // mock size
        status: const drift.Value('Awaiting review'),
        bankOrCard: drift.Value(institution),
        accountType: drift.Value(fileType),
        uploadedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        processedAt: const drift.Value.absent(),
      ),
    );

    // 4. Reload statements to update the list
    await loadStatements();
    return statementId;
  }

  void addSavedStatement(UploadedStatementItem item) {
    final list = state.recentUploads.where((e) => e.id != item.id).toList();
    list.insert(0, item);
    state = state.copyWith(recentUploads: list);
  }

  Future<void> removeUpload(String id) async {
    final db = _ref.read(appDatabaseProvider);
    await db.deleteStatement(id);
    await DraftStatementService.deleteDraft(id);
    
    // Invalidate dashboard, cashflow and account providers to reload states
    _ref.invalidate(cashFlowScreenProvider);
    _ref.invalidate(cashPositionProvider);
    _ref.invalidate(monthlyIncomeProvider);
    _ref.invalidate(monthlyExpensesProvider);
    _ref.invalidate(accountProfileProvider);

    await loadStatements();
  }

  void setUploading(bool isUploading) {
    state = state.copyWith(isUploading: isUploading);
  }
}

final uploadScreenProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref);
});

