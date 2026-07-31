import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/widgets/app_header_brand.dart';
import '../../../shared/widgets/app_footer_brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import 'beta_feedback_dialog.dart';
import 'beta_analytics_dialog.dart';
import '../legal/legal_viewer_dialog.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  int _badgeTapCount = 0;
  bool _isAdminUnlocked = false;
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I upload a statement?',
      'a': 'Go to the Cash Flow tab, tap the "+" button or "Upload a statement" link. Select either Bank statement or Credit Card statement, choose your PDF statement file, and our AI will automatically extract and parse the transactions.'
    },
    {
      'q': 'Is my financial data secure?',
      'a': 'Yes, absolutely. Your statements are parsed locally on-device using secure SQLite local mapping. We do not store or sell your bank credentials. All data is securely encrypted in transport and storage.'
    },
    {
      'q': 'Why are some transactions miscategorised?',
      'a': 'AI merchant classification uses semantic logic. If a merchant category is incorrect, you can edit it manually by tapping on the transaction row in the Cash Flow review list and choosing the correct category.'
    },
    {
      'q': 'How are miles and cashback calculated?',
      'a': 'Miles and cashback are calculated based on your card spend multiplied by your configured cards earning rates. You can edit card rates anytime in the Rewards tab.'
    },
    {
      'q': 'Can I add a bank or card that\'s not listed?',
      'a': 'Yes. When you upload a statement, the AI will extract the bank name and create the account. You can also manually add transactions of any bank or card in the Cash Flow tab.'
    },
    {
      'q': 'How do I delete my account?',
      'a': 'You can delete your account and all locally cached statement data by going to the Account tab, scrolling to the bottom, and tapping "Delete Account".'
    },
  ];

  void _openAdminLogsWithPin() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Admin Authentication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Admin PIN to view beta telemetry and tester feedback:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter Admin PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = controller.text.trim();
              if (pin == '0404') {
                Navigator.pop(ctx);
                setState(() => _isAdminUnlocked = true);
                BetaAnalyticsDialog.show(context);
              } else {
                context.showTopSnackBar('Incorrect Admin PIN', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Access Logs', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmail() async {
    const email = 'sgcashflowai@gmail.com';
    // 1. Copy email address to clipboard as a reliable guarantee for web/desktop users
    await Clipboard.setData(const ClipboardData(text: email));
    if (mounted) {
      context.showTopSnackBar('Email copied to clipboard ($email)!');
    }

    // 2. Trigger mailto once
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignored if OS has no default desktop mail handler (email is already copied to clipboard)
    }
  }

  Future<void> _openWhatsApp() async {
    const phone = '6587194254';
    final appUri = Uri.parse('whatsapp://send?phone=$phone');
    final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$phone');

    bool launched = false;
    try {
      if (await canLaunchUrl(appUri)) {
        launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched && mounted) {
      await Clipboard.setData(const ClipboardData(text: '+6587194254'));
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('WhatsApp Not Detected', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'We cannot detect the WhatsApp app on your device.\n\nPhone number (+65 8719 4254) has been copied to your clipboard. Please add SG Cashflow AI manually to your apps.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openTelegram() async {
    const handle = 'SGCashFlowAI';
    final appUri = Uri.parse('tg://resolve?domain=$handle');
    final webUri = Uri.parse('https://t.me/$handle');

    bool launched = false;
    try {
      if (await canLaunchUrl(appUri)) {
        launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched && mounted) {
      await Clipboard.setData(const ClipboardData(text: '@SGCashFlowAI'));
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Telegram Not Detected', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'We cannot detect the Telegram app on your device.\n\nGroup handle (@SGCashFlowAI) has been copied to your clipboard. Please add SG Cashflow AI manually to your apps.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeaderBrand(),
              const SizedBox(height: 16),
              // 1. Header
              const Text(
                'Support',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'We\'re here to help.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 1.5 Beta Testing Feedback Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BETA TESTER EXCLUSIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        // Admin Logs Link (PIN Locked)
                        InkWell(
                          onTap: () {
                            if (_isAdminUnlocked) {
                              BetaAnalyticsDialog.show(context);
                            } else {
                              _openAdminLogsWithPin();
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isAdminUnlocked ? Icons.analytics_outlined : Icons.lock_outline,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isAdminUnlocked ? 'Admin Logs' : 'Admin Portal 🔒',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Have feedback or spotted a bug?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Send your comments directly to our engineering team with 1 click.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => BetaFeedbackDialog.show(context),
                        icon: const Icon(Icons.rate_review_rounded, size: 18, color: Color(0xFF2563EB)),
                        label: const Text(
                          'Submit Beta Feedback',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Triple Contact Cards (Email, WhatsApp, Telegram)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF2563EB),
                        title: 'Email us',
                        subtitle: 'Official Help\nsgcashflowai@gmail.com',
                        onTap: _openEmail,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: const Color(0xFF16A34A),
                        title: 'WhatsApp',
                        subtitle: 'Chat with us\n+65 8719 4254',
                        onTap: _openWhatsApp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildContactCard(
                        icon: Icons.send_rounded,
                        iconColor: const Color(0xFF0284C7),
                        title: 'Telegram',
                        subtitle: 'Join Group\n@SGCashFlowAI',
                        onTap: _openTelegram,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. FAQs Section
              Row(
                children: const [
                  Icon(Icons.menu_book_outlined, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'FREQUENTLY ASKED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _buildFaqItem(
                      'Is my financial data kept private?',
                      'Yes, 100%! All your uploaded bank & credit card statements are parsed and stored locally inside your browser/device database. We never sell your data.',
                    ),
                    const Divider(height: 1),
                    _buildFaqItem(
                      'Which banks & credit cards are supported?',
                      'We support DBS/POSB, OCBC, UOB, MariBank, Citibank, SingFinance, Chocolate Finance, HSBC, Maybank, Standard Chartered, and major credit cards in Singapore.',
                    ),
                    const Divider(height: 1),
                    _buildFaqItem(
                      'How do miles and cashback rewards get calculated?',
                      'SGCashFlowAI automatically maps your credit card transactions against standard card reward categories (e.g. SimplyGo, Dining, Groceries, Travel) to estimate earned miles or cashback.',
                    ),
                    const Divider(height: 1),
                    _buildFaqItem(
                      'How do I upload a statement?',
                      'Go to the Cash Flow tab or Home screen, tap "Upload a statement". Select Bank or Credit Card statement, choose your PDF statement file, and our AI will automatically extract and parse the transactions.',
                    ),
                    const Divider(height: 1),
                    _buildFaqItem(
                      'Why are some transactions miscategorised?',
                      'AI merchant classification uses semantic logic. If a merchant category is incorrect, you can edit it manually by tapping on the transaction row in the Cash Flow list and choosing the correct category.',
                    ),
                    const Divider(height: 1),
                    _buildFaqItem(
                      'Can I add a bank or card that\'s not listed?',
                      'Yes. When you upload a statement, the AI will extract the bank name and create the account. You can also manually add transactions of any bank or card in the Cash Flow tab.',
                    ),
                    const Divider(height: 1),
                    _buildFaqItem(
                      'How do I delete my account or clear data?',
                      'You can delete your account and clear all locally cached statement data by going to the Account tab, scrolling to the bottom, and tapping "Delete Account".',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Version Footer
              const AppFooterBrand(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
