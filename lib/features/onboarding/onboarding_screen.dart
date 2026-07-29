import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_provider.dart';

import '../legal/legal_viewer_dialog.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Step 1 Controllers
  final _firstNameController = TextEditingController(text: 'Alex');
  final _lastNameController = TextEditingController(text: 'Tan');
  final _mobileController = TextEditingController(text: '+65 9123 4567');
  final _savingsTargetController = TextEditingController(text: '1000');
  String _currencyPref = 'SGD';

  // Step 2 Agreement States
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _dataConsentAccepted = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _savingsTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Steps Progress Bar
            _buildProgressBar(onboardingState.currentStep),

            // 2. Main Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: _buildStepContent(onboardingState.currentStep, onboardingState, notifier),
              ),
            ),

            // 3. Bottom Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isContinueEnabled(onboardingState.currentStep)
                    ? () async {
                        if (onboardingState.currentStep == 1) {
                          notifier.setPersonalInfo(
                            firstName: _firstNameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                            mobileNumber: _mobileController.text.trim(),
                            currencyPref: _currencyPref,
                            monthlySavingsGoal: 0.0,
                          );
                          notifier.nextStep();
                        } else if (onboardingState.currentStep == 2) {
                          notifier.setLegalConsents(
                            terms: _termsAccepted,
                            privacy: _privacyAccepted,
                            dataConsent: _dataConsentAccepted,
                          );
                          notifier.nextStep();
                        } else if (onboardingState.currentStep == 3) {
                          await notifier.completeOnboarding();
                          if (mounted) {
                            context.go('/home/dashboard');
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      onboardingState.currentStep == 3 ? 'Complete Setup' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    const totalSteps = 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentStep > 1)
                InkWell(
                  onTap: () => ref.read(onboardingProvider.notifier).prevStep(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                )
              else
                const SizedBox(width: 36),
              Text(
                'STEP $currentStep OF $totalSteps',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isActive = stepNum <= currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6.0,
                    right: index == totalSteps - 1 ? 0 : 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step, OnboardingState state, OnboardingNotifier notifier) {
    switch (step) {
      case 1:
        return _buildStepUserInfo();
      case 2:
        return _buildStepLegalConsent();
      case 3:
        return _buildStepRewards(state, notifier);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: User Info ──
  Widget _buildStepUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.white, size: 30),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome to SGCashFlowAI™',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell us a bit about yourself so we can personalise your dashboard.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('First name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(hintText: 'e.g. Alex'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(hintText: 'e.g. Tan'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Mobile (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+65 9123 4567'),
        ),
      ],
    );
  }

  // ── Step 2: Legal Consent ──
  Widget _buildStepLegalConsent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.gavel_outlined, size: 48, color: AppColors.primary),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Legal Consent & Privacy',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Text(
                'In progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Please review and accept our agreements to proceed with AI analysis.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 32),
        
        // Consent checkboxes
        _buildConsentCheckbox(
          title: 'Accept Terms & Conditions',
          subtitle: 'Read platform rules and agreement details.',
          value: _termsAccepted,
          onChanged: (v) => setState(() => _termsAccepted = v ?? false),
          onTapView: () => LegalViewerModal.show(context, initialTabIndex: 0),
        ),
        const SizedBox(height: 16),
        _buildConsentCheckbox(
          title: 'Accept Privacy Policy',
          subtitle: 'We strictly comply with Singapore\'s PDPA data regulations.',
          value: _privacyAccepted,
          onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
          onTapView: () => LegalViewerModal.show(context, initialTabIndex: 1),
        ),
        const SizedBox(height: 16),
        _buildConsentCheckbox(
          title: 'Allow AI Analytics & Logs',
          subtitle: 'Authorize statement extraction log processes for model optimization.',
          value: _dataConsentAccepted,
          onChanged: (v) => setState(() => _dataConsentAccepted = v ?? false),
        ),
      ],
    );
  }

  Widget _buildConsentCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onTapView,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (onTapView != null)
              GestureDetector(
                onTap: onTapView,
                child: const Text(
                  'Read',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  // ── Step 3: Rewards Focus ──
  Widget _buildStepRewards(OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'What do you optimise for?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'This tailors your rewards view. You can change it later.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        
        _buildRewardTile(
          focusKey: 'miles',
          title: 'Miles',
          description: 'I optimise for air miles & travel rewards.',
          icon: Icons.flight_takeoff,
          state: state,
          notifier: notifier,
        ),
        const SizedBox(height: 16),
        _buildRewardTile(
          focusKey: 'cashback',
          title: 'Cashback',
          description: 'I prefer straight cash rebates.',
          icon: Icons.account_balance_wallet,
          state: state,
          notifier: notifier,
        ),
        const SizedBox(height: 16),
        _buildRewardTile(
          focusKey: 'both',
          title: 'Both',
          description: 'Mix of miles cards and cashback cards.',
          icon: Icons.stars,
          state: state,
          notifier: notifier,
        ),
      ],
    );
  }

  Widget _buildRewardTile({
    required String focusKey,
    required String title,
    required String description,
    required IconData icon,
    required OnboardingState state,
    required OnboardingNotifier notifier,
  }) {
    final isSelected = state.rewardFocus == focusKey;
    return InkWell(
      onTap: () => notifier.setRewardFocus(focusKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.4) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFFE2E8F0).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isContinueEnabled(int currentStep) {
    if (currentStep == 1) {
      return _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty;
    } else if (currentStep == 2) {
      return _termsAccepted && _privacyAccepted && _dataConsentAccepted;
    }
    return true; // Step 3 always has one selection active by default
  }
}
