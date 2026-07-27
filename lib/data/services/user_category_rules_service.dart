import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../secure_storage/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearnedRule {
  final String pattern;
  final String expenseCategory;
  final String milesCategory;

  LearnedRule({
    required this.pattern,
    required this.expenseCategory,
    required this.milesCategory,
  });

  Map<String, String> toJson() => {
        'pattern': pattern,
        'expenseCategory': expenseCategory,
        'milesCategory': milesCategory,
      };

  factory LearnedRule.fromJson(Map<String, dynamic> json) => LearnedRule(
        pattern: json['pattern'] as String? ?? '',
        expenseCategory: json['expenseCategory'] as String? ?? 'expense_other',
        milesCategory: json['milesCategory'] as String? ?? 'Others',
      );
}

final userCategoryRulesServiceProvider = Provider<UserCategoryRulesService>((ref) {
  return UserCategoryRulesService();
});

class UserCategoryRulesService {
  static const String _rulesKey = 'sgcashflow_user_category_rules_v1';

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Save a learned rule for a given merchant description
  Future<void> saveRule({
    required String rawMerchant,
    required String expenseCategory,
    String milesCategory = 'Others',
  }) async {
    final cleaned = _normalize(rawMerchant);
    if (cleaned.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_rulesKey);
    Map<String, dynamic> rulesMap = {};
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        rulesMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }

    rulesMap[cleaned] = LearnedRule(
      pattern: cleaned,
      expenseCategory: expenseCategory,
      milesCategory: milesCategory,
    ).toJson();

    await prefs.setString(_rulesKey, jsonEncode(rulesMap));
  }

  /// Match a merchant string against saved user rules
  Future<LearnedRule?> matchRule(String rawMerchant) async {
    final cleaned = _normalize(rawMerchant);
    if (cleaned.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_rulesKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final Map<String, dynamic> rulesMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 1. Direct match or substring match
      for (final entry in rulesMap.entries) {
        final keyPattern = entry.key;
        if (cleaned.contains(keyPattern) || keyPattern.contains(cleaned)) {
          return LearnedRule.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    return null;
  }
}
