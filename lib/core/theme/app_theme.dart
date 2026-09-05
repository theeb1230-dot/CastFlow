import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color primaryCyan = Color(0xFF00F2FE);
  static const Color secondaryBlue = Color(0xFF4FACFE);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF8FAFC);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[primaryCyan, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryCyan,
      secondary: secondaryBlue,
      surface: surfaceDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
