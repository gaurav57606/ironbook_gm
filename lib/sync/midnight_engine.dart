import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../data/local/hive_init.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../core/services/notification_service.dart';
import 'sync_engine.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'midnightTask') {
      await runMidnightTask();
    }
    return Future.value(true);
  });
}

Future<void> runMidnightTask() async {
  await Hive.initFlutter();
  final healthy = await HiveInit.openWithCorruptionGuard();
  if (!healthy) return;

  final snapshots = Hive.box<MemberSnapshot>('snapshots');
  final today = DateTime.now();
  final todayKey = '${today.year}-${today.month}-${today.day}';

  for (final snapshot in snapshots.values) {
    if (snapshot.archived) continue;

    final status = snapshot.status;
    if (status == MemberStatus.expiring || status == MemberStatus.expired) {
      await NotificationService.sendMemberAlert(
        snapshot: snapshot,
        dedupKey: '${snapshot.memberId}_$todayKey',
      );
    }
  }

  await SyncEngine.pushPendingEvents();
}
