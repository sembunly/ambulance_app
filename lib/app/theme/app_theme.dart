import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1466C4);
  static const primaryDim = Color(0xFF0F4F9D);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF8FAFC);
  static const border = Color(0xFFE1E5EB);
  static const border2 = Color(0xFFC9D1DC);
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF98A2B3);
  static const error = Color(0xFFD92D20);
  static const success = Color(0xFF039855);
  static const primarySoft = Color(0xFFEAF3FF);
  static const onPrimary = surface;
}

class AppColorTokens {
  const AppColorTokens();

  Color get background => AppColors.background;
  Color get surface => AppColors.surface;
  Color get surface2 => AppColors.surface2;
  Color get border => AppColors.border;
  Color get border2 => AppColors.border2;
  Color get textPrimary => AppColors.textPrimary;
  Color get textSecondary => AppColors.textSecondary;
  Color get textMuted => AppColors.textMuted;
  Color get primary => AppColors.primary;
  Color get primarySoft => AppColors.primarySoft;
  Color get error => AppColors.error;
  Color get success => AppColors.success;
  Color get onPrimary => AppColors.onPrimary;
}

extension AppThemeContext on BuildContext {
  AppColorTokens get appColors => const AppColorTokens();
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}
