import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'providers/bootstrap_provider.dart';

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
    final bootstrap = ref.watch(bootstrapStateProvider);
    final isDegraded = bootstrap == BootstrapPhase.tier2Degraded || !hiveHealthy;

    Widget app = MaterialApp.router(
      title: 'IronBook GM',
      theme: AppTheme.darkTheme(useGoogleFonts: useGoogleFonts),
      routerConfig: ref.watch(routerProvider(hiveHealthy)),
      debugShowCheckedModeBanner: false,
    );

    if (isDegraded) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Banner(
          message: !hiveHealthy ? 'STORAGE ERROR' : 'OFFLINE MODE',
          location: BannerLocation.topEnd,
          color: !hiveHealthy ? Colors.red : Colors.orange,
          child: app,
        ),
      );
    }

    return app;
  }
}
