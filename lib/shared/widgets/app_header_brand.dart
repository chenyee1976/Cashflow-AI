import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppHeaderBrand extends StatelessWidget {
  const AppHeaderBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'CashFlow AI™',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
