import 'package:flutter/material.dart';

/// Centralized colour palette for monochromatic (black & white) Limkokwing
/// branding and grade badges.
class AppColors {
  AppColors._();

  // Monochromatic Brand Palette (Black & White)
  static const Color primaryRed = Color(0xFF111111);
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFFF2F2F2);
  static const Color charcoal = Color(0xFF141414);
  static const Color slate = Color(0xFF555555);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFD6D6D6);

  // Grade Semantic Colours
  static const Color gradeGreen = Color(0xFF1B873F);
  static const Color gradeGreenBg = Color(0xFFE8F5E9);

  static const Color gradeBlue = Color(0xFF1565C0);
  static const Color gradeBlueBg = Color(0xFFE3F2FD);

  static const Color gradeOrange = Color(0xFFEF6C00);
  static const Color gradeOrangeBg = Color(0xFFFFF3E0);

  static const Color gradeBrown = Color(0xFF6D4C41);
  static const Color gradeBrownBg = Color(0xFFEFEBE9);

  static const Color gradeRed = Color(0xFFC62828);
  static const Color gradeRedBg = Color(0xFFFFEBEE);

  /// Returns foreground colour based on letter grade.
  static Color gradeForeground(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A-':
        return gradeGreen;
      case 'B+':
      case 'B':
      case 'B-':
        return gradeBlue;
      case 'C+':
      case 'C':
      case 'C-':
        return gradeOrange;
      case 'D':
        return gradeBrown;
      default:
        return gradeRed;
    }
  }

  /// Returns soft background colour based on letter grade.
  static Color gradeBackground(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A-':
        return gradeGreenBg;
      case 'B+':
      case 'B':
      case 'B-':
        return gradeBlueBg;
      case 'C+':
      case 'C':
      case 'C-':
        return gradeOrangeBg;
      case 'D':
        return gradeBrownBg;
      default:
        return gradeRedBg;
    }
  }
}

/// Application Material 3 theme definition.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryRed,
      primary: AppColors.primaryRed,
      onPrimary: Colors.white,
      secondary: AppColors.charcoal,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.charcoal,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gradeRed),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(color: AppColors.primaryRed),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
    );
  }
}