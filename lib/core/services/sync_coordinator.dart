import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinates synchronization between foreground and background processes.
/// Uses Hive as a cross-isolate lock mechanism and a Stream for foreground triggers.
class SyncCoordinator {
  static const String _boxName = 'sync_metadata';
  static const String _lockKey = 'sync_lock';

  final _syncRequestController = StreamController<void>.broadcast();

  /// Stream that emits when a synchronization is requested.
  Stream<void> get onSyncRequested => _syncRequestController.stream;

  /// Triggers a synchronization attempt in the foreground.
  void triggerSync() {
    debugPrint('SyncCoordinator: Sync triggered.');
    _syncRequestController.add(null);
  }

  /// Attempts to acquire the sync lock.
  /// Returns true if lock was acquired, false if already locked.
  Future<bool> acquireLock(String holderId) async {
    final box = await Hive.openBox(_boxName);
    final currentHolder = box.get(_lockKey);

    if (currentHolder != null && currentHolder != holderId) {
      debugPrint('SyncCoordinator: Lock already held by $currentHolder. Rejecting $holderId.');
      return false;
    }

    await box.put(_lockKey, holderId);
    debugPrint('SyncCoordinator: Lock acquired by $holderId.');
    return true;
  }

  /// Releases the sync lock if held by the specified holder.
  Future<void> releaseLock(String holderId) async {
    final box = await Hive.openBox(_boxName);
    final currentHolder = box.get(_lockKey);

    if (currentHolder == holderId) {
      await box.delete(_lockKey);
      debugPrint('SyncCoordinator: Lock released by $holderId.');
    } else {
      debugPrint('SyncCoordinator: Attempted release by $holderId, but lock belongs to $currentHolder.');
    }
  }

  /// Force releases the lock (e.g., on app startup to clear stale locks).
  Future<void> clearAllLocks() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
    debugPrint('SyncCoordinator: All sync locks cleared.');
  }

  /// Returns true if a lock is currently active.
  Future<bool> isLocked() async {
    final box = await Hive.openBox(_boxName);
    return box.containsKey(_lockKey);
  }

  void dispose() {
    _syncRequestController.close();
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator();
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});
