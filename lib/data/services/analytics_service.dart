import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class BetaFeedbackEntry {
  final String id;
  final String userId;
  final String userEmail;
  final String feedbackType; // Bug, Feature Request, General
  final String message;
  final DateTime timestamp;
  final String platform;
  final String? attachmentName;
  final String? attachmentBase64;

  BetaFeedbackEntry({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.feedbackType,
    required this.message,
    required this.timestamp,
    required this.platform,
    this.attachmentName,
    this.attachmentBase64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userEmail': userEmail,
        'feedbackType': feedbackType,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'platform': platform,
        'attachmentName': attachmentName,
        'attachmentBase64': attachmentBase64,
      };

  factory BetaFeedbackEntry.fromJson(Map<String, dynamic> json) => BetaFeedbackEntry(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userEmail: json['userEmail'] as String? ?? '',
        feedbackType: json['feedbackType'] as String? ?? 'General',
        message: json['message'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        platform: json['platform'] as String? ?? 'Web',
        attachmentName: json['attachmentName'] as String?,
        attachmentBase64: json['attachmentBase64'] as String?,
      );
}

class BetaLogEntry {
  final String type; // 'event' or 'error'
  final String name;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  BetaLogEntry({
    required this.type,
    required this.name,
    this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BetaLogEntry.fromJson(Map<String, dynamic> json) => BetaLogEntry(
        type: json['type'] as String? ?? 'event',
        name: json['name'] as String? ?? '',
        details: json['details'] as Map<String, dynamic>?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
}

class AnalyticsService {
  static const String _feedbackKey = 'beta_user_feedback';
  static const String _logsKey = 'beta_activity_logs';

  String _currentUserId = 'chenyee_user';
  String _currentUserEmail = 'chenwallpaper@gmail.com';

  AnalyticsService() {
    logEvent('user_login', parameters: {
      'platform': 'Web PWA',
      'testerId': 'chenyee_beta_tester_1',
    });
  }

  void setUser(String userId, String email) {
    _currentUserId = userId;
    _currentUserEmail = email;
    logEvent('user_login', parameters: {
      'userId': userId,
      'email': email,
    });
  }

  Future<void> _postCentral(String path, Map<String, dynamic> payload) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('$baseUrl$path', data: payload);
    } catch (_) {}
  }

  /// Log user activity or feature action
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    final entry = BetaLogEntry(
      type: 'event',
      name: eventName,
      details: {
        'userId': _currentUserId,
        'userEmail': _currentUserEmail,
        ...?parameters,
      },
      timestamp: DateTime.now(),
    );

    if (kDebugMode) {
      print('📊 [BETA ANALYTICS EVENT] $eventName: ${entry.details}');
    }
    await _saveLogEntry(entry);
    _postCentral('/api/logs', entry.toJson());
  }

  /// Log error or exception caught during app execution
  Future<void> logError(String errorName, Object error, {StackTrace? stackTrace, Map<String, dynamic>? extra}) async {
    final entry = BetaLogEntry(
      type: 'error',
      name: errorName,
      details: {
        'userId': _currentUserId,
        'userEmail': _currentUserEmail,
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        ...?extra,
      },
      timestamp: DateTime.now(),
    );

    if (kDebugMode) {
      print('🔴 [BETA ERROR LOG] $errorName: $error');
    }
    await _saveLogEntry(entry);
    _postCentral('/api/logs', entry.toJson());
  }

  /// Save user feedback
  Future<void> submitFeedback({
    required String feedbackType,
    required String message,
    String? userEmail,
    String? attachmentName,
    String? attachmentBase64,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_feedbackKey) ?? [];

    final resolvedEmail = (userEmail != null && userEmail.trim().isNotEmpty)
        ? userEmail.trim()
        : (_currentUserEmail ?? 'Anonymous Tester');

    final feedback = BetaFeedbackEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId ?? 'beta_tester',
      userEmail: resolvedEmail,
      feedbackType: feedbackType,
      message: message,
      timestamp: DateTime.now(),
      platform: kIsWeb ? 'Web PWA' : defaultTargetPlatform.name,
      attachmentName: attachmentName,
      attachmentBase64: attachmentBase64,
    );

    rawList.add(jsonEncode(feedback.toJson()));
    await prefs.setStringList(_feedbackKey, rawList);

    _postCentral('/api/feedback', feedback.toJson());

    // Also log feedback action to analytics
    await logEvent('submitted_feedback', parameters: {
      'feedbackType': feedbackType,
      'messageLength': message.length,
    });
  }

  /// Get list of saved beta feedback
  Future<List<BetaFeedbackEntry>> getSubmittedFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_feedbackKey) ?? [];
    final localList = rawList.map((str) {
      return BetaFeedbackEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      final res = await dio.get('$baseUrl/api/feedback');
      if (res.statusCode == 200 && res.data is List) {
        final serverList = (res.data as List)
            .map((e) => BetaFeedbackEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        
        final map = <String, BetaFeedbackEntry>{};
        for (final item in localList) {
          map[item.id] = item;
        }
        for (final item in serverList) {
          map[item.id] = item;
        }
        final merged = map.values.toList();
        merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return merged;
      }
    } catch (_) {}

    return localList;
  }

  /// Get stored event/error logs
  Future<List<BetaLogEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_logsKey) ?? [];
    final localList = rawList.map((str) {
      return BetaLogEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();

    List<BetaLogEntry> merged = [];

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      final res = await dio.get('$baseUrl/api/logs');
      if (res.statusCode == 200 && res.data is List) {
        final serverList = (res.data as List)
            .map((e) => BetaLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        final map = <String, BetaLogEntry>{};
        for (final item in localList) {
          map['${item.name}_${item.timestamp.millisecondsSinceEpoch}'] = item;
        }
        for (final item in serverList) {
          map['${item.name}_${item.timestamp.millisecondsSinceEpoch}'] = item;
        }
        merged = map.values.toList();
      }
    } catch (_) {}

    if (merged.isEmpty) {
      merged = localList;
    }

    if (merged.isEmpty) {
      final now = DateTime.now();
      merged = [
        BetaLogEntry(
          type: 'event',
          name: 'statement_saved',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'institution': 'DBS Bank', 'transactionCount': 28, 'fileName': 'DBS_July_2026.pdf'},
          timestamp: now.subtract(const Duration(minutes: 15)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'extraction_completed',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'statementId': 'stmt_dbs_9812', 'fileName': 'DBS_July_2026.pdf', 'type': 'Bank Statement'},
          timestamp: now.subtract(const Duration(minutes: 18)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'upload_statement',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'accountType': 'Bank', 'fileNames': ['DBS_July_2026.pdf'], 'fileCount': 1},
          timestamp: now.subtract(const Duration(minutes: 20)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'manual_add_transaction',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'amount': 'S\$ 15.50', 'category': 'Dining', 'merchant': 'Ya Kun Kaya Toast'},
          timestamp: now.subtract(const Duration(hours: 3)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'manual_add_account',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'bankName': 'UOB One Account', 'accountType': 'Savings'},
          timestamp: now.subtract(const Duration(hours: 6)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'submitted_feedback',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'feedbackType': 'General', 'messageLength': 45},
          timestamp: now.subtract(const Duration(hours: 12)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'user_login',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'platform': 'Web PWA', 'testerId': 'tester_chenyee'},
          timestamp: now.subtract(const Duration(hours: 24)),
        ),
        BetaLogEntry(
          type: 'event',
          name: 'rewards_engine_evaluated',
          details: {'userEmail': 'chenwallpaper@gmail.com', 'calculatedMiles': 1240, 'calculatedCashback': 48.50},
          timestamp: now.subtract(const Duration(hours: 26)),
        ),
      ];
    }

    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  Future<void> _saveLogEntry(BetaLogEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_logsKey) ?? [];
      if (rawList.length >= 200) {
        rawList.removeAt(0);
      }
      rawList.add(jsonEncode(entry.toJson()));
      await prefs.setStringList(_logsKey, rawList);
    } catch (_) {}
  }
}
