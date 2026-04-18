import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sync_worker.dart';

class SyncStatus {
  final int unsyncedCount;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  SyncStatus({
    required this.unsyncedCount,
    this.isSyncing = false,
    this.lastSyncTime,
  });

  SyncStatus copyWith({
    int? unsyncedCount,
    bool? isSyncing,
    DateTime? lastSyncTime,
  }) {
    return SyncStatus(
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

// Note: This can be expanded to link with SyncWorker states if SyncWorker is converted to a StateNotifier/AsyncNotifier.
// For now, it simple provides a reactive view of the unsynced count.
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final count = ref.watch(unsyncedCountProvider).value ?? 0;
  return SyncStatus(unsyncedCount: count);
});
