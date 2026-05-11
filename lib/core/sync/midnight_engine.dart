import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ironbook_gm/firebase_options.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/services/notification_service.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';

class MidnightEngine {
  /// The entry point for the Workmanager background task.
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      // 1. Initialize core binding for the background isolate
      WidgetsFlutterBinding.ensureInitialized();
      
      try {
        // 2. Initialize critical local services
        final prefs = await SharedPreferences.getInstance();
        
        // 3. Attempt Firebase init with options (Required for Release Mode)
        bool firebaseReady = false;
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 15));
          
          if (!kDebugMode) {
            await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
          }
          firebaseReady = true;
        } catch (e) {
          // If logger isn't ready yet, we use debugPrint for boot failures
          if (kDebugMode) debugPrint("[WORKER] Firebase init failed/timed out in background: $e");
        }

        // 4. Setup Container with necessary overrides
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firebaseInitializedProvider.overrideWith((ref) => firebaseReady),
          ],
        );
        
        final logger = container.read(loggerProvider);
        if (firebaseReady) logger.setFirebaseInitialized(true);
        
        logger.info("[WORKER] Background task '$task' started.", category: 'BOOT');

        final syncCoord = container.read(syncCoordinatorProvider);
        const holderId = 'background_midnight_engine';
        
        if (!await syncCoord.acquireLock(holderId)) {
          logger.info("[WORKER] Lock held by another process. Skipping current run.", category: 'SYNC');
          container.dispose();
          return true; 
        }

        try {
          logger.info("[WORKER] Lock acquired. Starting tasks.", category: 'SYNC');
          // 5. Run Maintenance Tasks (Alerts, Cleanups)
          await _runMemberAlerts(container);

          // 6. Run Cloud Sync
          if (firebaseReady) {
            final syncWorker = container.read(syncWorkerProvider);
            logger.info("[WORKER] Starting Cloud Sync...", category: 'SYNC');
            await syncWorker.performSync();
            logger.info("[WORKER] Cloud Sync completed.", category: 'SYNC');
          } else {
            logger.warn("[WORKER] Skipping Cloud Sync: Firebase not ready.", category: 'SYNC');
          }

          logger.info("[WORKER] All background maintenance completed successfully.", category: 'BOOT');
        } finally {
          await syncCoord.releaseLock(holderId);
          logger.info("[WORKER] Lock released. Isolate shutting down.", category: 'SYNC');
          container.dispose();
        }
      } catch (e, stack) {
        // Use debugPrint if container/logger failed to initialize
        if (kDebugMode) debugPrint("[WORKER] Fatal Error: $e\n$stack");
        try {
           FirebaseCrashlytics.instance.recordError(e, stack, reason: 'MidnightEngine Fatal Background Failure');
        } catch (_) {}
      }
      
      return Future.value(true);
    });
  }

  static Future<void> _runMemberAlerts(ProviderContainer container) async {
    final memberRepo = container.read(memberRepositoryProvider);
    final clock = container.read(clockProvider);
    final today = clock.now;
    final todayKey = '${today.year}-${today.month}-${today.day}';

    final members = await memberRepo.getAllMembers();
    container.read(loggerProvider).info("Checking alerts for ${members.length} members.", category: 'SYNC');

    for (final member in members) {
      if (member.archived) continue;

      final status = member.getStatus(today);
      if (status == MemberStatus.expiring || status == MemberStatus.expired) {
        await NotificationService.sendMemberAlert(
          snapshot: member,
          dedupKey: '${member.memberId}_$todayKey',
          now: today,
        );
      }
    }
  }
}
