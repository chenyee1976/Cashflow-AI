import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import '../../../shared/widgets/app_header_brand.dart';
import 'account_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _geminiApiKeyCtrl = TextEditingController(text: SecureStorageService.defaultGeminiApiKey);
  String _rewardFocus = 'Both';
  String _currency = 'SGD — Singapore Dollar';

  bool _isEditingPersonalInfo = false;
  bool _initialized = false;
  String _membershipTier = 'pro_free_trial'; // 'essential', 'pro_free_trial', 'pro_monthly', 'elite'
  String _cardNum = '';
  String _cardName = '';
  String _cardExpiry = '';
  String _cardCvv = '';
  String _billingZip = '';
  String _lastPaymentDate = '';
  String _nextPaymentDate = '';

  bool _isEditingCard = false;
  final _cardNumCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();
  final _billingZipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGeminiKey();
    _loadBillingCard();
  }

  void _loadGeminiKey() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.getGeminiApiKey();
    if (key != null) {
      setState(() {
        _geminiApiKeyCtrl.text = key;
      });
    }
  }

  void _showGeminiKeyDialog() {
    final keyCtrl = TextEditingController(text: _geminiApiKeyCtrl.text);
    final isCustom = _geminiApiKeyCtrl.text.isNotEmpty &&
        _geminiApiKeyCtrl.text != SecureStorageService.defaultGeminiApiKey;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Gemini API Key Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your personal Gemini API key or use the shared default key for statement extraction:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: InputDecoration(
                hintText: 'Enter Gemini API Key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCustom ? 'Active Status: Using Personal Custom API Key' : 'Active Status: Using Shared Default API Key (AQ.Ab8RN...)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCustom ? AppColors.primary : AppColors.success,
              ),
            ),
          ],
        ),
        actions: [
          if (isCustom) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final storage = ref.read(secureStorageProvider);
                await storage.saveGeminiApiKey('');
                setState(() {
                  _geminiApiKeyCtrl.text = SecureStorageService.defaultGeminiApiKey;
                });
                if (mounted) {
                  context.showTopSnackBar('Reset to Default Gemini API Key');
                }
              },
              child: const Text('Reset to Default', style: TextStyle(color: AppColors.error)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newKey = keyCtrl.text.trim();
              Navigator.pop(ctx);
              final storage = ref.read(secureStorageProvider);
              await storage.saveGeminiApiKey(newKey);
              setState(() {
                _geminiApiKeyCtrl.text = newKey.isNotEmpty ? newKey : SecureStorageService.defaultGeminiApiKey;
              });
              if (mounted) {
                context.showTopSnackBar('Gemini API Key updated successfully');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Key', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _loadBillingCard() async {
    final storage = ref.read(secureStorageProvider);
    final card = await storage.getBillingCard();
    if (card['name']?.isNotEmpty == true || card['num']?.isNotEmpty == true) {
      setState(() {
        _cardName = card['name'] ?? '';
        _cardNum = card['num'] ?? '';
        _cardExpiry = card['expiry'] ?? '';
        _cardCvv = card['cvv'] ?? '';
        _billingZip = card['zip'] ?? '';
        _lastPaymentDate = card['lastPay'] ?? '';
        _nextPaymentDate = card['nextPay'] ?? '';
        _cardNameCtrl.text = _cardName;
        _cardNumCtrl.text = _cardNum;
        _cardExpiryCtrl.text = _cardExpiry;
        _cardCvvCtrl.text = _cardCvv;
        _billingZipCtrl.text = _billingZip;
      });
    }
  }

  void _initFields(AccountProfileData data) {
    if (_initialized) return;
    _firstNameCtrl.text = data.firstName;
    _lastNameCtrl.text = data.lastName;
    _mobileCtrl.text = data.mobileNumber;
    _rewardFocus = data.rewardFocus;
    if (_geminiApiKeyCtrl.text.isEmpty) {
      _geminiApiKeyCtrl.text = SecureStorageService.defaultGeminiApiKey;
    }
    _initialized = true;
  }

  void _saveChanges() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm changes?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to save your credit card details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Automatically save credit card if it was left in edit mode
    if (_isEditingCard) {
      final now = DateTime.now();
      final nextBilling = DateTime(now.year, now.month + 1, now.day);
      final lastPayStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';
      final nextPayStr = '${nextBilling.day} ${_getMonthName(nextBilling.month)} ${nextBilling.year}';

      final nameVal = _cardNameCtrl.text.trim();
      final rawNum = _cardNumCtrl.text.replaceAll(RegExp(r'\D'), '');
      final numVal = rawNum.length >= 4 ? rawNum.substring(rawNum.length - 4) : rawNum;
      final expVal = _cardExpiryCtrl.text.trim();
      final cvvVal = _cardCvvCtrl.text.trim();
      final zipVal = _billingZipCtrl.text.trim();

      setState(() {
        _cardName = nameVal;
        _cardNum = numVal;
        _cardExpiry = expVal;
        _cardCvv = cvvVal;
        _billingZip = zipVal;
        _lastPaymentDate = lastPayStr;
        _nextPaymentDate = nextPayStr;
        _isEditingCard = false;
      });

      await ref.read(secureStorageProvider).saveBillingCard(
        name: nameVal,
        num: numVal,
        expiry: expVal,
        cvv: cvvVal,
        zip: zipVal,
        lastPay: lastPayStr,
        nextPay: nextPayStr,
      );
    }

    final ops = ref.read(accountOperationsProvider);
    await ops.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      rewardFocus: _rewardFocus,
    );
    final storage = ref.read(secureStorageProvider);
    final keyToSave = _geminiApiKeyCtrl.text.trim();
    print('DEBUG Saving key: "$keyToSave"');
    await storage.saveGeminiApiKey(keyToSave);
    final checkKey = await storage.getGeminiApiKey();
    print('DEBUG Verified saved key: "$checkKey"');
    if (mounted) {
      context.showTopSnackBar('Changes saved successfully');
    }
  }

  void _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This will permanently delete all uploaded statements, parsed accounts, and transactions. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ops = ref.read(accountOperationsProvider);
      try {
        await ops.clearAllData();
        if (mounted) {
          context.showTopSnackBar('All data has been cleared');
        }
      } catch (e) {
        if (mounted) {
          context.showTopSnackBar('Error clearing data: $e', isError: true);
        }
      }
    }
  }

  void _signOut() async {
    final ops = ref.read(accountOperationsProvider);
    await ops.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(accountProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (data) {
            _initFields(data);
            final initials = '${data.firstName.isNotEmpty ? data.firstName[0].toUpperCase() : ''}${data.lastName.isNotEmpty ? data.lastName[0].toUpperCase() : ''}';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeaderBrand(),
                  const SizedBox(height: 16),
                  // 1. Header
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your profile and app preferences.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials.isNotEmpty ? initials : 'CT',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.firstName} ${data.lastName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. Personal Info Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            'PERSONAL INFO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          if (_isEditingPersonalInfo) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Confirm changes?', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: const Text('Are you sure you want to save your personal details?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Confirm', style: TextStyle(color: AppColors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final ops = ref.read(accountOperationsProvider);
                              await ops.updateProfile(
                                firstName: _firstNameCtrl.text.trim(),
                                lastName: _lastNameCtrl.text.trim(),
                                mobileNumber: _mobileCtrl.text.trim(),
                                rewardFocus: _rewardFocus,
                              );
                              setState(() {
                                _isEditingPersonalInfo = false;
                              });
                              if (context.mounted) {
                                context.showTopSnackBar('Personal information updated successfully');
                              }
                            }
                          } else {
                            setState(() {
                              _isEditingPersonalInfo = true;
                            });
                          }
                        },
                        icon: Icon(_isEditingPersonalInfo ? Icons.check : Icons.edit, color: AppColors.primary, size: 14),
                        label: Text(
                          _isEditingPersonalInfo ? 'Save' : 'Edit',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('First name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  _buildTextField(_firstNameCtrl, enabled: _isEditingPersonalInfo),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Last name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  _buildTextField(_lastNameCtrl, enabled: _isEditingPersonalInfo),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Mobile number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _buildTextField(_mobileCtrl, enabled: _isEditingPersonalInfo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4. Preferences Section
                  Row(
                    children: const [
                      Icon(Icons.tune, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'PREFERENCES',
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reward focus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _buildDropdown(
                          value: _rewardFocus,
                          items: const ['Miles', 'Cashback', 'Both'],
                          onChanged: (val) => setState(() => _rewardFocus = val!),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hides the Miles tab when set to Cashback only.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        const Text('Currency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _buildDropdown(
                          value: _currency,
                          items: const ['SGD — Singapore Dollar', 'USD — US Dollar'],
                          onChanged: (val) => setState(() => _currency = val!),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.vpn_key_outlined, size: 16, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text(
                                        'Gemini AI API Key (Statement Extraction)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '● Shared Key Active',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _geminiApiKeyCtrl,
                                readOnly: false,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  fillColor: AppColors.white,
                                  filled: true,
                                  hintText: SecureStorageService.defaultGeminiApiKey,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _showGeminiKeyDialog,
                                    icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                                    label: const Text('Amend / Change API Key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Shared key is active for all beta testers. Click Amend to use custom key.',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Membership Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.card_membership, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            'MEMBERSHIP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
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
                  const SizedBox(height: 12),

                  // Membership Tier Selection cards
                  Column(
                    children: [
                      // 1. Essential membership
                      _buildMembershipOption(
                        id: 'essential',
                        title: 'Essential membership',
                        subtitle: 'Free to use with cash position, cashflows and rewards',
                        badgeText: 'Free',
                        badgeColor: Colors.grey.shade600,
                        priceText: 'S\$0.00/mo',
                      ),
                      const SizedBox(height: 10),
                      // 2. Pro membership (14 day trial)
                      _buildMembershipOption(
                        id: 'pro_free_trial',
                        title: 'Pro membership (14 day free membership)',
                        subtitle: 'Paid membership with more services (Free for 14 days) - cancel anytime',
                        badgeText: 'Popular',
                        badgeColor: AppColors.primary,
                        priceText: '14-day Trial',
                      ),
                      const SizedBox(height: 10),
                      // 3. Pro membership (paid)
                      _buildMembershipOption(
                        id: 'pro_monthly',
                        title: 'Pro membership',
                        subtitle: 'Paid monthly membership with more services - cancel anytime',
                        badgeText: 'Monthly',
                        badgeColor: const Color(0xFF0073E6),
                        priceText: 'S\$9.90/mo',
                      ),
                      const SizedBox(height: 10),
                      // 4. Elite membership
                      _buildMembershipOption(
                        id: 'elite',
                        title: 'Elite membership',
                        subtitle: 'Placeholder for more premium services - cancel anytime',
                        badgeText: 'Premium',
                        badgeColor: const Color(0xFFFFB300),
                        priceText: 'S\$19.90/mo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Billing Card & Payment Details Box (Matching Membership Details Colors)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Credit Card Information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {
                                  if (_isEditingCard) {
                                    // Save changes
                                    final now = DateTime.now();
                                    final nextBilling = DateTime(now.year, now.month + 1, now.day);
                                    final lastPayStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';
                                    final nextPayStr = '${nextBilling.day} ${_getMonthName(nextBilling.month)} ${nextBilling.year}';

                                    final nameVal = _cardNameCtrl.text.trim();
                                    final rawNum = _cardNumCtrl.text.replaceAll(RegExp(r'\D'), '');
                                    final numVal = rawNum.length >= 4 ? rawNum.substring(rawNum.length - 4) : rawNum;
                                    final expVal = _cardExpiryCtrl.text.trim();
                                    final cvvVal = _cardCvvCtrl.text.trim();
                                    final zipVal = _billingZipCtrl.text.trim();

                                    setState(() {
                                      _cardName = nameVal;
                                      _cardNum = numVal;
                                      _cardExpiry = expVal;
                                      _cardCvv = cvvVal;
                                      _billingZip = zipVal;
                                      _lastPaymentDate = lastPayStr;
                                      _nextPaymentDate = nextPayStr;
                                      _isEditingCard = false;
                                    });

                                    ref.read(secureStorageProvider).saveBillingCard(
                                      name: nameVal,
                                      num: numVal,
                                      expiry: expVal,
                                      cvv: cvvVal,
                                      zip: zipVal,
                                      lastPay: lastPayStr,
                                      nextPay: nextPayStr,
                                    );

                                    context.showTopSnackBar('Billing information updated successfully');
                                  } else {
                                  // Enter edit mode
                                  setState(() {
                                    _cardNameCtrl.text = _cardName;
                                    _cardNumCtrl.text = _cardNum;
                                    _cardExpiryCtrl.text = _cardExpiry;
                                    _cardCvvCtrl.text = _cardCvv;
                                    _billingZipCtrl.text = _billingZip;
                                    _isEditingCard = true;
                                  });
                                }
                              },
                              icon: Icon(_isEditingCard ? Icons.check : Icons.edit, color: AppColors.primary, size: 14),
                              label: Text(
                                _isEditingCard ? 'Save' : 'Edit',
                                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isEditingCard) ...[
                          // Cardholder Name Input
                          const Text('Cardholder Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cardNameCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'Name on credit card',
                              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          // Card Number Input
                          const Text('Card Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cardNumCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(19),
                              CardNumberInputFormatter(),
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'xxxx-xxxx-xxxx-xxxx',
                              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          // Expiry & CVV Inputs Side-by-Side
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Expiry (MM/YY)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _cardExpiryCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(5),
                                        CardExpiryInputFormatter(),
                                      ],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        hintText: 'MM/YY',
                                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CVV / CVC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _cardCvvCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        hintText: 'xxx',
                                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Billing ZIP Input
                          const Text('Billing ZIP / Postal Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _billingZipCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'xxxxxx',
                              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ] else ...[
                          // Read-Only card view
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _cardNum.isEmpty ? 'xxxx-xxxx-xxxx-xxxx' : '•••• •••• •••• $_cardNum',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _cardNum.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                  letterSpacing: _cardNum.isEmpty ? 0.5 : 1.5,
                                ),
                              ),
                              if (_cardNum.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'VISA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CARDHOLDER',
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _cardName.isEmpty ? 'Name on credit card' : _cardName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _cardName.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXPIRES',
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _cardExpiry.isEmpty ? 'mm.yy' : _cardExpiry,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _cardExpiry.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CVV',
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _cardCvv.isEmpty ? 'xxx' : '***',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _cardCvv.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.divider, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LAST PAYMENT',
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _lastPaymentDate.isEmpty ? 'Last payment date' : _lastPaymentDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _lastPaymentDate.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NEXT PAYMENT',
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _nextPaymentDate.isEmpty ? 'Next payment date' : _nextPaymentDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _nextPaymentDate.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BILLING ZIP',
                                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _billingZip.isEmpty ? 'xxxxxx' : _billingZip,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _billingZip.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Changes button (Only visible when editing card details)
                  if (_isEditingCard) ...[
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save, size: 16, color: AppColors.white),
                      label: const Text('Save changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // 5. Linked Finance Section
                  Row(
                    children: const [
                      Icon(Icons.link, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'LINKED FINANCE',
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
                        _buildFinanceRow(
                          icon: Icons.account_balance_rounded,
                          title: 'Bank accounts',
                          count: data.bankCount,
                          tooltipMessage: data.bankAccounts.isEmpty
                              ? 'No active bank accounts'
                              : data.bankAccounts.map((acc) => '• ${acc.bankName} · ${acc.accountNumber ?? ""}').join('\n'),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildFinanceRow(
                          icon: Icons.credit_card_rounded,
                          title: 'Credit cards',
                          count: data.cardCount,
                          tooltipMessage: data.creditCards.isEmpty
                              ? 'No active credit cards'
                              : data.creditCards.map((card) => '• ${card.bankName} · ${card.cardName} · ${card.lastFour ?? ""}').join('\n'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Re-run onboarding to add or update banks and cards.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // 6. Action Buttons
                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, size: 16, color: AppColors.textPrimary),
                    label: const Text('Sign out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.divider),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _clearData,
                      icon: const Icon(Icons.delete_forever, size: 16, color: AppColors.error),
                      label: const Text(
                        'Clear all my data',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer version info
                  const Center(
                    child: Text(
                      'SGCashFlowAI™ v1.0',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      style: TextStyle(fontSize: 14, color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
      decoration: InputDecoration(
        fillColor: enabled ? AppColors.white : const Color(0xFFF8FAFC),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildFinanceRow({
    required IconData icon,
    required String title,
    required int count,
    String? tooltipMessage,
  }) {
    final tile = ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
        ],
      ),
      onTap: () {},
    );

    if (tooltipMessage != null && tooltipMessage.isNotEmpty) {
      return Tooltip(
        message: tooltipMessage,
        preferBelow: false,
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildMembershipOption({
    required String id,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String priceText,
  }) {
    final isSelected = _membershipTier == id;

    return InkWell(
      onTap: () {
        setState(() {
          _membershipTier = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox/Radio button
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Title & Subtitle descriptions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Pricing text
            Text(
              priceText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final buffer = StringBuffer();
    final cleanText = text.replaceAll(RegExp(r'\D'), '');

    // Check if AMEX (starts with 34 or 37, typically 15 digits)
    final isAmex = cleanText.startsWith('34') || cleanText.startsWith('37');

    if (isAmex) {
      // AMEX format: xxxx-xxxxxx-xxxxx
      for (int i = 0; i < cleanText.length; i++) {
        buffer.write(cleanText[i]);
        final nonZeroIndex = i + 1;
        if (nonZeroIndex == 4 || nonZeroIndex == 10) {
          if (nonZeroIndex < cleanText.length) {
            buffer.write('-');
          }
        }
      }
    } else {
      // Standard 16 digit format: xxxx-xxxx-xxxx-xxxx
      for (int i = 0; i < cleanText.length; i++) {
        buffer.write(cleanText[i]);
        final nonZeroIndex = i + 1;
        if (nonZeroIndex % 4 == 0 && nonZeroIndex < cleanText.length) {
          buffer.write('-');
        }
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final buffer = StringBuffer();
    final cleanText = text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex < cleanText.length) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
