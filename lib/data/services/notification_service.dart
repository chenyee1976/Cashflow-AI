import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final unreadNotificationsProvider = StateNotifierProvider<UnreadNotificationsNotifier, int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return UnreadNotificationsNotifier(service);
});

class UnreadNotificationsNotifier extends StateNotifier<int> {
  final NotificationService _service;
  UnreadNotificationsNotifier(this._service) : super(0) {
    checkUnread();
  }

  Future<void> checkUnread() async {
    final count = await _service.getUnreadCount();
    if (mounted) {
      state = count;
    }
  }

  Future<void> markRead() async {
    await _service.markAllAsRead();
    if (mounted) {
      state = 0;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime publishedAt;
  final String author;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.publishedAt,
    required this.author,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'publishedAt': publishedAt.toIso8601String(),
        'author': author,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Notification',
        message: json['message'] as String? ?? '',
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : DateTime.now(),
        author: json['author'] as String? ?? 'SGCashFlowAI Admin',
      );
}

class NotificationService {
  static const String _localNotifsKey = 'app_published_notifications';
  static const String _lastReadTimeKey = 'app_notification_last_read_timestamp';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  String get _baseUrl => kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';

  /// Get list of all published notifications
  Future<List<AppNotification>> getNotifications() async {
    final local = await _getLocalNotifications();

    try {
      final res = await _dio.get('$_baseUrl/api/notifications');
      if (res.statusCode == 200 && res.data is List) {
        final serverList = (res.data as List)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        
        // Merge local + server notifications (preserving all user-published items by ID)
        final map = <String, AppNotification>{};
        for (final item in local) {
          map[item.id] = item;
        }
        for (final item in serverList) {
          map[item.id] = item;
        }
        final merged = map.values.toList();
        merged.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        await _cacheLocally(merged);
        return merged;
      }
    } catch (_) {}

    return local;
  }

  /// Publish a new notification (Admin only)
  Future<bool> publishNotification({
    required String title,
    required String message,
  }) async {
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      message: message.trim(),
      publishedAt: DateTime.now(),
      author: 'SGCashFlowAI Admin',
    );

    try {
      final res = await _dio.post(
        '$_baseUrl/api/notifications',
        data: notif.toJson(),
      );
      if (res.statusCode == 200) {
        final current = await _getLocalNotifications();
        current.insert(0, notif);
        await _cacheLocally(current);
        return true;
      }
    } catch (_) {}

    // Save locally if offline
    final current = await _getLocalNotifications();
    current.insert(0, notif);
    await _cacheLocally(current);
    return true;
  }

