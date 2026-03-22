import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg      = Color(0xFF0C0C0E);
  static const bg2     = Color(0xFF141417);
  static const bg3     = Color(0xFF1C1C21);
  static const bg4     = Color(0xFF242429);

  static const orange  = Color(0xFFFF6B2B);
  static const orange2 = Color(0xFFFF8C5A);
  static const orangeD = Color(0xFFCC4A15);

  static const green   = Color(0xFF22C55E);
  static const red     = Color(0xFFEF4444);
  static const amber   = Color(0xFFF59E0B);
  static const blue    = Color(0xFF3B82F6);

  static const text    = Color(0xFFF0EEF6);
  static const text2   = Color(0xFF9896A4);
  static const text3   = Color(0xFF5C5A67);
  static const border  = Color(0xFF2A2A30);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.orange,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      surface: AppColors.bg3,
      background: AppColors.bg,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: AppColors.text),
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 14),
        bodyMedium: TextStyle(color: AppColors.text2, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.text3, fontSize: 11),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg2,
      selectedItemColor: AppColors.orange,
      unselectedItemColor: AppColors.text3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.orange),
      ),
      hintStyle: const TextStyle(color: AppColors.text3),
      labelStyle: const TextStyle(color: AppColors.text2),
    ),
  );
}
