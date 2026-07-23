import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/cashflow/upload/upload_screen.dart';
import '../../features/cashflow/review/transaction_review_screen.dart';
import '../../features/cashflow/statement/cash_flow_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';

import '../../features/rewards/rewards_screen.dart';
import '../../features/rewards/miles_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/account/account_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // ── Auth ───────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Onboarding ─────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Main shell with bottom tab bar ─────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/home/cashflow',
            builder: (context, state) => const CashFlowHomeScreen(),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) => const UploadScreen(),
              ),
              GoRoute(
                path: 'processing',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Processing'),
              ),
              GoRoute(
                path: 'review',
                builder: (context, state) {
                  final params = state.extra as Map<String, dynamic>? ?? {};
                  return TransactionReviewScreen(
                    fileType: params['fileType'] as String? ?? 'bank',
                    fileName: params['fileName'] as String? ?? 'statement.pdf',
                    statementId: params['statementId'] as String? ?? '',
                  );
                },
              ),
              GoRoute(
                path: 'statement',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Cash Flow Statement'),
              ),
            ],
          ),
          GoRoute(
            path: '/home/rewards',
            builder: (context, state) => const RewardsScreen(),
          ),
          GoRoute(
            path: '/home/miles',
            builder: (context, state) => const MilesScreen(),
          ),
          GoRoute(
            path: '/home/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/home/account',
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Bottom tab shell — wraps all /home/* routes
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    _TabItem('/home/dashboard', Icons.home_outlined, Icons.home, 'Home'),
    _TabItem('/home/cashflow', Icons.bar_chart_outlined, Icons.bar_chart,
        'Cash Flow'),
    _TabItem('/home/rewards', Icons.credit_card_outlined, Icons.credit_card,
        'Rewards'),
    _TabItem('/home/miles', Icons.flight_outlined, Icons.flight, 'Miles'),
    _TabItem('/home/support', Icons.chat_bubble_outline, Icons.chat_bubble,
        'Support'),
    _TabItem('/home/account', Icons.person_outline, Icons.person, 'Account'),
  ];

  int _calculateCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home/dashboard')) return 0;
    if (location.startsWith('/home/cashflow')) return 1;
    if (location.startsWith('/home/rewards')) return 2;
    if (location.startsWith('/home/miles')) return 3;
    if (location.startsWith('/home/support')) return 4;
    if (location.startsWith('/home/account')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateCurrentIndex(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner ad placeholder
          Container(
            height: 50,
            color: const Color(0xFFF8FAFC),
            child: const Center(
              child: Text(
                'Financial Services Ad',
                style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
              ),
            ),
          ),
          BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            onTap: (i) {
              context.go(_tabs[i].path);
            },
            items: _tabs
                .map((t) => BottomNavigationBarItem(
                      icon: Icon(t.icon),
                      activeIcon: Icon(t.activeIcon),
                      label: t.label,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem(this.path, this.icon, this.activeIcon, this.label);
}
