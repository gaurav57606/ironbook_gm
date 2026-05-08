import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

/// Coordinates synchronization between foreground and background processes.
/// Uses Drift (SQLite) Preferences table as a cross-isolate lock mechanism 
/// and a Stream for foreground triggers.
class SyncCoordinator {
  static const String _lockKey = 'sync_lock';

  final OutboxDatabase _db;
  final _syncRequestController = StreamController<void>.broadcast();

  SyncCoordinator(this._db);

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
    try {
      return await _db.transaction(() async {
        final lock = await (_db.select(_db.preferences)..where((t) => t.key.equals(_lockKey))).getSingleOrNull();

        if (lock != null && lock.value != holderId) {
          debugPrint('SyncCoordinator: Lock already held by ${lock.value}. Rejecting $holderId.');
          return false;
        }

        await _db.into(_db.preferences).insertOnConflictUpdate(
          PreferencesCompanion.insert(
            key: _lockKey, 
            value: holderId,
          ),
        );
        debugPrint('SyncCoordinator: Lock acquired by $holderId.');
        return true;
      });
    } catch (e) {
      debugPrint('SyncCoordinator: Error acquiring lock: $e');
      return false;
    }
  }

  /// Releases the sync lock if held by the specified holder.
  Future<void> releaseLock(String holderId) async {
    try {
      await _db.transaction(() async {
        final lock = await (_db.select(_db.preferences)..where((t) => t.key.equals(_lockKey))).getSingleOrNull();

        if (lock != null && lock.value == holderId) {
          await (_db.delete(_db.preferences)..where((t) => t.key.equals(_lockKey))).go();
          debugPrint('SyncCoordinator: Lock released by $holderId.');
        } else {
          debugPrint('SyncCoordinator: Attempted release by $holderId, but lock belongs to ${lock?.value}.');
        }
      });
    } catch (e) {
      debugPrint('SyncCoordinator: Error releasing lock: $e');
    }
  }

  /// Force releases the lock (e.g., on app startup to clear stale locks).
  Future<void> clearAllLocks() async {
    try {
      await (_db.delete(_db.preferences)..where((t) => t.key.equals(_lockKey))).go();
      debugPrint('SyncCoordinator: All sync locks cleared.');
    } catch (e) {
      debugPrint('SyncCoordinator: Error clearing locks: $e');
    }
  }

  /// Returns true if a lock is currently active.
  Future<bool> isLocked() async {
    final lock = await (_db.select(_db.preferences)..where((t) => t.key.equals(_lockKey))).getSingleOrNull();
    return lock != null;
  }

  void dispose() {
    _syncRequestController.close();
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  final coordinator = SyncCoordinator(db);
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});
