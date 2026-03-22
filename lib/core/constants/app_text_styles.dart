import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heroNumber = GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
  );

  static TextStyle sectionTitle = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    textStyle: const TextStyle(
      textBaseline: TextBaseline.alphabetic,
      letterSpacing: 1.0,
    ),
  );

  static TextStyle cardTitle = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle cardSubtitle = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle body = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle memberName = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle invoiceValue = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
}
