import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension TopSnackBarExtension on BuildContext {
  void showTopSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    context.showTopSnackBar(message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    context.showTopSnackBar(message, isError: true);
  }
}
