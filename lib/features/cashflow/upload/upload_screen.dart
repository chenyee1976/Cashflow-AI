import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_header_brand.dart';
import 'upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  String? _statusBannerMessage;
  bool _isSuccess = false;
  bool _isBannerVisible = false;
  bool _isBankExpanded = true;
  bool _isCreditCardExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadScreenProvider);
    final notifier = ref.read(uploadScreenProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeaderBrand(),
              const SizedBox(height: 16),
              // 1. App Bar Header (Back + Top Alert Banner)
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Upload statement',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_statusBannerMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!_isSuccess)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      else
                        const Icon(Icons.check_circle, color: AppColors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusBannerMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.white),
                        onPressed: () {
                          setState(() {
                            _statusBannerMessage = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),

              // 2. Twin Upload Dotted Cards
              Row(
                children: [
                  Expanded(
                    child: _buildDashedUploadBox(
                      title: 'Bank statement',
                      icon: Icons.account_balance,
                      onTap: () => _simulateUpload(context, notifier, 'bank'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDashedUploadBox(
                      title: 'Credit card statement',
                      icon: Icons.credit_card,
                      onTap: () => _simulateUpload(context, notifier, 'credit_card'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              const Center(
                child: Text(
                  'We use AI to extract transactions. Review them after upload.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 3. Recent Uploads Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT UPLOADS (${state.recentUploads.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (state.recentUploads.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No statements uploaded yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else ...[
                // Bank Statements list
                () {
                  final list = state.recentUploads.where((s) => s.fileType == 'bank').toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BANK STATEMENTS (${list.length})',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                          ),
                          IconButton(
                            icon: Icon(
                              _isBankExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _isBankExpanded = !_isBankExpanded;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isBankExpanded) ...list.map((item) => _buildRecentItem(item, notifier)),
                      const SizedBox(height: 16),
                    ],
                  );
                }(),

                // Credit Card Statements list
                () {
                  final list = state.recentUploads.where((s) => s.fileType == 'credit_card').toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CREDIT CARD STATEMENTS (${list.length})',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 0.5),
                          ),
                          IconButton(
                            icon: Icon(
                              _isCreditCardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.orange,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _isCreditCardExpanded = !_isCreditCardExpanded;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isCreditCardExpanded) ...list.map((item) => _buildRecentItem(item, notifier)),
                    ],
                  );
                }(),
              ],
              const SizedBox(height: 32),

              // 4. Link to cashflow tab
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home/cashflow'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View extracted cash flow',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedUploadBox({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PDF, CSV, JPG or PNG · 20 MB',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(UploadedStatementItem item, UploadNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.fileType == 'bank' ? Icons.account_balance : Icons.credit_card,
              color: item.fileType == 'bank' ? AppColors.primary : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.status} · ${item.transactionCount} txn · ${item.institution}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // View/Review Button
          ElevatedButton(
            onPressed: () {
              context.push(
                '/home/cashflow/review',
                extra: {
                  'fileType': item.fileType,
                  'fileName': item.fileName,
                  'statementId': item.id,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: item.status == 'Awaiting review'
                  ? AppColors.primary
                  : AppColors.textSecondary.withOpacity(0.3),
              elevation: 0,
              minimumSize: const Size(64, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              item.status == 'Awaiting review' ? 'Review' : 'View',
              style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Statement'),
                  content: Text('Are you sure you want to delete "${item.fileName}"? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                notifier.removeUpload(item.id);
              }
            },
          ),
        ],
      ),
    );
  }

  void _simulateUpload(BuildContext context, UploadNotifier notifier, String type) async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'csv', 'jpg', 'jpeg', 'png'],
          allowMultiple: true,
          withData: true,
        );
      } catch (pickerErr) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _statusBannerMessage = 'AI extraction in progress, pls wait';
          _isSuccess = false;
        });
        notifier.setUploading(true);

        String? firstStatementId;
        String? firstFileName;
        for (final file in result.files) {
          if (file.name.isNotEmpty) {
            final fileName = file.name;
            final lowerName = fileName.toLowerCase();
            String institution = 'Statement';
            if (lowerName.contains('mari')) {
              institution = 'MariBank';
            } else if (lowerName.contains('chocolate')) {
              institution = 'Chocolate Finance';
            } else if (lowerName.contains('citi')) {
              institution = 'Citibank';
            } else if (lowerName.contains('maybank')) {
              institution = 'Maybank';
            } else if (lowerName.contains('dbs')) {
              institution = 'DBS';
            } else if (lowerName.contains('posb')) {
              institution = 'POSB';
            } else if (lowerName.contains('uob')) {
              institution = 'UOB';
            } else if (lowerName.contains('ocbc')) {
              institution = 'OCBC';
            } else if (lowerName.contains('hsbc')) {
              institution = 'HSBC';
            } else if (lowerName.contains('sc') || lowerName.contains('standard')) {
              institution = 'Standard Chartered';
            }

            // Simulate file parsing delay
            await Future.delayed(const Duration(seconds: 1));

            Uint8List? fileBytes = file.bytes;
            if (fileBytes == null && file.path != null && !kIsWeb) {
              try {
                fileBytes = await io.File(file.path!).readAsBytes();
              } catch (_) {}
            }

            final id = await notifier.addStatementDraft(
              fileName: fileName,
              fileType: type,
              institution: institution,
              fileBytes: fileBytes,
            );
            
            if (firstStatementId == null) {
              firstStatementId = id;
              firstFileName = fileName;
            }
          }
        }

        notifier.setUploading(false);
        setState(() {
          _statusBannerMessage = 'AI extraction completed, pls review the extraction data';
          _isSuccess = true;
        });

        if (firstStatementId != null && context.mounted) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (context.mounted) {
            context.push(
              '/home/cashflow/review',
              extra: {
                'fileType': type,
                'fileName': firstFileName,
                'statementId': firstStatementId,
              },
            );
          }
        }
      }
    } catch (e) {
      notifier.setUploading(false);
      setState(() {
        _statusBannerMessage = 'Error choosing files: $e';
        _isSuccess = false;
      });
    }
  }
}
