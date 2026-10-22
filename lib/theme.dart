import 'package:flutter/material.dart';

/// PassKeep Matcha Palette (Tailored from user visual spec)
class AppColors {
  // Primary Dark Forest Matcha
  static const Color primaryMatcha = Color(0xFF3B5B43);
  
  // Secondary Sage Matcha
  static const Color sageMatcha = Color(0xFF78987E);
  
  // Soft Pistachio Mint (Container / Accent)
  static const Color pistachioMint = Color(0xFFBACDB3);
  
  // Background Warm Rice Cream
  static const Color oatMilkBg = Color(0xFFF2EDE4);
  
  // Card Surface
  static const Color cardSurface = Color(0xFFFFFFFF);
  
  // High contrast text
  static const Color textPrimary = Color(0xFF223427);
  
  // Subtitle / Muted text
  static const Color textMuted = Color(0xFF5E7363);
  
  // Clean border
  static const Color borderMuted = Color(0xFFD8E2D4);
  
  // Destructive / Alert
  static const Color alertPersimmon = Color(0xFFC74A3D);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.oatMilkBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryMatcha,
        onPrimary: Colors.white,
        secondary: AppColors.sageMatcha,
        onSecondary: Colors.white,
        error: AppColors.alertPersimmon,
        onError: Colors.white,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
    );
  }
}
