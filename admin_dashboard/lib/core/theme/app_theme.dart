import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F6D3B);
  static const primaryLight = Color(0xFF1A8A4A);
  static const bgPrimary = Color(0xFFF8F9FB);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgDark = Color(0xFF13161C);
  static const bgDarkCard = Color(0xFF242830);
  static const bgDarkBorder = Color(0xFF2E3340);
  static const bgDarkSurface = Color(0xFF1A1D23);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF8B95A3);
  static const sidebarBg = Color(0xFF0F6D3B);
  
  static const statusGreen = Color(0xFF16A34A);
  static const statusGreenBg = Color(0xFFDCFCE7);
  static const statusAmber = Color(0xFFD97706);
  static const statusAmberBg = Color(0xFFFEF3C7);
  static const statusRed = Color(0xFFDC2626);
  static const statusRedBg = Color(0xFFFEE2E2);
  static const statusBlue = Color(0xFF2563EB);
  static const statusBlueBg = Color(0xFFDEF1FF);
  static const statusGray = Color(0xFF6B7280);
  static const statusGrayBg = Color(0xFFF3F4F6);
  
  static const accentTeal = Color(0xFF0891B2);
  static const accentGold = Color(0xFFD97706);
  static const accentOrange = Color(0xFFF97316);
  static const accentPurple = Color(0xFFA855F7);
  static const accentMint = Color(0xFF10B981);
}

class AppTextStyles {
  static const displayLarge = TextStyle(fontSize: 57, fontWeight: FontWeight.bold);
  static const displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.bold);
  static const headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static const headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
  static const headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  
  static const titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static const titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  
  static const bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
  
  static const labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  
  static const statValue = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static const statLabel = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      cardColor: AppColors.bgCard,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentTeal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.bgDarkCard,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentTeal,
        surface: AppColors.bgDarkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
    );
  }
}
