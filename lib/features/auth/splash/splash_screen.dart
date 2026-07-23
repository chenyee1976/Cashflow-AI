import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/secure_storage/secure_storage_service.dart';
import '../../../../data/database/app_database.dart';
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
      
      const userId = 'chenyee_user';
      final existingUser = await db.getUserById(userId);
      final statements = await db.getStatementsByUser(userId);
      final isExistingAccount = existingUser != null || statements.isNotEmpty || onboardingComplete;

      if (!mounted) return;

      if (sessionValid) {
        if (isExistingAccount) {
          context.go('/home/dashboard');
        } else {
          context.go('/onboarding');
        }
      } else {
        context.go('/login');
      }
    } catch (e) {
      // flutter_secure_storage may not work on web — go to login
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
              Text(
                'CashFlow AI™',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
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
