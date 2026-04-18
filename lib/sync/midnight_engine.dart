import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/hive_init.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../core/services/notification_service.dart';
import '../core/services/sync_coordinator.dart';
import '../data/sync_worker.dart';
import '../core/utils/clock.dart';
import '../providers/base_providers.dart';

class MidnightEngine {
  /// The entry point for the Workmanager background task.
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      debugPrint("MidnightEngine: Background task '$task' started.");

      try {
        // 1. Initialize core services in the background isolate
        await Firebase.initializeApp();
        await NotificationService.init();
        
        // 2. Open storage and ensure adapters are registered
        HiveInit.registerAdapters();
        final healthy = await HiveInit.openWithCorruptionGuard();
        if (!healthy) {
          debugPrint("MidnightEngine: Hive corruption detected. Aborting background task.");
          return true;
        }

        // 3. Acquire global sync lock to prevent foreground/background conflict
        final container = ProviderContainer();
        final syncCoord = container.read(syncCoordinatorProvider);
        final holderId = 'background_midnight_engine';
        
        if (!await syncCoord.acquireLock(holderId)) {
          debugPrint("MidnightEngine: Lock held by another process. Skipping current run.");
          container.dispose();
          return true; 
        }

        try {
          // 4. Run Maintenance Tasks (Alerts, Cleanups)
          try {
            final clock = container.read(clockProvider);
            await _runMemberAlerts(clock);

            // 5. Run Cloud Sync
            final syncWorker = container.read(syncWorkerProvider);
            await syncWorker.performSync();
          } finally {
            // Container disposed in outer block
          }

          debugPrint("MidnightEngine: All background maintenance completed successfully.");
        } finally {
          await syncCoord.releaseLock(holderId);
          container.dispose();
        }
      } catch (e, stack) {
        debugPrint("MidnightEngine Error: $e\n$stack");
      }
      
      return Future.value(true);
    });
  }

  static Future<void> _runMemberAlerts(IClock clock) async {
    final snapshots = Hive.lazyBox<MemberSnapshot>('snapshots');
    final today = clock.now;
    final todayKey = '${today.year}-${today.month}-${today.day}';

    debugPrint("MidnightEngine: Checking alerts for ${snapshots.length} members.");

    for (final key in snapshots.keys) {
      final snapshot = await snapshots.get(key);
      if (snapshot == null || snapshot.archived) continue;

      final status = snapshot.getStatus(today);
      if (status == MemberStatus.expiring || status == MemberStatus.expired) {
        await NotificationService.sendMemberAlert(
          snapshot: snapshot,
          dedupKey: '${snapshot.memberId}_$todayKey',
          now: today,
        );
      }
    }
  }

  // _runCloudSync merged into main try block for container reuse
}
