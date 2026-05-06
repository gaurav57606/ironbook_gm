import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bg          = Color(0xFF0C0C0E);  // --bg
  static const Color bg2         = Color(0xFF141417);  // --bg2
  static const Color bg3         = Color(0xFF1C1C21);  // --bg3
  static const Color bg4         = Color(0xFF242429);  // --bg4

  // Brand
  static const Color primary     = Color(0xFFFF6B2B);  // --orange
  static const Color primaryDim  = Color(0xFFCC4A15);  // --orangeD
  static const Color orange      = Color(0xFFFF6B2B);  // Alias for frontui
  static const Color orangeD     = Color(0xFFCC4A15);  // Alias for frontui

  // Semantic
  static const Color active      = Color(0xFF22C55E);  // --green
  static const Color green       = Color(0xFF22C55E);  // Alias for screens
  static const Color success     = active;             // Mapping for screens
  static const Color expiring    = Color(0xFFF59E0B);  // --amber
  static const Color amber       = Color(0xFFF59E0B);  // Alias for screens
  static const Color expired     = Color(0xFFEF4444);  // --red
  static const Color error       = Color(0xFFEF4444);  // --red
  static const Color red         = Color(0xFFEF4444);  // Alias for screens
  static const Color warning     = Color(0xFFF59E0B);  // --amber
  static const Color blue        = Color(0xFF3B82F6);  // --blue (added for completeness)

  // Text
  static const Color textPrimary    = Color(0xFFF0EEF6);  // --text
  static const Color textSecondary  = Color(0xFF9896A4);  // --text2
  static const Color textMuted      = Color(0xFF5C5A67);  // --text3
  static const Color text           = Color(0xFFF0EEF6);  // Alias for frontui
  static const Color text2          = Color(0xFF9896A4);  // Alias for frontui
  static const Color text3          = Color(0xFF5C5A67);  // Alias for frontui

  // UI
  static const Color border      = Color(0xFF2A2A30);  // --border
  static const Color divider     = Color(0xFF1C1C21);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFF922B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF2C2C34), Color(0xFF1C1C21)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bg, Color(0xFF141417)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Elevation Colors (Lighter for higher elevation)
  static const Color elevation1 = Color(0xFF141417);
  static const Color elevation2 = Color(0xFF1C1C21);
  static const Color elevation3 = Color(0xFF242429);
  static const Color elevation4 = Color(0xFF2C2C34);
}









