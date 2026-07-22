import 'package:flutter/material.dart';

/// Visual direction will follow boss designs when available.
/// Until then: warm night-out palette, not purple-default AI look.
class AppTheme {
  static const Color ink = Color(0xFF1A1512);
  static const Color cream = Color(0xFFF7F1E8);
  static const Color ember = Color(0xFFC45C26);
  static const Color moss = Color(0xFF2F4F3E);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ember,
        primary: ember,
        secondary: moss,
        surface: cream,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ink,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF5C534C),
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ember,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
