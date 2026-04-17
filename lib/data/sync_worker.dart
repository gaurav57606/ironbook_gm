import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';

/// Worker responsible for pushing local events to Firestore.
/// Ensures idempotency using eventId as Firestore Document ID.
class SyncWorker {
  final IEventRepository _repo;
  final Future<void> Function(String collection, String id, Map<String, dynamic> data) _recordPusher;
  final String? Function() _currentUserId;
  bool _isSyncing = false;
  int _consecutiveFailures = 0;

  SyncWorker(this._repo, this._recordPusher, this._currentUserId);

  Future<void> performSync() async {
    final uid = _currentUserId();
    if (uid == null) {
      debugPrint('SyncWorker: No authenticated user, skipping sync.');
      return;
    }

    if (_isSyncing) {
      debugPrint('SyncWorker: In-memory sync flag active, skipping...');
      return;
    }

    final holderId = 'foreground_worker';
    if (!await SyncCoordinator.acquireLock(holderId)) {
      debugPrint('SyncWorker: Global sync lock held, skipping push.');
      return;
    }

    _isSyncing = true;
    try {
      final unsynced = await _repo.getAllUnsynced();
      debugPrint('SyncWorker: Found ${unsynced.length} unsynced events for user $uid');
      if (unsynced.isEmpty) {
         _consecutiveFailures = 0; // Reset on "success" (even if empty)
         return;
      }

      debugPrint('SyncWorker: Starting sync for ${unsynced.length} events');

      for (final event in unsynced) {
        debugPrint('SyncWorker: Syncing event ${event.id} (${event.eventType})');
        await _recordPusher('users/$uid/events', event.id, event.toFirestore());
        await _repo.markAsSynced(event.id);
      }
      
      _consecutiveFailures = 0;
      debugPrint('SyncWorker: Sync completed successfully');
    } catch (e) {
      _consecutiveFailures++;
      debugPrint('SyncWorker Error: $e (Failure count: $_consecutiveFailures)');
      rethrow; // Rethrow to allow scheduler to handle backoff
    } finally {
      _isSyncing = false;
      await SyncCoordinator.releaseLock(holderId);
    }
  }

  /// Starts a periodic sync timer with exponential backoff on failure.
  void startPeriodicSync(Duration baseInterval) {
    _scheduleNextSync(baseInterval);
  }

  void _scheduleNextSync(Duration baseInterval) {
    // Audit Check 3.3: Exponential Backoff
    // Next delay = base * 2^failures, capped at 15 minutes.
    int factor = 1 << (_consecutiveFailures.clamp(0, 10)); // max 1024x
    Duration nextDelay = baseInterval * factor;
    if (nextDelay > const Duration(minutes: 15)) {
      nextDelay = const Duration(minutes: 15);
    }

    if (_consecutiveFailures > 0) {
      debugPrint('SyncWorker: Backing off. Next sync in ${nextDelay.inSeconds}s');
    }

    Timer(nextDelay, () async {
      try {
        await performSync();
      } catch (_) {
        // Errors are already handled in performSync and _consecutiveFailures incremented
      }
      _scheduleNextSync(baseInterval);
    });
  }
}

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return SyncWorker(
    repo,
    (coll, id, data) => FirebaseFirestore.instance.collection(coll).doc(id).set(data, SetOptions(merge: true)),
    () => FirebaseAuth.instance.currentUser?.uid,
  );
});

final unsyncedCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 10))
      .asyncMap((_) async {
        final unsynced = await repo.getAllUnsynced();
        return unsynced.length;
      });
});
