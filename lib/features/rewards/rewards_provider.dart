import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import '../../data/services/card_rules_registry.dart';
import 'card_rewards_store.dart';

class RewardCardData {
  final String cardId;
  final String cardName;
  final String bankName;
  final String lastFour;
  final String rewardType; // 'miles' | 'cashback' | 'points'

  // Miles fields
  final double milesOpening;
  final double milesEarnedStatement;
  final double milesBonus;
  final double milesRedeemed;
  final double milesEnding;
  double milesEarnedRate; // e.g. 1.2 miles per S$1
  String milesRateType; // 'all_spend' | 'local_spend' | 'foreign_spend'
  double milesMinSpend;
  double milesMaxSpend;
  final double cardSpendThisMonth;
  final List<Map<String, dynamic>> milesRates;
  final List<Transaction> transactions;

  double get calculatedMiles {
    if (milesEarnedStatement > 0 || milesBonus > 0) {
      return milesEarnedStatement + milesBonus;
    }

    final rule = CardRulesRegistry.getRule(bankName, cardName);
    if (transactions.isNotEmpty && milesRates.isNotEmpty) {
      double sum = 0.0;
      for (final tx in transactions) {
        final rate = getMilesRateForTx(tx);
        double amt = tx.amount.abs();
        
        if (rule.floorSpendToDollar) {
          amt = (amt / rule.spendBlock).floorToDouble() * rule.spendBlock;
        }
        
        final rawMiles = amt * rate;
        double finalMiles;
        switch (rule.roundingMethod) {
          case RoundingMethod.nearest:
            finalMiles = rawMiles.roundToDouble();
            break;
          case RoundingMethod.floor:
            finalMiles = rawMiles.floorToDouble();
            break;
          case RoundingMethod.ceil:
            finalMiles = rawMiles.ceilToDouble();
            break;
          case RoundingMethod.keepDecimal:
            finalMiles = double.parse(rawMiles.toStringAsFixed(2));
            break;
        }
        sum += finalMiles;
      }
      return sum;
    }
    
    double totalAmt = cardSpendThisMonth;
    if (rule.floorSpendToDollar) {
      totalAmt = (totalAmt / rule.spendBlock).floorToDouble() * rule.spendBlock;
    }
    return totalAmt * milesEarnedRate;
  }

  double getMilesRateForTx(Transaction tx) {
    final currency = (tx.currency ?? '').toLowerCase();
    if (currency.contains('receipt')) return 0.0;
    if (milesRates.isEmpty) return milesEarnedRate;
    
    // Check foreign spend first
    final isForeign = currency.contains('fcy') || currency.contains('foreign') || (!currency.contains('sgd') && currency.isNotEmpty);
    if (isForeign) {
      final match = milesRates.firstWhere(
        (r) => r['category'].toString().toLowerCase().contains('fcy') ||
               r['category'].toString().toLowerCase().contains('foreign'),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        return double.tryParse(match['rate']?.toString() ?? '') ?? milesEarnedRate;
      }
    }
    
    // Check for specific category match
    final category = tx.category.toLowerCase();
    final match = milesRates.firstWhere(
      (r) => r['category'].toString().toLowerCase() == category,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      return double.tryParse(match['rate']?.toString() ?? '') ?? milesEarnedRate;
    }
    
    // Default to SGD/All spend
    final normalMatch = milesRates.firstWhere(
      (r) => r['category'].toString().toLowerCase().contains('sgd') ||
             r['category'].toString().toLowerCase().contains('all'),
      orElse: () => <String, dynamic>{},
    );
    if (normalMatch.isNotEmpty) {
      return double.tryParse(normalMatch['rate']?.toString() ?? '') ?? milesEarnedRate;
    }
    
    return milesEarnedRate;
  }

  // Cashback fields
  final double cashbackEarnedStatement;
  double cashbackRate; // e.g. 0.03 = 3%
  String cashbackRateCategory; // 'all_spend' | 'groceries' | 'travel' | custom
  double cashbackMinSpend;
  double cashbackMaxSpend;
  final List<Map<String, dynamic>> cashbackRates;

