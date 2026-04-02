import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class IronBookApp extends ConsumerWidget {
  final bool hiveHealthy;
  final bool useGoogleFonts;
  
  const IronBookApp({
    super.key,
    required this.hiveHealthy,
    this.useGoogleFonts = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'IronBook GM',
      theme: AppTheme.darkTheme(useGoogleFonts: useGoogleFonts),
      routerConfig: ref.watch(routerProvider(hiveHealthy)),
      debugShowCheckedModeBanner: false,
    );
  }
}
