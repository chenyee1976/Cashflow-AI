import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/analytics_service.dart';
import '../notifications/notification_dialog.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Beta Admin Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      NotificationDialog.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.campaign_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Notifications 📢', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint),
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
                          final item = items[items.length - 1 - index]; // newest first
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

                  // Tab 2: Activity & Error Logs
                  FutureBuilder<List<BetaLogEntry>>(
                    future: analytics.getLogs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No activity logs recorded yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = logs[index]; // newest first
                          final isError = log.type == 'error';
                          return Container(
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
                                  const SizedBox(height: 4),
                                  Text(
                                    log.details.toString(),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
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
