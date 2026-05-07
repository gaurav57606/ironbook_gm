import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      debugPrint("MidnightEngine: Background task '$task' started.");

      try {
        // 1. Initialize core services in the background isolate
        await Firebase.initializeApp();
        await NotificationService.init();
        
        // Note: Drift initializes lazily when the database is accessed.

        // 2. Acquire global sync lock to prevent foreground/background conflict
        final container = ProviderContainer();
        final syncCoord = container.read(syncCoordinatorProvider);
        const holderId = 'background_midnight_engine';
        
        if (!await syncCoord.acquireLock(holderId)) {
          debugPrint("MidnightEngine: Lock held by another process. Skipping current run.");
          container.dispose();
          return true; 
        }

        try {
          // 3. Run Maintenance Tasks (Alerts, Cleanups)
          await _runMemberAlerts(container);

          // 4. Run Cloud Sync
          final syncWorker = container.read(syncWorkerProvider);
          await syncWorker.performSync();

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

  static Future<void> _runMemberAlerts(ProviderContainer container) async {
    final memberRepo = container.read(memberRepositoryProvider);
    final clock = container.read(clockProvider);
    final today = clock.now;
    final todayKey = '${today.year}-${today.month}-${today.day}';

    final members = await memberRepo.getAllMembers();
    debugPrint("MidnightEngine: Checking alerts for ${members.length} members.");

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
