import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData darkTheme({bool useGoogleFonts = true}) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.orange,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        secondary: AppColors.orangeD,
        surface: AppColors.bg3,
        error: AppColors.red,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 11),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 11),
      ),
    );

    if (!useGoogleFonts) return baseTheme;

    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w400, height: 1.6),
          bodySmall: TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w400, height: 1.6),
          labelMedium: TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w400),
          labelSmall: TextStyle(color: AppColors.text3, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2),
        ),
      ),
    );
  }
}
