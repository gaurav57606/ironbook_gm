import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
import 'package:ironbook_gm/core/monitoring/monitoring_service.dart';

const bool isTestEnvironment = bool.fromEnvironment('FLUTTER_TEST');

typedef BootstrapResult = ({bool initialized});

class AppBootstrap {
  static Future<BootstrapResult> initialize(ProviderContainer container) async {
    final logger = container.read(loggerProvider);
    final stopwatch = Stopwatch()..start();
    logger.info('Starting Tier 1 (Native/Local) Initialization...', category: 'BOOT');

    try {
      final result = await _runTier1(container).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // Tier 1 timed out — still schedule Tier 2 so router eventually unblocks
          logger.critical('TIER 1 TIMEOUT: Skipping to Tier 2.', category: 'BOOT');
          container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _scheduleTier2WithFailsafe(container, logger);
          });
          return (initialized: true);
        },
      );

      logger.info('Tier 1 Startup took: ${stopwatch.elapsedMilliseconds}ms', category: 'BOOT');
      return result;
    } catch (e, stack) {
      logger.critical('FATAL TIER 1 FAILURE: $e', category: 'BOOT', error: e, stackTrace: stack);
      // Even on fatal Tier 1 failure, push to degraded so screen unblocks
      container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
      return (initialized: false);
    }
  }

  static Future<BootstrapResult> _runTier1(ProviderContainer container) async {
    final logger = container.read(loggerProvider);

    // Step 1: Config (dotenv load) — fast, no I/O except asset bundle
    logger.info('Initializing ConfigService...', category: 'BOOT');
    try {
      await container.read(configServiceProvider).init().timeout(const Duration(seconds: 3));
    } catch (e) {
      logger.warn('ConfigService init failed (non-fatal): $e', category: 'BOOT');
    }

    // Step 2: System UI — synchronous, no I/O
    _setupSystemUI();

    // Step 3: Drift DB — open file, fast
    logger.info('Opening Drift Outbox Database...', category: 'DB');
    try {
      container.read(outboxDatabaseProvider);
    } catch (e) {
      logger.warn('Drift DB open failed (non-fatal): $e', category: 'DB');
    }

    // NOTE: FlutterSecureStorage (HMAC/installation ID) is intentionally NOT called here.
    // On Android, FlutterSecureStorage.read() can deadlock if the system keystore is
    // not yet available (e.g. first boot, post-wipe). It is initialized lazily in Tier 2
    // after Firebase auth is ready, where it is actually needed.

    container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier1Ready;
    logger.info('Tier 1 Initialization Complete.', category: 'BOOT');

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduleTier2WithFailsafe(container, logger);
    });

    return (initialized: true);
  }

  /// Starts Tier 2 and arms a 20-second failsafe timer.
  /// The failsafe guarantees the router always unblocks even if Tier 2 silently crashes.
  static void _scheduleTier2WithFailsafe(ProviderContainer container, dynamic logger) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      container.read(tier2StatusProvider.notifier).state = Tier2Status.ready;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
      return;
    }
    Timer(const Duration(seconds: 20), () {
      final tier2 = container.read(tier2StatusProvider);
      if (tier2 == Tier2Status.pending) {
        logger.critical(
          'TIER 2 FAILSAFE: Still pending after 20s — forcing degraded mode.',
          category: 'BOOT',
        );
        container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
        container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
      }
    });
    _runTier2(container);
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
      // 0. Pre-auth non-essential tasks
      try {
        await container.read(syncCoordinatorProvider).clearAllLocks().timeout(const Duration(seconds: 2));
      } catch (e) {
        logger.warn('clearAllLocks failed (non-fatal): $e', category: 'BOOT');
      }

      // 1. Firebase
      logger.info('Initializing Firebase...', category: 'FIREBASE');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15));

        container.read(firebaseInitializedProvider.notifier).state = true;
        logger.setFirebaseInitialized(true);
        logger.info('Firebase Initialized (${stopwatch.elapsedMilliseconds}ms).', category: 'FIREBASE');

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
          logger.info('Crashlytics hooked.', category: 'FIREBASE');
        }

        if (!kIsWeb) {
          logger.info('Initializing Notifications...', category: 'NOTIFICATION');
          try {
            await NotificationService.init(container).timeout(const Duration(seconds: 7));
            await FcmService.init(container).timeout(const Duration(seconds: 7));
          } catch (e) {
            logger.error('Notification init failed', category: 'NOTIFICATION', error: e);
          }
        }

        // Auth ready — safe to use HMAC / SecureStorage from here onward
        final auth = FirebaseAuth.instance;
        logger.info('Firebase Auth ready. Restoring session...', category: 'BOOT');
        await container.read(authProvider.notifier).onFirebaseReady(auth).timeout(const Duration(seconds: 10));
        logger.info('Auth session restored.', category: 'BOOT');

        // Seed purge: after auth, fully non-blocking. Runs once per install.
        unawaited(Future(() async {
          try {
            final prefs = await SharedPreferences.getInstance();
            if (!(prefs.getBool('seed_purge_done_v1') ?? false)) {
              await SeedData.purgeSeedMembers(container);
              await prefs.setBool('seed_purge_done_v1', true);
              logger.info('Seed purge complete.', category: 'BOOT');
            }
          } catch (e) {
            logger.warn('Seed purge failed (non-fatal): $e', category: 'BOOT');
          }
        }));

      } catch (e, stack) {
        // Firebase failed — continue to degraded, do NOT rethrow
        logger.warn(
          'Cloud services failed or timed out: $e',
          category: 'FIREBASE',
          error: e,
          stackTrace: stack,
        );
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
              networkType: NetworkType.not_required,
              requiresBatteryNotLow: true,
            ),
          );
          logger.info('Workmanager registered.', category: 'WORKER');
        } catch (e) {
          logger.error('Workmanager init failed: $e', category: 'WORKER', error: e);
        }
      }

      // 3. Monitoring Service
      logger.info('Initializing Monitoring Service (Supabase)...', category: 'MONITOR');
      try {
        // Instantiate the singleton to start the batch timer
        MonitoringService();
        logger.info('Monitoring Service active.', category: 'MONITOR');
      } catch (e) {
        logger.warn('Monitoring Service failed to start (non-fatal): $e', category: 'MONITOR');
      }

      // 4. Finalize Bootstrap & Unblock UI
      if (container.read(firebaseInitializedProvider)) {
        if (!isTestEnvironment) {
          container.read(syncWorkerProvider).startPeriodicSync(const Duration(seconds: 30));
        }

        container.listen(unsyncedCountProvider, (previous, next) {
          next.whenData((count) {
            logger.setHealthSignal('outbox_size', count);
          });
        });

        logger.info('Tier 2 unblocking UI...', category: 'BOOT');
        container.read(tier2StatusProvider.notifier).state = Tier2Status.ready;
        container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Ready;
        
        // 4. DECOUPLED: Trigger recovery AFTER navigation is unblocked
        logger.info('Triggering background data recovery...', category: 'BOOT');
        container.read(authProvider.notifier).triggerBackgroundRecovery();
      } else {
        logger.warn('Degraded Mode: No Firebase. Arming connectivity retry.', category: 'BOOT');
        container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
        container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;

        // ── OFFLINE RECOVERY LISTENER ────────────────────────────────────────────
        // Arms a one-shot retry: when connectivity is restored after an offline
        // startup, automatically re-attempt Tier 2 so Firebase and sync resume.
        StreamSubscription<List<ConnectivityResult>>? offlineRetrySub;
        offlineRetrySub = Connectivity().onConnectivityChanged.listen((results) async {
          final isOnline = results.any((r) => r != ConnectivityResult.none);
          if (!isOnline) return;
          // Only retry if still degraded — another path may have already recovered
          if (container.read(tier2StatusProvider) != Tier2Status.degraded) {
            offlineRetrySub?.cancel();
            return;
          }
          logger.info(
            'Connectivity restored in degraded mode. Retrying Tier 2...',
            category: 'BOOT',
          );
          offlineRetrySub?.cancel();
          await _runTier2(container);
        });
      }

      logger.info('Tier 2 Initialization Complete (${stopwatch.elapsedMilliseconds}ms).', category: 'BOOT');

    } catch (e, stack) {
      // Last-resort — always unblock router
      logger.critical('CRITICAL TIER 2 FAILURE: $e', category: 'BOOT', error: e, stackTrace: stack);
      container.read(tier2StatusProvider.notifier).state = Tier2Status.degraded;
      container.read(bootstrapStateProvider.notifier).state = BootstrapPhase.tier2Degraded;
    }
  }
}
