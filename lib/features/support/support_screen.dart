import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/widgets/app_header_brand.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
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

  Future<void> _openLink(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        context.showTopSnackBar('Could not open link: $urlStr', isError: true);
      }
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
                'We\'re here to help — usually reply within 24 hours.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Triple Contact Cards (Email, WhatsApp, Telegram)
              Row(
                children: [
                  Expanded(
                    child: _buildContactCard(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Email us',
                      subtitle: 'sgcashflowai@gmail.com',
                      onTap: _openEmail,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      title: 'WhatsApp',
                      subtitle: 'Chat with us\n+65 8719 4254',
                      onTap: () => _openLink('https://wa.me/6587194254'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactCard(
                      icon: Icons.send_rounded,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Telegram',
                      subtitle: 'Join SGCashFlowAI group',
                      onTap: () => _openLink('https://t.me/SGCashFlowAI'),
                    ),
                  ),
                ],
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
                  children: _faqs.map((faq) => _buildFaqItem(faq['q']!, faq['a']!)).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // 4. More Section
              Row(
                children: const [
                  Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'MORE',
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
                    _buildMoreRow(
                      icon: Icons.assignment_outlined,
                      title: 'Terms of Service',
                      statusTag: 'In progress',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildMoreRow(
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      statusTag: 'In progress',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 5. Version Footer
              const Center(
                child: Text(
                  'SGCashFlowAI™ v1.0 — made in Singapore 🇸🇬',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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

  Widget _buildMoreRow({
    required IconData icon,
    required String title,
    required String statusTag,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(
              statusTag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
        ],
      ),
      onTap: onTap,
    );
  }
}
