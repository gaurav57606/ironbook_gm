import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'core/services/fcm_service.dart';

class IronBookApp extends ConsumerWidget {
  final bool hiveHealthy;
  
  const IronBookApp({
    super.key,
    required this.hiveHealthy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: hiveHealthy is passed to the router provider via a state provider or similar
    // For now, we'll implement the logic inside the router directly by watching a health provider
    
    return MaterialApp.router(
      title: 'IronBook GM',
      theme: AppTheme.darkTheme,
      routerConfig: ref.watch(routerProvider(hiveHealthy)),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap with FCM navigator key for kill signal navigation
        return Navigator(
          key: FcmService.navigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => child!,
          ),
        );
      },
    );
  }
}
