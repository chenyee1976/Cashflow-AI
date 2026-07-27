import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        timestamp: DateTime.parse(json['timestamp'] as String),
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
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class AnalyticsService {
  static const String _logsKey = 'beta_analytics_logs';
  static const String _feedbackKey = 'beta_feedback_entries';

  String? _currentUserId;
  String? _currentUserEmail;

  void setUser(String userId, String email) {
    _currentUserId = userId;
    _currentUserEmail = email;
    logEvent('user_login', parameters: {
      'userId': userId,
      'email': email,
    });
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
    return rawList.map((str) {
      return BetaFeedbackEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
  }

  /// Get stored event/error logs
  Future<List<BetaLogEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_logsKey) ?? [];
    return rawList.map((str) {
      return BetaLogEntry.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> _saveLogEntry(BetaLogEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_logsKey) ?? [];
      // Keep max 200 logs to prevent memory overflow
      if (rawList.length >= 200) {
        rawList.removeAt(0);
      }
      rawList.add(jsonEncode(entry.toJson()));
      await prefs.setStringList(_logsKey, rawList);
    } catch (_) {}
  }
}
