import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/bootstrap.dart';
import 'core/providers/base_providers.dart';
import 'app.dart';

void main() async {
  // 1. Core Binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initial Local State (SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  
  // 3. Provider Container
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  
  // 4. Tier 1 Initialization (Drift) - Fast & Blocking
  final result = await AppBootstrap.initialize(container);


  // 5. Run App (Spawns Router -> Splash)
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: IronBookApp(storageHealthy: result.initialized),
    ),
  );
}









