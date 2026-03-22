import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bg          = Color(0xFF0C0C0E);  // main bg — true black for AMOLED
  static const Color bg2         = Color(0xFF161618);  // cards
  static const Color bg3         = Color(0xFF1E1E1E);  // elevated cards
  static const Color bg4         = Color(0xFF272727);  // inputs, chips

  // Brand
  static const Color primary     = Color(0xFFFF6B2B);  // electric orange
  static const Color primaryDim  = Color(0xFF7A3010);  // primary tapped state

  // Semantic
  static const Color expired     = Color(0xFFFF3B3B);  // red — expired members
  static const Color expiring    = Color(0xFFFFB800);  // amber — ≤7 days left
  static const Color active      = Color(0xFF3DCC7E);  // green — active members

  // Text
  static const Color textPrimary    = Color(0xFFF2F2EC);
  static const Color textSecondary  = Color(0xFF9A9A8A);
  static const Color textMuted      = Color(0xFF4E4E44);

  // UI
  static const Color border      = Color(0xFF252520);
  static const Color divider     = Color(0xFF1C1C1A);
}
