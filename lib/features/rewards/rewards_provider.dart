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

    bool isBillPayment(Transaction t) {
      final m = t.merchant.toLowerCase();
      final c = (t.category ?? '').toLowerCase();
      return m.contains('payment by giro') ||
             m.contains('giro pymt') ||
             m.contains('giro payment') ||
             m.contains('ibank payment') ||
             m.contains('fast payment') ||
             m.contains('cash payment') ||
             m.contains('autopay') ||
             m.contains('thank you - payment') ||
             m.contains('payment received') ||
             m.startsWith('payment ') ||
             m == 'payment' ||
             c == 'payment' ||
             c == 'bill payment';
    }

    final rule = CardRulesRegistry.getRule(bankName, cardName);
    if (transactions.isNotEmpty && milesRates.isNotEmpty) {
      double sum = 0.0;
      for (final tx in transactions) {
        if (isBillPayment(tx)) continue;
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
        if (tx.amount < 0) {
          sum += finalMiles;
        } else {
          sum -= finalMiles;
        }
      }
      return sum < 0 ? 0.0 : sum;
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

    final isMaybankFnF = bankName.toLowerCase().contains('maybank') || cardName.toLowerCase().contains('family');

    if (isMaybankFnF) {
      bool isRepaymentOrCashback(Transaction t) {
        if (t.amount <= 0) return false;
        final expCat = (t.category ?? '').toLowerCase();
        final m = t.merchant.toLowerCase();

        final isRepayment = expCat.contains('repayment') ||
                            expCat.contains('transfer') ||
                            expCat.contains('card payment') ||
                            expCat.contains('bill payment') ||
                            expCat == 'payment' ||
                            m.contains('payment by giro') ||
                            m.contains('giro pymt') ||
                            m.contains('giro payment') ||
                            m.contains('autopay') ||
                            m.contains('thank you - payment') ||
                            m.contains('payment received');

        final isCashbackReceived = expCat.contains('cashback') ||
                                   expCat.contains('rebate') ||
                                   expCat.contains('reward credit') ||
                                   m.contains('cashback') ||
                                   m.contains('rebate');

        return isRepayment || isCashbackReceived;
      }

      final validTxs = transactions.where((t) => !isRepaymentOrCashback(t)).toList();
      final totalSpend = cardSpendThisMonth;

      // 1. Base Reward: Total spend * 0.22%
      final baseReward = totalSpend * 0.0022;

      final catSpends = <String, double>{
        'MYR Spend': 0.0,
        'IDR Spend': 0.0,
        'Commute': 0.0,
        'Dining & Food Delivery': 0.0,
        'Groceries': 0.0,
        'Online Shopping': 0.0,
        'Telco & Streaming': 0.0,
      };

      for (final tx in validTxs) {
        final cat = (tx.category ?? '').toLowerCase();
        final merchant = (tx.merchant ?? '').toLowerCase();
        final currency = (tx.currency ?? '').toLowerCase();
        // Outflow (amount < 0) -> +spend. Vendor Refund (amount > 0) -> -spend.
        final netAmt = tx.amount < 0 ? tx.amount.abs() : -tx.amount.abs();

        if (currency.contains('myr')) {
          catSpends['MYR Spend'] = (catSpends['MYR Spend'] ?? 0.0) + netAmt;
        } else if (currency.contains('idr')) {
          catSpends['IDR Spend'] = (catSpends['IDR Spend'] ?? 0.0) + netAmt;
        } else if (cat.contains('commute') || merchant.contains('bus/mrt')) {
          catSpends['Commute'] = (catSpends['Commute'] ?? 0.0) + netAmt;
        } else if (cat.contains('dining') || cat.contains('food') || merchant.contains('mcdonalds') || merchant.contains('kopitiam') || merchant.contains('grab') || merchant.contains('kfc') || merchant.contains('hainan') || merchant.contains('coffee')) {
          catSpends['Dining & Food Delivery'] = (catSpends['Dining & Food Delivery'] ?? 0.0) + netAmt;
        } else if (cat.contains('grocer') || merchant.contains('sheng siong') || merchant.contains('fairprice') || merchant.contains('giant') || merchant.contains('prime supermarket') || merchant.contains('cheers') || merchant.contains('cold storage')) {
          catSpends['Groceries'] = (catSpends['Groceries'] ?? 0.0) + netAmt;
        } else if (cat.contains('online') || merchant.contains('shopee') || merchant.contains('pinduoduo') || merchant.contains('taobao')) {
          catSpends['Online Shopping'] = (catSpends['Online Shopping'] ?? 0.0) + netAmt;
        } else if (cat.contains('telco') || cat.contains('streaming') || merchant.contains('m1') || merchant.contains('whiz') || merchant.contains('simba') || merchant.contains('vivifi') || merchant.contains('eight telecom')) {
          catSpends['Telco & Streaming'] = (catSpends['Telco & Streaming'] ?? 0.0) + netAmt;
        }
      }

      double bonusTier1Total = 0.0;
      double bonusTier2Total = 0.0;

      if (totalSpend >= 1600.0) {
        catSpends.forEach((catLabel, catAmt) {
          if (catAmt > 0) {
            final rate = catLabel == 'Groceries' ? 0.06 : 0.08;
            bonusTier2Total += catAmt * rate;
          }
        });
      } else if (totalSpend >= 800.0) {
        catSpends.forEach((catLabel, catAmt) {
          if (catAmt > 0) {
            bonusTier1Total += catAmt * 0.06;
          }
        });
      }

      return baseReward + bonusTier1Total + bonusTier2Total;
    }

    if (transactions.isNotEmpty && cashbackRates.isNotEmpty) {
      bool isBillPayment(Transaction t) {
        final m = t.merchant.toLowerCase();
        final c = (t.category ?? '').toLowerCase();
        return m.contains('payment by giro') ||
               m.contains('giro pymt') ||
               m.contains('giro payment') ||
               m.contains('ibank payment') ||
               m.contains('fast payment') ||
               m.contains('cash payment') ||
               m.contains('autopay') ||
               m.contains('thank you - payment') ||
               m.contains('payment received') ||
               m.startsWith('payment ') ||
               m == 'payment' ||
               c == 'payment' ||
               c == 'bill payment';
      }

      double sum = 0.0;
      for (final tx in transactions) {
        if (isBillPayment(tx)) continue;
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
        if (tx.amount < 0) {
          sum += finalCashback;
        } else {
          sum -= finalCashback;
        }
      }
      return sum < 0 ? 0.0 : sum;
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

    if (currency.contains('idr')) {
      final match = cashbackRates.firstWhere(
        (r) => r['category'].toString().toLowerCase().contains('idr'),
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

    // Step 1: Find all credit card statements for the selected month
    final monthCCStatements = allStatements.where((s) {
      final isCC = s.fileType == 'credit_card' || s.accountType == 'credit_card';
      if (!isCC) return false;
      final sDate = DateTime.fromMillisecondsSinceEpoch((s.periodEnd ?? s.uploadedAt) * 1000);
      return sDate.year == selectedMonth.year && sDate.month == selectedMonth.month;
    }).toList();

    // Step 2: If NO credit card statements exist for this month, return an empty list immediately!
    if (monthCCStatements.isEmpty) {
      return [];
    }

    // Step 3: Filter transactions for the selected month and credit card accounts
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
        final existing = uniqueCardsMap[key]!;
        if (card.createdAt > existing.createdAt) {
          uniqueCardsMap[key] = card;
        }
      }
    }
    final consolidatedCards = uniqueCardsMap.values.toList();

    final Map<String, String> duplicateToCanonicalId = {};
    for (final card in rawCards) {
      final key = '${_norm(card.bankName)}_${_norm(card.cardName)}_${_norm(card.lastFour ?? '')}';
      duplicateToCanonicalId[card.id] = uniqueCardsMap[key]!.id;
    }

    final List<RewardCardData> results = [];

    for (final card in consolidatedCards) {
      final cardTxs = monthTxs.where((t) => duplicateToCanonicalId[t.accountId] == card.id).toList();
      double totalSpend = 0.0;
      for (final t in cardTxs) {
        if (t.amount > 0) {
          final expCat = (t.category ?? '').toLowerCase();
          final m = t.merchant.toLowerCase();
          final isRepayment = expCat.contains('repayment') ||
                              expCat.contains('transfer') ||
                              expCat.contains('card payment') ||
                              expCat.contains('bill payment') ||
                              expCat == 'payment' ||
                              m.contains('payment by giro') ||
                              m.contains('giro pymt') ||
                              m.contains('giro payment') ||
                              m.contains('autopay') ||
                              m.contains('thank you - payment') ||
                              m.contains('payment received');

          final isCashbackReceived = expCat.contains('cashback') ||
                                     expCat.contains('rebate') ||
                                     expCat.contains('reward credit') ||
                                     m.contains('cashback') ||
                                     m.contains('rebate');

          if (isRepayment || isCashbackReceived) {
            // Case 1 & 2: Repayment back to card or Cashback Received -> NOT SPEND
            continue;
          }
        }

        if (t.amount < 0) {
          totalSpend += t.amount.abs();
        } else {
          // Case 3: Vendor Refund -> REDUCTION TO SPEND
          totalSpend -= t.amount.abs();
        }
      }
      if (totalSpend < 0) totalSpend = 0.0;

      final hasStatementForThisMonth = monthCCStatements.any((s) =>
        s.id == card.sourceStatementId ||
        s.bankOrCard == card.id ||
        cardTxs.any((t) => t.statementId == s.id)
      );

      if (!hasStatementForThisMonth) {
        continue;
      }

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

      double cashbackEarnedStatement = 0.0;
      double cashbackRateVal = 0.0;
      String cashbackCategory = 'all_spend';
      double cashbackMinSpendVal = 0.0;
      double cashbackMaxSpendVal = 0.0;
      List<Map<String, dynamic>> cashbackRatesList = [];

      double milesEarnedStatement = 0.0;
      double milesOpeningVal = 0.0;
      double milesBonusVal = 0.0;
      double milesRedeemedVal = 0.0;
      double milesEndingVal = 0.0;
      double milesEarnedRateVal = 1.2;
      String milesRateTypeVal = 'all_spend';
      double milesMinSpendVal = 0.0;
      double milesMaxSpendVal = 0.0;
      List<Map<String, dynamic>> milesRatesList = [];

      final hasStatement = hasStatementForThisMonth;

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
        // Strict user saved rates load: card rules registry is used if no user overrides exist
        final rule = CardRulesRegistry.getRule(card.bankName, card.cardName);
        for (final r in rule.defaultRatesList) {
          if (card.rewardType == 'miles' || card.rewardType == 'points') {
            milesRatesList.add({
              'category': r['category']?.toString() ?? 'SGD Spend',
              'rate': r['rate']?.toString() ?? '1.2',
              'minSpend': r['minSpend']?.toString() ?? '',
              'maxSpend': r['maxSpend']?.toString() ?? '',
            });
          } else {
            cashbackRatesList.add({
              'category': r['category']?.toString() ?? 'SGD Spend',
              'rate': r['rate']?.toString() ?? '1.0',
              'minSpend': r['minSpend']?.toString() ?? '',
              'maxSpend': r['maxSpend']?.toString() ?? '',
            });
          }
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
