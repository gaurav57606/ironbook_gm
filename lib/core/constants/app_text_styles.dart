import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static bool useGoogleFonts = true;

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
    if (!useGoogleFonts) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      textStyle: TextStyle(letterSpacing: letterSpacing),
    );
  }

  // Sizing Constants from FrontUI
  static const double h1Size = 11.0;
  static const double h2Size = 24.0;
  static const double bodySize = 12.0;
  static const double smallSize = 10.0;
  static const double tinySize = 9.0;
  static const double microSize = 8.0;

  static TextStyle get heroNumber => _font(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary);

  static TextStyle get sectionTitle => _font(
    fontSize: tinySize,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );

  static TextStyle get cardTitle => _font(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get cardSubtitle => _font(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle get body => _font(fontSize: bodySize, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get bodySmall => _font(fontSize: smallSize, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get label => _font(fontSize: smallSize, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get memberName => _font(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get invoiceValue => _font(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary);

  static TextStyle get h1 => _font(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary);

  static TextStyle get h2 => _font(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  
  static TextStyle get h3 => _font(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get buttonSmall => _font(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
}
