import 'dart:async';
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

  String _currentUserId = 'unknown_user';
  String _currentUserEmail = '';
  final Completer<void> _identityReady = Completer<void>();

  AnalyticsService() {
    _initUser();
  }

  Future<void> _initUser() async {
    await _ensureUserIdentity();
    if (!_identityReady.isCompleted) {
      _identityReady.complete();
    }
    await syncAllLocalToCloud();
  }

  Future<void> _ensureUserIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('tester_email');
      if (savedEmail != null && savedEmail.contains('@')) {
        _currentUserEmail = savedEmail.trim();
      }
      // No hardcoded fallback — keep empty until real identity is available
      final savedUserId = prefs.getString('user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        _currentUserId = savedUserId.trim();
      }
      // No hardcoded fallback — keep 'unknown_user' until setUser() is called
    } catch (_) {}
  }

  void setUser(String userId, String email) {
    final wasUnknown = _currentUserId == 'unknown_user' || _currentUserEmail.isEmpty;
    if (userId.isNotEmpty) _currentUserId = userId;
    if (email.contains('@')) _currentUserEmail = email.trim();
    SharedPreferences.getInstance().then((prefs) {
      if (email.contains('@')) prefs.setString('tester_email', email.trim());
      if (userId.isNotEmpty) prefs.setString('user_id', userId.trim());
    });

    // Backfill any entries logged before identity was available
    if (wasUnknown && _currentUserEmail.isNotEmpty) {
      _backfillUnknownEntries();
    }

    logEvent('user_login', parameters: {
      'userId': _currentUserId,
      'email': _currentUserEmail,
    });
  }

  /// Backfill unknown_user entries in Supabase with the real identity
  Future<void> _backfillUnknownEntries() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('$baseUrl/api/logs', data: {
        'action': 'backfill_identity',
        'userId': _currentUserId,
        'userEmail': _currentUserEmail,
      });
    } catch (_) {}
  }

  Future<bool> _isAnalyticsAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('allow_ai_analytics') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> syncAllLocalToCloud() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _ensureUserIdentity();

      // 1. Sync all local feedback items in a SINGLE batch POST call
      final rawFeedback = prefs.getStringList(_feedbackKey) ?? [];
      if (rawFeedback.isNotEmpty) {
        final batch = <Map<String, dynamic>>[];
        for (final str in rawFeedback) {
          try {
            batch.add(jsonDecode(str) as Map<String, dynamic>);
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await _postCentralBatch('/api/feedback', batch);
        }
      }

      // 2. Sync all local activity logs in a SINGLE batch POST call
      final rawLogs = prefs.getStringList(_logsKey) ?? [];
      if (rawLogs.isNotEmpty) {
        final batch = <Map<String, dynamic>>[];
        for (final str in rawLogs) {
          try {
            batch.add(jsonDecode(str) as Map<String, dynamic>);
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await _postCentralBatch('/api/logs', batch);
        }
      }
    } catch (_) {}
  }

  Future<void> _postCentralBatch(String path, List<Map<String, dynamic>> items) async {
    final allowed = await _isAnalyticsAllowed();
    if (!allowed || items.isEmpty) return;

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    try {
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('$baseUrl$path', data: items);
    } catch (_) {}
  }

  Future<void> _postCentral(String path, Map<String, dynamic> payload) async {
    final allowed = await _isAnalyticsAllowed();
    if (!allowed) return; // Respect user opt-out

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    // Post to Vercel API endpoint (which manages server-side storage safely without rate limits)
    try {
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('$baseUrl$path', data: payload);
    } catch (_) {}
  }

  /// Log user activity or feature action
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    final allowed = await _isAnalyticsAllowed();
    if (!allowed) return;

    // Wait for identity to be resolved before logging (max 3s timeout)
    try {
      await _identityReady.future.timeout(const Duration(seconds: 3));
    } catch (_) {}

    await _ensureUserIdentity();

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
    // Wait for identity to be resolved before logging (max 3s timeout)
    try {
      await _identityReady.future.timeout(const Duration(seconds: 3));
    } catch (_) {}
    await _ensureUserIdentity();
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
    await _ensureUserIdentity();
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_feedbackKey) ?? [];

    final resolvedEmail = (userEmail != null && userEmail.trim().isNotEmpty && userEmail.contains('@'))
        ? userEmail.trim()
        : _currentUserEmail;

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

  /// Get list of saved beta feedback from local + Vercel + Direct Cloud REST
  Future<List<BetaFeedbackEntry>> getSubmittedFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_feedbackKey) ?? [];
    final localList = rawList.map((str) {
      return BetaFeedbackEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();

    final map = <String, BetaFeedbackEntry>{};
    for (final item in localList) {
      map[item.id] = item;
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 1. Try Vercel Serverless Function
    // 1. Query Vercel Serverless Endpoint
    try {
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      final res = await dio.get('$baseUrl/api/feedback');
      if (res.statusCode == 200 && res.data is List) {
        final serverList = (res.data as List)
            .map((e) => BetaFeedbackEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final item in serverList) {
          map[item.id] = item;
        }
      }
    } catch (_) {}

    final merged = map.values.toList();
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  /// Get stored event/error logs from local + Vercel
  Future<List<BetaLogEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_logsKey) ?? [];
    final localList = rawList.map((str) {
      return BetaLogEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();

    final map = <String, BetaLogEntry>{};
    for (final item in localList) {
      map['${item.name}_${item.timestamp.toIso8601String()}'] = item;
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 1. Query Vercel Serverless Endpoint
    try {
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      final res = await dio.get('$baseUrl/api/logs');
      if (res.statusCode == 200 && res.data is List) {
        final serverList = (res.data as List)
            .map((e) => BetaLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final item in serverList) {
          map['${item.name}_${item.timestamp.toIso8601String()}'] = item;
        }
      }
    } catch (_) {}

    final merged = map.values.toList();
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
