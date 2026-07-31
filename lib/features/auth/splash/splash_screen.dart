import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/secure_storage/secure_storage_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for splash screen duration (2s total)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      final storage = ref.read(secureStorageProvider);
      final db = ref.read(appDatabaseProvider);
      final sessionValid = await storage.isSessionValid();
      final onboardingComplete = await storage.isOnboardingComplete();
      
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = await storage.getUserId() ?? 'chenyee_user';
      final savedEmail = prefs.getString('tester_email') ?? await storage.getGoogleEmail() ?? 'chenwallpaper@gmail.com';
      
      final analytics = ref.read(analyticsServiceProvider);
      analytics.setUser(savedUserId, savedEmail);

      final existingUser = await db.getUserById(savedUserId);
      final statements = await db.getStatementsByUser(savedUserId);
      final bankAccounts = await db.getBankAccountsByUser(savedUserId);
      final creditCards = await db.getCreditCardsByUser(savedUserId);
      final isExistingAccount = existingUser != null || statements.isNotEmpty || bankAccounts.isNotEmpty || creditCards.isNotEmpty || onboardingComplete;

      if (!mounted) return;

      if (isExistingAccount) {
        await storage.setOnboardingComplete();
        await storage.saveSessionExpiry(DateTime.now().add(const Duration(days: 30)));
        context.go('/home/dashboard');
      } else if (sessionValid) {
        context.go('/onboarding');
      } else {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Splash session check error: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder Widget
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SGCashFlowAI™',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Beta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your Personal AI Treasury',
                style: const TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
