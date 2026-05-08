import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/bootstrap.dart';
import 'core/providers/base_providers.dart';
import 'core/services/logger_service.dart';
import 'app.dart';
import 'shared/widgets/production_error_boundary.dart';

void main() async {
  // 1. Core Binding & Early Error Handling
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize early error handling (Before Firebase)
  // This captures errors during the bootstrap phase itself
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // In production, this will eventually be handled by Crashlytics via LoggerService
    // For now, we ensure it's at least printed and ready for the next phase
    debugPrint('Early FlutterError captured: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Early Platform Error captured: $error');
    return true; // Prevent app from killing itself immediately
  };

  // Replace Red Screen of Death in Production
  if (!kDebugMode) {
    ErrorWidget.builder = (details) => ProductionErrorBoundary(errorDetails: details);
  }

  try {
    // 2. Initial Local State (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    
    // 3. Provider Container
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    
    final logger = container.read(loggerProvider);
    logger.info('IronBook GM: Starting bootstrap sequence...', category: 'BOOT');

    // 4. Tier 1 Initialization (Drift) - Fast & Blocking
    final result = await AppBootstrap.initialize(container);

    // 5. Run App
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: IronBookApp(storageHealthy: result.initialized),
      ),
    );
  } catch (e, stack) {
    debugPrint('FATAL STARTUP ERROR: $e\n$stack');
    // Fallback UI if everything fails
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Fatal Startup Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A critical error occurred while starting the app.\n\nError: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
