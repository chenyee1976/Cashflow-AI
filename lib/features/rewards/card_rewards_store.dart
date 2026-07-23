import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CardRewardsDataStore {
  static Future<void> saveRewards({
    required String cardId,
    String? statementId,
    required double cashbackEarnedStatement,
    required List<Map<String, dynamic>> cashbackRates,
    required double milesEarnedStatement,
    required List<Map<String, dynamic>> milesRates,
    String? totalSpend,
    String? paymentDueDate,
    String? milesOpening,
    String? milesBonus,
    String? milesRedeemed,
    String? milesEnding,
    bool? hasMiles,
    bool? hasCashback,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'cashbackEarnedStatement': cashbackEarnedStatement,
      'cashbackRates': cashbackRates,
      'milesEarnedStatement': milesEarnedStatement,
      'milesRates': milesRates,
      if (totalSpend != null) 'totalSpend': totalSpend,
      if (paymentDueDate != null) 'paymentDueDate': paymentDueDate,
      if (milesOpening != null) 'milesOpening': milesOpening,
      if (milesBonus != null) 'milesBonus': milesBonus,
      if (milesRedeemed != null) 'milesRedeemed': milesRedeemed,
      if (milesEnding != null) 'milesEnding': milesEnding,
      if (hasMiles != null) 'hasMiles': hasMiles,
      if (hasCashback != null) 'hasCashback': hasCashback,
    };
    if (statementId != null && statementId.isNotEmpty) {
      await prefs.setString('card_rewards_${cardId}_$statementId', jsonEncode(data));
    }
    await prefs.setString('card_rewards_$cardId', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadRewards(String cardId, {String? statementId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (statementId != null && statementId.isNotEmpty) {
      final jsonStr = prefs.getString('card_rewards_${cardId}_$statementId');
      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    final jsonStr = prefs.getString('card_rewards_$cardId');
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
