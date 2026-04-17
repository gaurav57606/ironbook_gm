import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Coordinates synchronization between foreground and background processes.
/// Uses Hive as a cross-isolate lock mechanism.
class SyncCoordinator {
  static const String _boxName = 'sync_metadata';
  static const String _lockKey = 'sync_lock';

  /// Attempts to acquire the sync lock.
  /// Returns true if lock was acquired, false if already locked.
  static Future<bool> acquireLock(String holderId) async {
    final box = await Hive.openBox(_boxName);
    final currentHolder = box.get(_lockKey);

    if (currentHolder != null) {
      debugPrint('SyncCoordinator: Lock already held by $currentHolder. Rejecting $holderId.');
      return false;
    }

    await box.put(_lockKey, holderId);
    debugPrint('SyncCoordinator: Lock acquired by $holderId.');
    return true;
  }

  /// Releases the sync lock if held by the specified holder.
  static Future<void> releaseLock(String holderId) async {
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
  static Future<void> clearAllLocks() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
    debugPrint('SyncCoordinator: All sync locks cleared.');
  }

  /// Returns true if a lock is currently active.
  static Future<bool> isLocked() async {
    final box = await Hive.openBox(_boxName);
    return box.containsKey(_lockKey);
  }
}
