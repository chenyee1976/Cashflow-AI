import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppFooterBrand extends StatelessWidget {
  const AppFooterBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          'SGCashFlowAI™ v1.0 — made in Singapore 🇸🇬',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
