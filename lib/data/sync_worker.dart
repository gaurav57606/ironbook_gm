import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local/drift/outbox_repository.dart';
import 'repositories/event_repository.dart';
import '../core/services/sync_coordinator.dart';
import '../providers/base_providers.dart';

enum SyncStatus { idle, syncing, failed }

class SyncState {
  final SyncStatus status;
  final DateTime? lastErrorAt;
  final DateTime? lastSuccessAt;
  final String? errorMessage;

  SyncState({required this.status, this.lastErrorAt, this.lastSuccessAt, this.errorMessage});
}

/// Worker responsible for pushing local events to Firestore.
/// Ensures idempotency using eventId as Firestore Document ID.
class SyncWorker {
  final IEventRepository _repo;
  final OutboxRepository _outboxRepo;
  final SyncCoordinator _coordinator;
  final Future<void> Function(String collection, String id, Map<String, dynamic> data) _recordPusher;
  final String? Function() _currentUserId;
  bool _isSyncing = false;
  int _consecutiveFailures = 0;
  DateTime? _lastErrorAt;
  DateTime? _lastSuccessAt;
  String? _lastErrorMessage;
  StreamSubscription? _syncSubscription;
  final StateProvider<SyncState> _statusProvider;
  final Ref _ref;

  SyncWorker(this._repo, this._outboxRepo, this._coordinator, this._recordPusher, this._currentUserId, this._statusProvider, this._ref) {
    // Subscribe to manual sync requests from the UI or Repositories
    _syncSubscription = _coordinator.onSyncRequested.listen((_) => performSync());
  }

  void dispose() {
    _syncSubscription?.cancel();
  }

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
    if (!await _coordinator.acquireLock(holderId)) {
      debugPrint('SyncWorker: Global sync lock held, skipping push.');
      return;
    }

    _isSyncing = true;
    _ref.read(_statusProvider.notifier).state = SyncState(status: SyncStatus.syncing);

    try {
      final unsynced = await _outboxRepo.getUnsyncedEvents();
      debugPrint('SyncWorker: Found ${unsynced.length} unsynced events in Drift Outbox for user $uid');
      if (unsynced.isEmpty) {
         _consecutiveFailures = 0; // Reset on "success" (even if empty)
         return;
      }

      debugPrint('SyncWorker: Starting sync for ${unsynced.length} events');

      for (final event in unsynced) {
        debugPrint('SyncWorker: Syncing event ${event.id} (${event.eventType})');
        await _recordPusher('users/$uid/events', event.id, event.toFirestore());
        await _repo.markAsSynced(event.id);
        await _outboxRepo.markSynced(event.id); // Also sync in Drift
      }
      
      _consecutiveFailures = 0;
      debugPrint('SyncWorker: Sync completed successfully');
    } catch (e) {
      _consecutiveFailures++;
      _lastErrorAt = DateTime.now();
      _lastErrorMessage = e.toString();
      debugPrint('SyncWorker Error: $e (Failure count: $_consecutiveFailures)');
      rethrow; // Rethrow to allow scheduler to handle backoff
    } finally {
      _isSyncing = false;
      
      if (_consecutiveFailures == 0) {
        _setSyncState(SyncStatus.idle);
      } else {
        _setSyncState(SyncStatus.failed, error: _lastErrorMessage);
      }
      
      await _coordinator.releaseLock(holderId);
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

final syncStatusProvider = StateProvider<SyncState>((ref) => SyncState(status: SyncStatus.idle));

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  final outboxRepo = ref.watch(outboxRepositoryProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);
  
  final worker = SyncWorker(
    repo,
    outboxRepo,
    coordinator,
    (coll, id, data) => FirebaseFirestore.instance.collection(coll).doc(id).set(data, SetOptions(merge: true)),
    () => FirebaseAuth.instance.currentUser?.uid,
    syncStatusProvider,
    ref,
  );

  ref.onDispose(() => worker.dispose());
  return worker;
});

final unsyncedCountProvider = StreamProvider<int>((ref) {
  final outboxRepo = ref.watch(outboxRepositoryProvider);
  return outboxRepo.watchUnsyncedCount();
});
