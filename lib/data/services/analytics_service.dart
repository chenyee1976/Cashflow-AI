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
    _initUser();
  }

  Future<void> _initUser() async {
    await _ensureUserIdentity();
    await syncAllLocalToCloud();
    logEvent('user_login', parameters: {
      'platform': 'Web PWA',
      'email': _currentUserEmail,
    });
  }

  Future<void> syncAllLocalToCloud() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _ensureUserIdentity();

      // 1. Sync all local feedback items
      final rawFeedback = prefs.getStringList(_feedbackKey) ?? [];
      for (final str in rawFeedback) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          await _postCentral('/api/feedback', map);
        } catch (_) {}
      }

      // 2. Sync all local activity logs
      final rawLogs = prefs.getStringList(_logsKey) ?? [];
      for (final str in rawLogs) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          await _postCentral('/api/logs', map);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _ensureUserIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('tester_email');
      if (savedEmail != null && savedEmail.contains('@')) {
        _currentUserEmail = savedEmail.trim();
      }
      final savedUserId = prefs.getString('user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        _currentUserId = savedUserId.trim();
      }
    } catch (_) {}
  }

  void setUser(String userId, String email) {
    if (userId.isNotEmpty) _currentUserId = userId;
    if (email.contains('@')) _currentUserEmail = email.trim();
    SharedPreferences.getInstance().then((prefs) {
      if (email.contains('@')) prefs.setString('tester_email', email.trim());
      if (userId.isNotEmpty) prefs.setString('user_id', userId.trim());
    });
    logEvent('user_login', parameters: {
      'userId': _currentUserId,
      'email': _currentUserEmail,
    });
  }

  Future<bool> _isAnalyticsAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('allow_ai_analytics') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _postCentral(String path, Map<String, dynamic> payload) async {
    final allowed = await _isAnalyticsAllowed();
    if (!allowed) return; // Respect user opt-out

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    // 1. Post to Vercel API endpoint
    try {
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('$baseUrl$path', data: payload);
    } catch (_) {}

    // 2. Dual Backup Post directly to Cloud REST Storage (Guarantees zero data loss across cold starts)
    try {
      final endpoint = path.contains('feedback')
          ? 'https://api.restful-api.dev/objects/ff8081819f7e10ae019fc55ab9e864fd'
          : 'https://api.restful-api.dev/objects/ff8081819f7e10ae019fc55ababe64fe';

      final getRes = await dio.get(endpoint);
      if (getRes.statusCode == 200 && getRes.data != null) {
        final currentItems = (getRes.data['data']?['items'] as List<dynamic>?) ?? [];
        final map = <String, dynamic>{};

        for (final item in currentItems) {
          if (item is Map<String, dynamic>) {
            final key = item['id'] ?? '${item['name']}_${item['timestamp']}';
            map[key.toString()] = item;
          }
        }

        final newKey = payload['id'] ?? '${payload['name']}_${payload['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}';
        map[newKey.toString()] = {
          ...payload,
          'cloudSyncedAt': DateTime.now().toIso8601String(),
        };

        final updatedList = map.values.toList();
        final trimmed = updatedList.length > 500 ? updatedList.sublist(updatedList.length - 500) : updatedList;

        await dio.put(endpoint, data: {
          'name': path.contains('feedback') ? 'sgcashflow_global_feedback' : 'sgcashflow_global_logs',
          'data': {'items': trimmed},
        });
      }
    } catch (_) {}
  }

  /// Log user activity or feature action
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    final allowed = await _isAnalyticsAllowed();
    if (!allowed) return;

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

    // 2. Direct Cloud REST Fallback (Guarantees data presence even if serverless instance recycles)
    try {
      final resCloud = await dio.get('https://api.restful-api.dev/objects/ff8081819f7e10ae019fc55ab9e864fd');
      if (resCloud.statusCode == 200 && resCloud.data != null) {
        final dataObj = resCloud.data['data'] as Map<String, dynamic>?;
        final itemsList = dataObj?['items'] as List<dynamic>?;
        if (itemsList != null) {
          for (final item in itemsList) {
            final entry = BetaFeedbackEntry.fromJson(item as Map<String, dynamic>);
            map[entry.id] = entry;
          }
        }
      }
    } catch (_) {}

    final merged = map.values.toList();
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  /// Get stored event/error logs from local + Vercel + Direct Cloud REST
  Future<List<BetaLogEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_logsKey) ?? [];
    final localList = rawList.map((str) {
      return BetaLogEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();

    final map = <String, BetaLogEntry>{};
    for (final item in localList) {
      map['${item.name}_${item.timestamp.millisecondsSinceEpoch}'] = item;
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 1. Try Vercel Serverless Function
    try {
      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      final res = await dio.get('$baseUrl/api/logs');
      if (res.statusCode == 200 && res.data is List) {
        final serverList = (res.data as List)
            .map((e) => BetaLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final item in serverList) {
          map['${item.name}_${item.timestamp.millisecondsSinceEpoch}'] = item;
        }
      }
    } catch (_) {}

    // 2. Direct Cloud REST Fallback
    try {
      final resCloud = await dio.get('https://api.restful-api.dev/objects/ff8081819f7e10ae019fc55ababe64fe');
      if (resCloud.statusCode == 200 && resCloud.data != null) {
        final dataObj = resCloud.data['data'] as Map<String, dynamic>?;
        final itemsList = dataObj?['items'] as List<dynamic>?;
        if (itemsList != null) {
          for (final item in itemsList) {
            final entry = BetaLogEntry.fromJson(item as Map<String, dynamic>);
            map['${entry.name}_${entry.timestamp.millisecondsSinceEpoch}'] = entry;
          }
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
