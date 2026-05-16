import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

import 'package:ironbook_gm/core/data/seed_data.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/config_service.dart';
import 'services/logger_service.dart';
import 'package:ironbook_gm/core/sync/midnight_engine.dart';

const bool isTestEnvironment = bool.fromEnvironment('FLUTTER_TEST');

typedef BootstrapResult = ({bool initialized});

class AppBootstrap {
  static Future<BootstrapResult> initialize(ProviderContainer container) async {
    final logger = container.read(loggerProvider);
    final stopwatch = Stopwatch()..start();
    logger.info('Starting Tier 1 (Native/Local) Initialization...', category: 'BOOT');

    try {
      final result = await _runTier1(container).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          logger.critical('TIER 1 INITIALIZATION TIMEOUT: Possible dead-lock or file system delay.', category: 'BOOT');
          return (initialized: false);
        },
      );
      
      logger.info('Tier 1 Startup took: ${stopwatch.elapsedMilliseconds}ms', category: 'BOOT');
      return result;
    } catch (e, stack) {
      logger.critical('FATAL TIER 1 FAILURE: $e', category: 'BOOT', error: e, stackTrace: stack);
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Pending;
      return (initialized: false);
    }
  }

  static Future<BootstrapResult> _runTier1(ProviderContainer container) async {
    final logger = container.read(loggerProvider);
    
    logger.info('Initializing ConfigService...', category: 'BOOT');
    await container.read(configServiceProvider).init().timeout(const Duration(seconds: 2));
    
    _setupSystemUI();
    
    logger.info('Initializing HMAC Service...', category: 'BOOT');
    await container.read(hmacServiceProvider).getInstallationId().timeout(const Duration(seconds: 3));
    
    logger.info('Opening Drift Outbox Database...', category: 'DB');
    container.read(outboxDatabaseProvider);
    
    container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
    logger.info('Tier 1 Initialization Complete.', category: 'BOOT');
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _runTier2(container);
    });
    
    return (initialized: true);
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
    final stopwatch = Stopwatch()..start();
    logger.info('Starting Tier 2 (Cloud/Background) Initialization...', category: 'BOOT');
    container.read(tier2StatusProvider.notifier).state = Tier2Status.pending;
    
    try {
      // 0. Non-essential pre-auth tasks (NO provider reads that need auth here)
      try {
        await container.read(syncCoordinatorProvider).clearAllLocks().timeout(const Duration(seconds: 2));
      } catch (e) {
        logger.warn('Non-essential native initialization failed: $e', category: 'BOOT');
      }

      // 1. Firebase & Cloud Services
      logger.info('Initializing Firebase...', category: 'FIREBASE');
      
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15));

        container.read(firebaseInitializedProvider.notifier).state = true;
        logger.setFirebaseInitialized(true);
        logger.info('Firebase Initialized Successfully (${stopwatch.elapsedMilliseconds}ms).', category: 'FIREBASE');

          if (!kIsWeb) {
            await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
            
            final originalFlutterError = FlutterError.onError;
            FlutterError.onError = (errorDetails) {
              FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
              originalFlutterError?.call(errorDetails);
            };

            PlatformDispatcher.instance.onError = (error, stack) {
              FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
              return true;
            };

            Isolate.current.addErrorListener(RawReceivePort((pair) async {
              final List<dynamic> errorAndStacktrace = pair;
              await FirebaseCrashlytics.instance.recordError(
                errorAndStacktrace.first,
                errorAndStacktrace.last,
                fatal: true,
              );
            }).sendPort);

            await logger.setHealthSignal('app_version', container.read(configServiceProvider).appVersion);
            await logger.setHealthSignal('is_debug', kDebugMode);
            
            logger.info('Crashlytics & Analytics hooked into global handlers (including Isolates).', category: 'FIREBASE');
          }

        if (!kIsWeb) {
          logger.info('Initializing Notifications...', category: 'NOTIFICATION');
          try {
            await NotificationService.init(container).timeout(const Duration(seconds: 7));
            await FcmService.init(container).timeout(const Duration(seconds: 7));
          } catch (e) {
            logger.error('Notification system initialization failed', category: 'NOTIFICATION', error: e);
          }
        }

        // Auth is ready AFTER this call — safe to use member/auth providers below
        final auth = FirebaseAuth.instance;
        await container.read(authProvider.notifier).onFirebaseReady(auth);

        // ✅ SAFE: Purge dummy seed members AFTER auth is fully ready
        // Runs only once per device install (guarded by prefs flag), fully non-blocking
        if (kDebugMode) {
          unawaited(Future(() async {
            try {
              final prefs = await SharedPreferences.getInstance();
              if (!(prefs.getBool('seed_purge_done_v1') ?? false)) {
                await SeedData.purgeSeedMembers(container);
                await prefs.setBool('seed_purge_done_v1', true);
                logger.info('Seed member purge complete.', category: 'BOOT');
              }
            } catch (e) {
              logger.warn('Seed purge failed (non-fatal): $e', category: 'BOOT');
            }
          }));
        }
        
      } catch (e, stack) {
        logger.warn('Cloud services initialization failed or timed out: $e', category: 'FIREBASE', error: e, stackTrace: stack);
      }

      // 2. Background Tasks
      if (!kIsWeb && !isTestEnvironment) {
        logger.info('Initializing Workmanager...', category: 'WORKER');
        try {
          await Workmanager().initialize(
            MidnightEngine.callbackDispatcher,
          ).timeout(const Duration(seconds: 5));
          
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
      } else if (isTestEnvironment) {
        logger.info('Skipping Workmanager in test environment.', category: 'WORKER');
      }

      // 3. Start Sync Worker
      if (container.read(firebaseInitializedProvider)) {
        logger.info('Starting Periodic Sync...', category: 'SYNC');
        if (!isTestEnvironment) {
          container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));
        } else {
          logger.info('Skipping Periodic Sync start in test environment.', category: 'SYNC');
        }
        
        container.listen(unsyncedCountProvider, (previous, next) {
          next.whenData((count) {
            logger.setHealthSignal('outbox_size', count);
          });
        });

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
