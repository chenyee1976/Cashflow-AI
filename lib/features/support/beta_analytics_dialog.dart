import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/aggregate_metrics_sync_service.dart';
import '../notifications/notification_dialog.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class BetaAnalyticsDialog extends ConsumerWidget {
  const BetaAnalyticsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BetaAnalyticsDialog(),
    );
  }

  void _exportAllLogsToCSV(BuildContext context, AnalyticsService analytics) async {
    final feedbackList = await analytics.getSubmittedFeedback();
    final logList = await analytics.getLogs();

    final buffer = StringBuffer();
    buffer.writeln('Type,Timestamp,User Email,User ID,Name/Category,Details');

    for (final fb in feedbackList) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(fb.timestamp);
      final emailEsc = (fb.userEmail.isNotEmpty ? fb.userEmail : 'Unknown').replaceAll('"', '""');
      final catEsc = fb.feedbackType.replaceAll('"', '""');
      final msgEsc = fb.message.replaceAll('"', '""').replaceAll('\n', ' ');
      buffer.writeln('"FEEDBACK","$dateStr","$emailEsc","${fb.userId}","$catEsc","$msgEsc"');
    }

    for (final log in logList) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);
      final userEmail = log.details?['userEmail'] as String? ?? log.details?['email'] as String? ?? 'Unknown';
      final userId = log.details?['userId'] as String? ?? 'Unknown';
      final emailEsc = userEmail.replaceAll('"', '""');
      final nameEsc = log.name.replaceAll('"', '""');
      final detailEsc = (log.details != null ? log.details.toString() : '').replaceAll('"', '""').replaceAll('\n', ' ');
      buffer.writeln('"LOG","$dateStr","$emailEsc","$userId","$nameEsc","$detailEsc"');
    }

    final bytes = const Utf8Encoder().convert(buffer.toString());
    final fileName = 'Beta_Analytics_Logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsServiceProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 6),
                  const Text(
                    'Beta Admin Dashboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      await analytics.syncAllLocalToCloud();
                      await ref.read(aggregateMetricsSyncServiceProvider).syncCurrentMonthMetrics();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cloud Sync Complete! All aggregate metrics updated.')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text('Sync Cloud', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _exportAllLogsToCSV(context, analytics),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.download_rounded, size: 14, color: Colors.green),
                          SizedBox(width: 3),
                          Text('Export CSV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      NotificationDialog.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.campaign_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text('Notify 📢', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'User Feedback'),
                Tab(text: 'Activity & Error Logs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Beta Feedback Entries
                  FutureBuilder<List<BetaFeedbackEntry>>(
                    future: analytics.getSubmittedFeedback(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No beta feedback submitted yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index]; // newest first
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.feedbackType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('dd MMM, HH:mm').format(item.timestamp),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From: ${item.userEmail} (${item.platform})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                if (item.attachmentName != null && item.attachmentName!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Attached File: ${item.attachmentName}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Tab 2: Activity & Error Logs (Grouped by User with Collapsible Accordions)
                  FutureBuilder<List<BetaLogEntry>>(
                    future: analytics.getLogs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final rawLogs = snapshot.data ?? [];
                      if (rawLogs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No activity logs recorded yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      // Group logs by User Email / ID
                      final grouped = <String, List<BetaLogEntry>>{};
                      for (final log in rawLogs) {
                        String rawEmail = (log.details?['userEmail'] as String?)?.isNotEmpty == true
                            ? (log.details!['userEmail'] as String).trim()
                            : ((log.details?['email'] as String?)?.isNotEmpty == true
                                ? (log.details!['email'] as String).trim()
                                : ((log.details?['userId'] as String?)?.isNotEmpty == true
                                    ? (log.details!['userId'] as String).trim()
                                    : 'Guest Beta Tester'));

                        String displayGroup = rawEmail;
                        final lower = rawEmail.toLowerCase();
                        if (lower.contains('unknown_user') || lower.contains('guest') || rawEmail.isEmpty) {
                          displayGroup = 'Guest User (Not Logged In)';
                        } else if (!rawEmail.contains('@')) {
                          displayGroup = '$rawEmail (Beta Tester)';
                        }
                        grouped.putIfAbsent(displayGroup, () => []).add(log);
                      }

                      // Sort each user's log list reverse-chronologically (newest first)
                      for (final list in grouped.values) {
                        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      }

                      // Sort user keys by their latest active timestamp (most recently active user at top)
                      final sortedUserEmails = grouped.keys.toList()
                        ..sort((a, b) {
                          final latestA = grouped[a]!.first.timestamp;
                          final latestB = grouped[b]!.first.timestamp;
                          return latestB.compareTo(latestA);
                        });

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedUserEmails.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, groupIndex) {
                          final email = sortedUserEmails[groupIndex];
                          final userLogs = grouped[email]!;
                          final latestTime = userLogs.first.timestamp;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            color: AppColors.surface,
                            clipBehavior: Clip.antiAlias,
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: groupIndex == 0,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    email.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                title: Text(
                                  email,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                subtitle: Text(
                                  '${userLogs.length} events · Last active ${DateFormat('dd MMM, HH:mm:ss').format(latestTime)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                children: userLogs.map((log) {
                                  final isError = log.type == 'error';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isError ? AppColors.error.withOpacity(0.05) : AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isError ? AppColors.error.withOpacity(0.3) : AppColors.divider,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isError ? Icons.error_outline : Icons.check_circle_outline,
                                              size: 16,
                                              color: isError ? AppColors.error : AppColors.success,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                log.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isError ? AppColors.error : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              DateFormat('dd MMM, HH:mm:ss').format(log.timestamp),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        if (log.details != null && log.details!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          if (log.details!['ipAddress'] != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(bottom: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                              ),
                                              child: Text(
                                                '🌐 Client IP: ${log.details!['ipAddress']}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                            ),
                                          ],
                                          Text(
                                            log.details.toString(),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
