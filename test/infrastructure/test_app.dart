import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';

Widget createTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: child,
  );
}

Widget createTestRouterApp({
  required RouterConfig<Object> routerConfig,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: routerConfig,
    ),
  );
}