  double get calculatedCashback {
    final rule = CardRulesRegistry.getRule(bankName, cardName);
    final isYuu = cardName.toLowerCase().contains('yuu');

    if (isYuu) {
      double basePointsSum = 0.0;
      double bonus1PointsSum = 0.0;
      double bonus2PointsSum = 0.0;

      final yuuMerchantKeywords = [
        '7-eleven', '7eleven', 'chagee', 'charge+', 'cold storage',
        'foodpanda', 'giant', 'guardian', 'gojek', 'singtel', 'simplygo'
      ];

      for (final tx in transactions) {
        if (tx.amount >= 0) continue; // Positive figures (payments/credits/autopay) do not earn rewards

        final amt = tx.amount.abs();
        final merchantLower = tx.merchant.toLowerCase();

        // Base reward: 1 point per $1
        basePointsSum += double.parse((amt * 1.0).toStringAsFixed(2));

        // Check Yuu bonus merchant
        final isYuuMerchant = yuuMerchantKeywords.any((kw) => merchantLower.contains(kw));
        if (isYuuMerchant) {
          bonus1PointsSum += double.parse((amt * 9.0).toStringAsFixed(2));
          if (cardSpendThisMonth >= 800.0) {
            bonus2PointsSum += double.parse((amt * 26.0).toStringAsFixed(2));
          }
        }
      }
      return basePointsSum + bonus1PointsSum + bonus2PointsSum;
    }

    if (transactions.isNotEmpty && cashbackRates.isNotEmpty) {
      double sum = 0.0;
      for (final tx in transactions) {
        final rate = getRateForTx(tx);
        double amt = tx.amount.abs();
        
        if (rule.floorSpendToDollar) {
          amt = (amt / rule.spendBlock).floorToDouble() * rule.spendBlock;
        }
        
        final rawCashback = amt * rate;
        double finalCashback;
        switch (rule.roundingMethod) {
          case RoundingMethod.nearest:
            finalCashback = rawCashback.roundToDouble();
            break;
          case RoundingMethod.floor:
            finalCashback = rawCashback.floorToDouble();
            break;
          case RoundingMethod.ceil:
            finalCashback = rawCashback.ceilToDouble();
            break;
          case RoundingMethod.keepDecimal:
            finalCashback = double.parse(rawCashback.toStringAsFixed(2));
            break;
        }
        sum += finalCashback;
      }
      return sum;
    }
    
    double totalAmt = cardSpendThisMonth;
    if (rule.floorSpendToDollar) {
      totalAmt = (totalAmt / rule.spendBlock).floorToDouble() * rule.spendBlock;
    }
    return totalAmt * cashbackRate;
  }

  double getRateForTx(Transaction tx) {
    final currency = (tx.currency ?? '').toLowerCase();
    if (currency.contains('receipt')) return 0.0;
    if (cashbackRates.isEmpty) return cashbackRate;
    final category = tx.category.toLowerCase();

    if (currency.contains('fcy') || currency.contains('foreign') || currency != 'sgd') {
      final match = cashbackRates.firstWhere(
        (r) => r['category'].toString().toLowerCase().contains('fcy') ||
               r['category'].toString().toLowerCase().contains('foreign'),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        final r = double.tryParse(match['rate']?.toString() ?? '0') ?? 0.0;
        return r > 1.0 ? r / 100.0 : r;
      }
    }

    if (currency.contains('myr')) {
      final match = cashbackRates.firstWhere(
        (r) => r['category'].toString().toLowerCase().contains('myr'),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        final r = double.tryParse(match['rate']?.toString() ?? '0') ?? 0.0;
        return r > 1.0 ? r / 100.0 : r;
      }
    }

    final match = cashbackRates.firstWhere(
      (r) {
        final cat = r['category'].toString().toLowerCase();
        return cat == category || category.contains(cat) || cat.contains(category);
      },
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      final r = double.tryParse(match['rate']?.toString() ?? '0') ?? 0.0;
      return r > 1.0 ? r / 100.0 : r;
    }

    final defaultRate = cashbackRates.firstWhere(
      (r) => r['category'].toString().toLowerCase().contains('sgd') ||
             r['category'].toString().toLowerCase().contains('all'),
      orElse: () => cashbackRates.first,
    );
    final r = double.tryParse(defaultRate['rate']?.toString() ?? '0') ?? 0.0;
    return r > 1.0 ? r / 100.0 : r;
  }

