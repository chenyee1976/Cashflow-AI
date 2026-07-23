import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExtractedAccountDraft {
  final String bank;
  final String name;
  final String num;
  final String currency;
  final String balance;
  final DateTime balanceAsOf;

  ExtractedAccountDraft({
    required this.bank,
    required this.name,
    required this.num,
    required this.currency,
    required this.balance,
    required this.balanceAsOf,
  });

  Map<String, dynamic> toJson() {
    return {
      'bank': bank,
      'name': name,
      'num': num,
      'currency': currency,
      'balance': balance,
      'balanceAsOf': balanceAsOf.toIso8601String(),
    };
  }

  factory ExtractedAccountDraft.fromJson(Map<String, dynamic> json) {
    return ExtractedAccountDraft(
      bank: json['bank'] as String? ?? '',
      name: json['name'] as String? ?? '',
      num: json['num'] as String? ?? '',
      currency: json['currency'] as String? ?? 'SGD',
      balance: json['balance'] as String? ?? '0.00',
      balanceAsOf: json['balanceAsOf'] != null
          ? DateTime.parse(json['balanceAsOf'] as String)
          : DateTime.now(),
    );
  }
}

class ExtractedRewardRate {
  final String category;
  final String rate;
  final String minSpend;
  final String maxSpend;

  ExtractedRewardRate({
    required this.category,
    required this.rate,
    required this.minSpend,
    required this.maxSpend,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'rate': rate,
      'minSpend': minSpend,
      'maxSpend': maxSpend,
    };
  }

  factory ExtractedRewardRate.fromJson(Map<String, dynamic> json) {
    return ExtractedRewardRate(
      category: json['category'] as String? ?? '',
      rate: json['rate'] as String? ?? '',
      minSpend: json['minSpend'] as String? ?? '',
      maxSpend: json['maxSpend'] as String? ?? '',
    );
  }
}

class ExtractedCreditCardDraft {
  // Section 1
  final String issuer;
  final String cardType;
  final String cardName;
  final String cardNumber;
  
  // Section 2 (Miles)
  final bool hasMiles;
  final String milesOpening;
  final String milesEarned;
  final String milesBonus;
  final String milesRedeemed;
  final String milesEnding;
  final List<ExtractedRewardRate> milesRates;

  // Section 4 (Cashback)
  final bool hasCashback;
  final String cashbackEarned;
  final List<ExtractedRewardRate> cashbackRates;

  // Section 6
  final String totalSpend;
  final DateTime paymentDueDate;

  ExtractedCreditCardDraft({
    required this.issuer,
    required this.cardType,
    required this.cardName,
    required this.cardNumber,
    required this.hasMiles,
    required this.milesOpening,
    required this.milesEarned,
    required this.milesBonus,
    required this.milesRedeemed,
    required this.milesEnding,
    required this.milesRates,
    required this.hasCashback,
    required this.cashbackEarned,
    required this.cashbackRates,
    required this.totalSpend,
    required this.paymentDueDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'issuer': issuer,
      'cardType': cardType,
      'cardName': cardName,
      'cardNumber': cardNumber,
      'hasMiles': hasMiles,
      'milesOpening': milesOpening,
      'milesEarned': milesEarned,
      'milesBonus': milesBonus,
      'milesRedeemed': milesRedeemed,
      'milesEnding': milesEnding,
      'milesRates': milesRates.map((r) => r.toJson()).toList(),
      'hasCashback': hasCashback,
      'cashbackEarned': cashbackEarned,
      'cashbackRates': cashbackRates.map((r) => r.toJson()).toList(),
      'totalSpend': totalSpend,
      'paymentDueDate': paymentDueDate.toIso8601String(),
    };
  }

