import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Global configuration for all tests in this directory
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTextStyles.useGoogleFonts = false;
  
  // We can also add global setup here if needed
  await testMain();
}


