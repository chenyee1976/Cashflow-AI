import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension TopSnackBarExtension on BuildContext {
  void showTopSnackBar(String message, {bool isError = false}) {
    final height = MediaQuery.of(this).size.height;
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: height - 100,
          left: 16,
          right: 16,
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
