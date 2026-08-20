import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Severity Colors
  static const Color severityLow = Color(0xFF10B981);      // 1-3
  static const Color severityMedium = Color(0xFFF59E0B);   // 4-6
  static const Color severityHigh = Color(0xFFF97316);     // 7-8
  static const Color severityCritical = Color(0xFFEF4444); // 9-10

  static Color getSeverityColor(int score) {
    if (score <= 3) return severityLow;
    if (score <= 6) return severityMedium;
    if (score <= 8) return severityHigh;
    return severityCritical;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryTeal,
        background: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0.5,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
