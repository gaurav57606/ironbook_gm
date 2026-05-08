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
import 'services/fcm_service.dart';
import 'services/config_service.dart';
import 'services/logger_service.dart';
import 'package:ironbook_gm/core/sync/midnight_engine.dart';

typedef BootstrapResult = ({bool initialized});

class AppBootstrap {
  static Future<BootstrapResult> initialize(ProviderContainer container) async {
    final logger = container.read(loggerProvider);
    logger.info('Starting Tier 1 (Native/Local) Initialization...', category: 'BOOT');

    try {
      // 1. Core Config
      logger.info('Initializing ConfigService...', category: 'BOOT');
      await container.read(configServiceProvider).init();
      
      // 2. System UI Setup
      _setupSystemUI();
      
      // 3. Security Essentials (Secure Storage)
      logger.info('Initializing HMAC Service...', category: 'BOOT');
      await container.read(hmacServiceProvider).getInstallationId();
      
      // 4. Primary Database (Drift)
      logger.info('Opening Drift Outbox Database...', category: 'DB');
      // Accessing the database triggers initialization
      container.read(outboxDatabaseProvider);
      
      if (kDebugMode) {
        logger.info('Seeding debug data if empty...', category: 'DB');
        await SeedData.seedIfEmpty(container);
      }
      
      // 5. Tier 1 Success
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
      logger.info('Tier 1 Initialization Complete.', category: 'BOOT');
      
      // Schedule TIER 2 (Post-Frame: Cloud/Background)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _runTier2(container);
      });
      
      return (initialized: true);
    } catch (e, stack) {
      logger.critical('CRITICAL TIER 1 FAILURE: $e', category: 'BOOT', error: e, stackTrace: stack);
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Pending; // Revert/Keep pending
      return (initialized: false);
    }
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
    final logger = container.read(loggerProvider);
    logger.info('Starting Tier 2 (Cloud/Background) Initialization...', category: 'BOOT');
    container.read(tier2StatusProvider.notifier).state = Tier2Status.pending;
    
    try {
      // 1. Firebase & Cloud Services
      logger.info('Initializing Firebase...', category: 'FIREBASE');
      
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15));

        // Mark Firebase as initialized for providers and logger
        container.read(firebaseInitializedProvider.notifier).state = true;
        logger.setFirebaseInitialized(true);
        logger.info('Firebase Initialized Successfully.', category: 'FIREBASE');

        // 1.1 Configure Monitoring (Connecting to early handlers from main.dart)
        if (!kIsWeb) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
          
          // Re-hook Flutter error handler to Crashlytics
          final originalFlutterError = FlutterError.onError;
          FlutterError.onError = (errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
            originalFlutterError?.call(errorDetails);
          };

          // Re-hook Platform error handler to Crashlytics
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };

          logger.info('Crashlytics & Analytics hooked into global handlers.', category: 'FIREBASE');
        }

        // 1.2 Notifications
        if (!kIsWeb) {
          logger.info('Initializing Notifications...', category: 'NOTIFICATION');
          try {
            await NotificationService.init(container).timeout(const Duration(seconds: 7));
            await FcmService.init(container).timeout(const Duration(seconds: 7));
          } catch (e) {
            logger.error('Notification system initialization failed', category: 'NOTIFICATION', error: e);
          }
        }

        // Notify AuthNotifier that Firebase is ready
        final auth = FirebaseAuth.instance;
        container.read(authProvider.notifier).onFirebaseReady(auth);
        
      } catch (e, stack) {
        logger.warn('Cloud services initialization failed or timed out: $e', category: 'FIREBASE', error: e, stackTrace: stack);
        // We continue in degraded mode
      }

      // 2. Background Tasks (Native Only)
      if (!kIsWeb) {
        logger.info('Initializing Workmanager...', category: 'WORKER');
        try {
          await Workmanager().initialize(
            MidnightEngine.callbackDispatcher,
            isInDebugMode: kDebugMode,
          ).timeout(const Duration(seconds: 5));
          
          // Idempotent registration: Clear existing before setting production frequency
          await Workmanager().cancelAll(); 
          
          await Workmanager().registerPeriodicTask(
            "1",
            "midnightTask",
            frequency: const Duration(hours: 12),
            existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
            constraints: Constraints(
              networkType: NetworkType.connected,
              requiresBatteryNotLow: true,
            ),
          );
          logger.info('Workmanager Task Registered.', category: 'WORKER');
        } catch (e) {
          logger.error('Workmanager Init Failed: $e', category: 'WORKER', error: e);
        }
      }

      // 3. Start Sync Worker (Only if Firebase initialized)
      if (container.read(firebaseInitializedProvider)) {
        logger.info('Starting Periodic Sync...', category: 'SYNC');
        container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));
        container.read(tier2StatusProvider.notifier).state = Tier2Status.ready;
        container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
      } else {
        logger.warn('Entering Degraded Mode (No Cloud Sync).', category: 'BOOT');
        container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
        container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
      }

      logger.info('Tier 2 Initialization Complete.', category: 'BOOT');
      
    } catch (e, stack) {
      logger.critical('CRITICAL TIER 2 FAILURE: $e', category: 'BOOT', error: e, stackTrace: stack);
      container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
    }
  }
}