  RewardCardData({
    required this.cardId,
    required this.cardName,
    required this.bankName,
    required this.lastFour,
    required this.rewardType,
    this.milesOpening = 0.0,
    this.milesEarnedStatement = 0.0,
    this.milesBonus = 0.0,
    this.milesRedeemed = 0.0,
    this.milesEnding = 0.0,
    this.milesEarnedRate = 1.2,
    this.milesRateType = 'all_spend',
    this.milesMinSpend = 0.0,
    this.milesMaxSpend = 0.0,
    this.cardSpendThisMonth = 0.0,
    this.milesRates = const [],
    this.cashbackEarnedStatement = 0.0,
    this.cashbackRate = 0.0,
    this.cashbackRateCategory = 'all_spend',
    this.cashbackMinSpend = 0.0,
    this.cashbackMaxSpend = 0.0,
    this.cashbackRates = const [],
    this.transactions = const [],
  });
}

// Selected month for rewards view
final rewardsMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(2026, 7);
});

// Rewards data provider
final rewardsCardsProvider = FutureProvider.autoDispose<List<RewardCardData>>((ref) async {
  try {
    final selectedMonth = ref.watch(rewardsMonthProvider);
    final db = ref.watch(appDatabaseProvider);
    final storage = ref.watch(secureStorageProvider);
    final userId = await storage.getUserId();

    if (userId == null) return [];

    final rawCards = await db.getCreditCardsByUser(userId);
    final allTxs = await db.getTransactionsByUser(userId);
    final allStatements = await db.getStatementsByUser(userId);

    // Build statement lookup map
    final Map<String, Statement> statementMap = {
      for (final s in allStatements) s.id: s
    };

    // Filter transactions for the selected month and credit card accounts
    // Group transaction into the selected month if it belongs to a statement whose periodEnd is in this selected month.
    // If it has no statementId, fallback to the transaction's own calendar month.
    final monthTxs = allTxs.where((t) {
      if (t.accountType != 'credit_card') return false;
      if (t.statementId != null && statementMap.containsKey(t.statementId)) {
        final s = statementMap[t.statementId]!;
        final sDate = DateTime.fromMillisecondsSinceEpoch((s.periodEnd ?? s.uploadedAt) * 1000);
        return sDate.year == selectedMonth.year && sDate.month == selectedMonth.month;
      }
      final txDate = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
      return txDate.year == selectedMonth.year && txDate.month == selectedMonth.month;
    }).toList();

    // Consolidate duplicate cards (same bank, card name, and lastFour)
    String _norm(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final Map<String, CreditCard> uniqueCardsMap = {};
    for (final card in rawCards) {
      final key = '${_norm(card.bankName)}_${_norm(card.cardName)}_${_norm(card.lastFour ?? '')}';
      if (!uniqueCardsMap.containsKey(key)) {
        uniqueCardsMap[key] = card;
      } else {
        // Keep the one with the latest creation time or statement connection
        final existing = uniqueCardsMap[key]!;
        if (card.createdAt > existing.createdAt) {
          uniqueCardsMap[key] = card;
        }
      }
    }
    final consolidatedCards = uniqueCardsMap.values.toList();

    // Map all duplicate card IDs to the canonical representation card ID
    final Map<String, String> duplicateToCanonicalId = {};
    for (final card in rawCards) {
      final key = '${_norm(card.bankName)}_${_norm(card.cardName)}_${_norm(card.lastFour ?? '')}';
      duplicateToCanonicalId[card.id] = uniqueCardsMap[key]!.id;
    }

    final List<RewardCardData> results = [];

    for (final card in consolidatedCards) {
      // Calculate total spend by summing transactions across all duplicate/canonical card instances
      final cardTxs = monthTxs.where((t) => duplicateToCanonicalId[t.accountId] == card.id).toList();
      final spendTxs = cardTxs.where((t) => !(t.currency ?? '').toLowerCase().contains('receipt')).toList();
      final totalSpend = spendTxs.fold<double>(0.0, (sum, t) => sum + t.amount.abs());

      // Load saved reward data (try canonical first, fallback to duplicate instances if needed)
      final monthStatementTxs = cardTxs.where((t) => t.statementId != null).toList();
      final statementId = monthStatementTxs.isNotEmpty ? monthStatementTxs.first.statementId : null;
      var savedRewards = await CardRewardsDataStore.loadRewards(card.id, statementId: statementId);
      if (savedRewards == null || (savedRewards['cashbackRates'] as List?)?.isEmpty == true) {
        for (final entry in duplicateToCanonicalId.entries) {
          if (entry.value == card.id && entry.key != card.id) {
            final otherRewards = await CardRewardsDataStore.loadRewards(entry.key, statementId: statementId);
            if (otherRewards != null && (otherRewards['cashbackRates'] as List?)?.isNotEmpty == true) {
              savedRewards = otherRewards;
              break;
            }
          }
        }
      }
      print('REWARDS_DEBUG: card.id=${card.id}, card.cardName=${card.cardName}, savedRewards=$savedRewards');

      double cashbackEarnedStatement = 0.0;
      double cashbackRateVal = 0.0;
      String cashbackCategory = 'all_spend';
      double cashbackMinSpendVal = 0.0;
      double cashbackMaxSpendVal = 0.0;
      List<Map<String, dynamic>> cashbackRatesList = [];

      double milesEarnedStatement = 0.0;
      double milesOpeningVal = card.cardName.contains('PremierMiles') ? 104889.0 : 0.0;
      double milesBonusVal = 0.0;
      double milesRedeemedVal = 0.0;
      double milesEndingVal = 0.0;
      double milesEarnedRateVal = 1.2;
      String milesRateTypeVal = 'all_spend';
      double milesMinSpendVal = 0.0;
      double milesMaxSpendVal = 0.0;
      List<Map<String, dynamic>> milesRatesList = [];

      // Check if a statement was actually uploaded for this card and this month
      // By mapping all transactions belonging to this statement into the selected month,
      // hasStatement check becomes robust.
      final hasStatement = cardTxs.any((t) => t.statementId != null);

      if (!hasStatement) {
        continue;
      }

      if (savedRewards != null) {
        cashbackEarnedStatement = hasStatement 
            ? (savedRewards['cashbackEarnedStatement'] as num? ?? 0.0).toDouble()
            : 0.0;
        print('REWARDS_DEBUG: loaded cashbackEarnedStatement=$cashbackEarnedStatement');
        if (savedRewards['cashbackRates'] != null) {
          final rawRates = savedRewards['cashbackRates'] as List<dynamic>;
          cashbackRatesList = rawRates.map((r) => Map<String, dynamic>.from(r as Map)).toList();
          if (cashbackRatesList.isNotEmpty) {
            final first = cashbackRatesList.first;
            final rStr = first['rate']?.toString() ?? '0';
            final r = double.tryParse(rStr) ?? 0.0;
            cashbackRateVal = r > 1.0 ? r / 100.0 : r;
            cashbackCategory = first['category']?.toString() ?? 'all_spend';
            cashbackMinSpendVal = double.tryParse(first['minSpend']?.toString() ?? '') ?? 0.0;
            cashbackMaxSpendVal = double.tryParse(first['maxSpend']?.toString() ?? '') ?? 0.0;
          }
        }

        milesEarnedStatement = hasStatement 
            ? (savedRewards['milesEarnedStatement'] as num? ?? 0.0).toDouble()
            : 0.0;
        if (savedRewards['milesOpening'] != null) {
          milesOpeningVal = double.tryParse(savedRewards['milesOpening'].toString()) ?? milesOpeningVal;
        }
        if (savedRewards['milesBonus'] != null) {
          milesBonusVal = double.tryParse(savedRewards['milesBonus'].toString()) ?? 0.0;
        }
        if (savedRewards['milesRedeemed'] != null) {
          milesRedeemedVal = double.tryParse(savedRewards['milesRedeemed'].toString()) ?? 0.0;
        }
        if (savedRewards['milesEnding'] != null) {
          milesEndingVal = double.tryParse(savedRewards['milesEnding'].toString()) ?? 0.0;
        }

        if (savedRewards['milesRates'] != null) {
          final rawRates = savedRewards['milesRates'] as List<dynamic>;
          milesRatesList = rawRates.map((r) => Map<String, dynamic>.from(r as Map)).toList();
          if (milesRatesList.isNotEmpty) {
            final first = milesRatesList.first;
            milesEarnedRateVal = double.tryParse(first['rate']?.toString() ?? '1.2') ?? 1.2;
            milesRateTypeVal = first['category']?.toString() ?? 'all_spend';
            milesMinSpendVal = double.tryParse(first['minSpend']?.toString() ?? '') ?? 0.0;
            milesMaxSpendVal = double.tryParse(first['maxSpend']?.toString() ?? '') ?? 0.0;
          }
        }
      } else {
        // Fallback defaults
        if (card.cardName.contains('PremierMiles')) {
          milesEarnedStatement = 465;
          milesOpeningVal = 104889;
          milesBonusVal = 203;
          milesRedeemedVal = 0;
          milesEndingVal = 105354;
          milesEarnedRateVal = 1.2;
          milesRatesList = [
            {'category': 'SGD Spend', 'rate': '1.2', 'minSpend': '', 'maxSpend': ''},
            {'category': 'Foreign Currency Spend', 'rate': '2.0', 'minSpend': '', 'maxSpend': ''}
          ];
        } else if (card.bankName.toLowerCase().contains('mari') || card.cardName.toLowerCase().contains('mari')) {
          cashbackEarnedStatement = 0.0;
          cashbackRateVal = 0.015;
          cashbackCategory = 'SGD Spend';
          cashbackRatesList = [
            {'category': 'SGD Spend', 'rate': '1.5', 'minSpend': '0', 'maxSpend': ''},
            {'category': 'FCY spend', 'rate': '3.0', 'minSpend': '0', 'maxSpend': ''}
          ];
        }
      }

      if (!hasStatement) {
        cashbackEarnedStatement = 0.0;
        milesEarnedStatement = 0.0;
      }

      results.add(RewardCardData(
        cardId: card.id,
        cardName: card.cardName,
        bankName: card.bankName,
        lastFour: card.lastFour ?? '****',
        rewardType: card.rewardType,
        milesOpening: milesOpeningVal,
        milesEarnedStatement: milesEarnedStatement,
        milesBonus: milesBonusVal,
        milesRedeemed: milesRedeemedVal,
        milesEnding: milesEndingVal,
        milesEarnedRate: milesEarnedRateVal,
        milesRateType: milesRateTypeVal,
        milesMinSpend: milesMinSpendVal,
        milesMaxSpend: milesMaxSpendVal,
        milesRates: milesRatesList,
        cardSpendThisMonth: totalSpend,
        cashbackEarnedStatement: cashbackEarnedStatement,
        cashbackRate: cashbackRateVal,
        cashbackRateCategory: cashbackCategory,
        cashbackMinSpend: cashbackMinSpendVal,
        cashbackMaxSpend: cashbackMaxSpendVal,
        cashbackRates: cashbackRatesList,
        transactions: cardTxs,
      ));
    }

    return results;
  } catch (e) {
    return [];
  }
});

// User reward focus preference
final rewardFocusProvider = FutureProvider.autoDispose<String>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await storage.getRewardFocus() ?? 'both';
});
