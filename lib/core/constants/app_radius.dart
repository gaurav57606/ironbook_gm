import 'package:flutter/material.dart';

/// Design tokens for consistent corner rounding.
class AppRadius {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 14.0; // Standard for containers/cards in IronBook
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double pill = 999.0;

  static BorderRadius get radiusXS => BorderRadius.circular(xs);
  static BorderRadius get radiusS => BorderRadius.circular(s);
  static BorderRadius get radiusM => BorderRadius.circular(m);
  static BorderRadius get radiusL => BorderRadius.circular(l);
  static BorderRadius get radiusXL => BorderRadius.circular(xl);
  static BorderRadius get radiusXXL => BorderRadius.circular(xxl);
  static BorderRadius get radiusPill => BorderRadius.circular(pill);
}
