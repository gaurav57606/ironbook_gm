import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';

import 'package:ironbook_gm/core/data/seed_data.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'services/notification_service.dart';
import 'services/config_service.dart';
import 'services/logger_service.dart';
import 'package:ironbook_gm/core/sync/midnight_engine.dart';

typedef BootstrapResult = ({bool initialized});

class AppBootstrap {
  static Future<BootstrapResult> initialize(ProviderContainer container) async {
    // --- TIER 1 (Blocking: Native/Local) ---
    // Note: WidgetsFlutterBinding.ensureInitialized() called in main()
    
    // 1. Core Config & Local Engine
    await container.read(configServiceProvider).init();
    
    // 2. System UI Setup
    _setupSystemUI();
    
    final logger = container.read(loggerProvider);
    logger.info('Bootstrap Tier 1: Local Services Initialization...');

    // 3. Initialize HMAC key via provider to ensure ConfigService is ready
    await container.read(hmacServiceProvider).getInstallationId();
    
    // 4. Open Primary Authority (Drift/SQLite)
    logger.info('Bootstrap Tier 1: Drift Initialization...');
    bool initialized = true;
    try {
      // Accessing the database triggers initialization
      container.read(outboxDatabaseProvider);
    } catch (e) {
      logger.error('Bootstrap Tier 1: Drift Initialization FAILED', e);
      initialized = false;
    }
    
    if (initialized && kDebugMode) {
      await SeedData.seedIfEmpty(container);
    }
    
    // 5. Set Initial State
    container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
    
    // Schedule TIER 2 (Post-Frame: Cloud/Background)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _runTier2(container);
    });
    
    return (initialized: initialized);
  }

  static void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  static Future<void> _runTier2(ProviderContainer container) async {
    debugPrint('Bootstrap Tier 2: Starting...');
    container.read(tier2StatusProvider.notifier).state = Tier2Status.pending;
    
    try {
      // 1. Firebase & Cloud Services (Unified Platform Config)
      debugPrint('Bootstrap Tier 2: Cloud Services...');
      
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));

        // 1.1 Configure Monitoring (Hardening)
        if (!kIsWeb) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
          
          FlutterError.onError = (errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          };
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };

          FirebaseCrashlytics.instance.log('IronBook Tier 2 Cloud Services Started');
        }

        await Future.wait([
          if (!kIsWeb) NotificationService.init(),
        ]).timeout(const Duration(seconds: 10));

        // Notify AuthNotifier that Firebase is ready
        final auth = FirebaseAuth.instance;
        container.read(authProvider.notifier).onFirebaseReady(auth);
      } catch (e) {
        debugPrint('Firebase Tier 2 Warning: Cloud initialization failed or timed out: $e');
        // We continue anyway to allow "Audit/Offline Mode"
      }

      // 2. Background Tasks (Native Only)
      if (!kIsWeb) {
        debugPrint('Bootstrap Tier 2: Workmanager...');
        try {
          await Workmanager().initialize(
            MidnightEngine.callbackDispatcher,
          );
          await Workmanager().registerPeriodicTask(
            "1",
            "midnightTask",
            frequency: const Duration(hours: 12),
          );
        } catch (e) {
          debugPrint('Workmanager Init Failed: $e');
        }
      }

      // 3. Start Sync Worker
      debugPrint('Bootstrap Tier 2: SyncWorker...');
      container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));

      // Successfully ready
      container.read(tier2StatusProvider.notifier).state = Tier2Status.ready;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
      debugPrint('Bootstrap Tier 2: Complete.');
      
    } catch (e) {
      debugPrint('Bootstrap Tier 2 (Degraded): $e');
      if (e is TimeoutException) {
        debugPrint('Bootstrap Tier 2: Cloud services timed out after 10s.');
      }
      
      container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
      
      // Still attempt to start local services even if cloud timed out
      try {
        container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));
      } catch (_) {}
    }
  }
}
