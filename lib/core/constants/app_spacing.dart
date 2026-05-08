import 'package:flutter/material.dart';

/// Design tokens for consistent spacing across the application.
/// Follows a 4px grid system.
class AppSpacing {
  // Base units
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;

  // Semantic spacing
  static const double screenPadding = 14.0; // The standard horizontal padding for screens
  static const double cardPadding = 16.0;
  static const double inputPadding = 14.0;
  static const double elementGap = 8.0;
  static const double sectionGap = 24.0;

  // Gap Widgets for easier use in Columns/Rows
  static const SizedBox gapXS = SizedBox(width: xs, height: xs);
  static const SizedBox gapS = SizedBox(width: s, height: s);
  static const SizedBox gapM = SizedBox(width: m, height: m);
  static const SizedBox gapL = SizedBox(width: l, height: l);
  static const SizedBox gapXL = SizedBox(width: xl, height: xl);
  static const SizedBox gapXXL = SizedBox(width: xxl, height: xxl);
}
