import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1E90FF);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFE8F4FF);

  // Background & Surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFFAAAAAA);

  // Semantic
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // UI
  static const Color divider = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  // Finance
  static const Color income = Color(0xFF27AE60);
  static const Color expense = Color(0xFFE74C3C);

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF1E90FF),
    Color(0xFF27AE60),
    Color(0xFFF39C12),
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF2980B9),
  ];

  // Pro Theme (Royal Electric Amethyst)
  static const Color proPrimary = Color(0xFF7C3AED);
  static const Color proPrimaryDark = Color(0xFF6D28D9);
  static const Color proAccent = Color(0xFF9333EA);
  static const Color proBackground = Color(0xFF0F172A);
  static const Color proCardBackground = Color(0xFF1E293B);
  static const Color proGold = Color(0xFFF59E0B);
  static const Color proGoldLight = Color(0xFFFEF3C7);
  static const LinearGradient proGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient proGoldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Pro Theme Aliases
  static const Color proCardBg = Color(0xFF1E293B);
  static const Color proBorder = Color(0xFF334155);
  static const Color proSurface = Color(0xFF1E293B);
  static const Color proSubtext = Color(0xFF94A3B8);
}