  /// Update an existing notification (Admin only)
  Future<bool> updateNotification({
    required String id,
    required String title,
    required String message,
  }) async {
    final current = await _getLocalNotifications();
    final idx = current.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final updated = AppNotification(
        id: id,
        title: title.trim(),
        message: message.trim(),
        publishedAt: current[idx].publishedAt,
        author: current[idx].author,
      );
      current[idx] = updated;
      await _cacheLocally(current);

      try {
        await _dio.post(
          '$_baseUrl/api/notifications',
          data: updated.toJson(),
        );
      } catch (_) {}
      return true;
    }
    return false;
  }

  /// Delete an existing notification (Admin only)
  Future<bool> deleteNotification(String id) async {
    try {
      final res = await _dio.delete('$_baseUrl/api/notifications?id=$id');
      if (res.statusCode == 200) {
        final current = await _getLocalNotifications();
        current.removeWhere((n) => n.id == id);
        await _cacheLocally(current);
        return true;
      }
    } catch (_) {}

    // Update local cache
    final current = await _getLocalNotifications();
    current.removeWhere((n) => n.id == id);
    await _cacheLocally(current);
    return true;
  }

  /// Calculate count of notifications published since last read timestamp
  Future<int> getUnreadCount() async {
    final notifs = await getNotifications();
    if (notifs.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    final lastReadMillis = prefs.getInt(_lastReadTimeKey) ?? 0;
    final lastRead = DateTime.fromMillisecondsSinceEpoch(lastReadMillis);

    int unread = 0;
    for (final n in notifs) {
      if (n.publishedAt.isAfter(lastRead)) {
        unread++;
      }
    }
    return unread;
  }

  /// Mark all notifications as read for this user device
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _cacheLocally(List<AppNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = list.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_localNotifsKey, raw);
  }

  Future<List<AppNotification>> _getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localNotifsKey) ?? [];
    if (raw.isEmpty) {
      return [
        AppNotification(
          id: 'welcome_beta_1',
          title: '🚀 Welcome to SGCashFlowAI Beta!',
          message: 'Thank you for testing CashFlow AI! You can upload your MariBank, DBS, UOB, OCBC, Citi bank and credit card statements to analyze your cashflow, card rewards, and expense tracking.',
          publishedAt: DateTime(2026, 7, 30, 17, 6),
          author: 'SGCashFlowAI Team',
        ),
        AppNotification(
          id: 'privacy_beta_testers',
          title: 'Current data privacy for beta testers',
          message: '''1. 🛡️ Financial Data is 100% Local (Private to the Tester's Device)
Uploaded Statements (PDFs / Images), Extracted Transactions, Account Balances, Credit Card Details, and Income/Expense Figures are saved ONLY on the beta tester's local phone or computer (inside their browser's encrypted IndexedDB storage).
Admin will NOT be able to view their actual bank statements, transaction amounts, balances, or card details.
This guarantees 100% compliance with Singapore's PDPA privacy laws, so beta testers can comfortably test the app with real statements without worrying about anyone seeing their financial numbers.

2. 📊 What Admin CAN See (Beta Activity Logs)
While Admin cannot see their private financial figures, your Admin Mode allows Admin to track their engagement via the Activity Logs screen:
Tester Identity: First Name, Last Name, and Email (entered during their first login popup).
Action Timeline: Event logs such as User Onboarded, Uploaded Bank Statement, Uploaded Credit Card Statement, Viewed Cash Flow Screen, Timestamps & Log Counts.''',
          publishedAt: DateTime(2026, 7, 29, 22, 40),
          author: 'SGCashFlowAI Admin',
        ),
        AppNotification(
          id: 'list_of_banks_tested',
          title: 'List of banks',
          message: '''We have tested the following bank statements and credit card statements so far on the app.
As of 29 July 2026

Bank statements:
1. POSB bank statements
2. OCBC bank statements
3. MariBank bank statements
4. Chocolate Finance bank statements
5. CIMB bank statements
6. Citibank bank statements
7. SingFinance bank statements

Credit card statements:
1. Citibank PremierMiles
2. OCBC 90n
3. MariBank credit card
4. Maybank Family and Friends card''',
          publishedAt: DateTime(2026, 7, 29, 21, 46),
          author: 'SGCashFlowAI Admin',
        ),
        AppNotification(
          id: 'welcome_beta_testers_intro',
          title: 'Welcome Beta Testers',
          message: '''Thanks for agreeing to help with testing this app.

Below are the functionalities of the app that you can test:
1. Upload of bank statements to populate your total cash positions and income and expenses as of each month end
2. Upload of credit card statements to populate your expenses and rewards as of each credit card statement
3. Total view of cash position for each month end, Total income and expenses of each month end
4. Total view of cashback or miles earned from your credit card statements
5. Tracking of total miles that you have earned''',
          publishedAt: DateTime(2026, 7, 29, 21, 42),
          author: 'SGCashFlowAI Admin',
        ),
        AppNotification(
          id: 'system_update_2',
          title: '📢 System Update: Multi-Bank Statement OCR & PDF Parsing',
          message: 'We have updated our AI statement parser with higher accuracy for DBS, MariBank, UOB, OCBC, and Citibank statements.',
          publishedAt: DateTime(2026, 7, 28, 14, 30),
          author: 'SGCashFlowAI Admin',
        ),
        AppNotification(
          id: 'pdpa_privacy_3',
          title: '🛡️ PDPA & Privacy Policy Update',
          message: 'Our Terms of Service, PDPA Privacy Policy, and AI Analytics controls are now available in Account Settings and Support.',
          publishedAt: DateTime(2026, 7, 28, 18, 0),
          author: 'SGCashFlowAI L&C',
        ),
      ];
    }
    return raw.map((str) {
      return AppNotification.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();
  }
}