  factory ExtractedCreditCardDraft.fromJson(Map<String, dynamic> json) {
    return ExtractedCreditCardDraft(
      issuer: json['issuer'] as String? ?? '',
      cardType: json['cardType'] as String? ?? 'Mastercard',
      cardName: json['cardName'] as String? ?? '',
      cardNumber: json['cardNumber'] as String? ?? '',
      hasMiles: json['hasMiles'] as bool? ?? false,
      milesOpening: json['milesOpening'] as String? ?? '',
      milesEarned: json['milesEarned'] as String? ?? '',
      milesBonus: json['milesBonus'] as String? ?? '',
      milesRedeemed: json['milesRedeemed'] as String? ?? '',
      milesEnding: json['milesEnding'] as String? ?? '',
      milesRates: (json['milesRates'] as List? ?? [])
          .map((r) => ExtractedRewardRate.fromJson(r as Map<String, dynamic>))
          .toList(),
      hasCashback: json['hasCashback'] as bool? ?? false,
      cashbackEarned: json['cashbackEarned'] as String? ?? '',
      cashbackRates: (json['cashbackRates'] as List? ?? [])
          .map((r) => ExtractedRewardRate.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalSpend: json['totalSpend'] as String? ?? '',
      paymentDueDate: json['paymentDueDate'] != null
          ? DateTime.parse(json['paymentDueDate'] as String)
          : DateTime.now(),
    );
  }
}

class ExtractedTransactionDraft {
  final String dateStr;
  final String merchant;
  final double amount;
  final String categoryValue;
  final String milesCashbackCategoryValue;
  final String spendCurrency;

  ExtractedTransactionDraft({
    required this.dateStr,
    required this.merchant,
    required this.amount,
    required this.categoryValue,
    this.milesCashbackCategoryValue = 'Others',
    this.spendCurrency = 'SGD Spend',
  });

  Map<String, dynamic> toJson() {
    return {
      'dateStr': dateStr,
      'merchant': merchant,
      'amount': amount,
      'categoryValue': categoryValue,
      'milesCashbackCategoryValue': milesCashbackCategoryValue,
      'spendCurrency': spendCurrency,
    };
  }

  factory ExtractedTransactionDraft.fromJson(Map<String, dynamic> json) {
    return ExtractedTransactionDraft(
      dateStr: json['dateStr'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      categoryValue: json['categoryValue'] as String? ?? 'expense_other',
      milesCashbackCategoryValue: json['milesCashbackCategoryValue'] as String? ?? 'Others',
      spendCurrency: json['spendCurrency'] as String? ?? 'SGD Spend',
    );
  }
}

class DraftStatementData {
  final List<ExtractedAccountDraft> accounts;
  final ExtractedCreditCardDraft? cardDraft;
  final List<ExtractedTransactionDraft> transactions;

  DraftStatementData({
    required this.accounts,
    this.cardDraft,
    required this.transactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'accounts': accounts.map((a) => a.toJson()).toList(),
      if (cardDraft != null) 'cardDraft': cardDraft!.toJson(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory DraftStatementData.fromJson(Map<String, dynamic> json) {
    return DraftStatementData(
      accounts: (json['accounts'] as List? ?? [])
          .map((a) => ExtractedAccountDraft.fromJson(a as Map<String, dynamic>))
          .toList(),
      cardDraft: json['cardDraft'] != null
          ? ExtractedCreditCardDraft.fromJson(json['cardDraft'] as Map<String, dynamic>)
          : null,
      transactions: (json['transactions'] as List? ?? [])
          .map((t) => ExtractedTransactionDraft.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DraftStatementService {
  static const _prefix = 'draft_statement_';

  static Future<void> saveDraft(String statementId, DraftStatementData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toJson());
    await prefs.setString('$_prefix$statementId', jsonStr);
  }

  static Future<DraftStatementData?> loadDraft(String statementId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_prefix$statementId');
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DraftStatementData.fromJson(decoded);
    } catch (e) {
      print('Error parsing draft statement $statementId: $e');
      return null;
    }
  }

  static Future<void> deleteDraft(String statementId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$statementId');
  }
}
