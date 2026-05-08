import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local/drift/outbox_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import '../services/logger_service.dart';

enum SyncWorkerStatus { idle, syncing, failed }

class SyncWorkerState {
  final SyncWorkerStatus status;
  final DateTime? lastErrorAt;
  final DateTime? lastSuccessAt;
  final String? errorMessage;

  SyncWorkerState({required this.status, this.lastErrorAt, this.lastSuccessAt, this.errorMessage});
}

/// Worker responsible for pushing local events to Firestore.
/// Ensures idempotency using eventId as Firestore Document ID.
class SyncWorker {
  final OutboxRepository _outboxRepo;
  final SyncCoordinator _coordinator;
  final SharedPreferences _prefs;
  final Future<void> Function(String collection, String id, Map<String, dynamic> data) _recordPusher;
  final String? Function() _currentUserId;
  bool _isSyncing = false;
  int _consecutiveFailures = 0;
  DateTime? _lastErrorAt;
  DateTime? _lastSuccessAt;
  String? _lastErrorMessage;
  StreamSubscription? _syncSubscription;
  final StateProvider<SyncWorkerState> _statusProvider;
  final Ref _ref;

  SyncWorker(this._outboxRepo, this._coordinator, this._prefs, this._recordPusher, this._currentUserId, this._statusProvider, this._ref) {
    // Subscribe to manual sync requests from the UI or Repositories
    _syncSubscription = _coordinator.onSyncRequested.listen((_) => performSync());
    
    // Load persisted failure count
    _consecutiveFailures = _prefs.getInt('sync_consecutive_failures') ?? 0;
  }

  void dispose() {
    _syncSubscription?.cancel();
  }

  Future<void> performSync() async {
    final uid = _currentUserId();
    if (uid == null) {
      _ref.read(loggerProvider).info('No authenticated user, skipping sync.', category: 'SYNC');
      return;
    }

    if (_isSyncing) {
      _ref.read(loggerProvider).info('In-memory sync flag active, skipping...', category: 'SYNC');
      return;
    }

    const holderId = 'foreground_worker';
    if (!await _coordinator.acquireLock(holderId)) {
      _ref.read(loggerProvider).info('Global sync lock held, skipping push.', category: 'SYNC');
      return;
    }

    // Connectivity guard: prevent unneeded attempts while offline
    final connectivity = await _checkConnectivity();
    if (!connectivity) {
      _ref.read(loggerProvider).info('Device offline, skipping sync.', category: 'SYNC');
      await _coordinator.releaseLock(holderId);
      return;
    }

    _isSyncing = true;
    _ref.read(_statusProvider.notifier).state = SyncWorkerState(status: SyncWorkerStatus.syncing);

    try {
      final unsynced = await _outboxRepo.getUnsyncedEvents();
      if (unsynced.isEmpty) {
         _ref.read(loggerProvider).info('Outbox empty, nothing to sync.', category: 'SYNC');
         _consecutiveFailures = 0; 
         await _prefs.setInt('sync_consecutive_failures', 0);
         return;
      }

      _ref.read(loggerProvider).info('Starting sync for ${unsynced.length} events', category: 'SYNC');

      for (final event in unsynced) {
        _ref.read(loggerProvider).debug('Syncing event ${event.id} (${event.eventType})', category: 'SYNC');
        try {
          await _recordPusher('users/$uid/events', event.id, event.toFirestore());
          await _outboxRepo.markSynced(event.id); // Mark synced in Drift
        } catch (itemError) {
          _ref.read(loggerProvider).error('Failed to sync individual event ${event.id}', category: 'SYNC', error: itemError);
          // Continue with next event if one fails, unless it's a network error
          if (itemError.toString().contains('network')) rethrow;
        }
      }
      
      _consecutiveFailures = 0;
      await _prefs.setInt('sync_consecutive_failures', 0);
      _lastSuccessAt = DateTime.now();
      _ref.read(loggerProvider).info('Sync batch completed successfully', category: 'SYNC');
    } catch (e, stack) {
      _consecutiveFailures++;
      await _prefs.setInt('sync_consecutive_failures', _consecutiveFailures);
      _lastErrorAt = DateTime.now();
      _lastErrorMessage = e.toString();
      _ref.read(loggerProvider).error('Sync batch failure (Attempt $_consecutiveFailures)', category: 'SYNC', error: e, stackTrace: stack);
      rethrow; // Rethrow to allow scheduler to handle backoff
    } finally {
      _isSyncing = false;
      
      if (_consecutiveFailures == 0) {
        _setSyncState(SyncWorkerStatus.idle);
      } else {
        _setSyncState(SyncWorkerStatus.failed, error: _lastErrorMessage);
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
      _ref.read(loggerProvider).info('Sync backoff: retry in ${nextDelay.inSeconds}s', category: 'SYNC');
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

  void _setSyncState(SyncWorkerStatus status, {String? error}) {
    _ref.read(_statusProvider.notifier).state = SyncWorkerState(
      status: status,
      lastErrorAt: _lastErrorAt,
      lastSuccessAt: _lastSuccessAt,
      errorMessage: error,
    );
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);
      if (!hasConnection) {
        _ref.read(loggerProvider).warn('Connectivity check: Offline', category: 'SYNC');
      }
      return hasConnection;
    } catch (e) {
      _ref.read(loggerProvider).error('Connectivity check failed', category: 'SYNC', error: e);
      return false; // Assume offline if check fails
    }
  }
}

final syncWorkerStatusProvider = StateProvider<SyncWorkerState>((ref) => SyncWorkerState(status: SyncWorkerStatus.idle));

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final outboxRepo = ref.watch(outboxRepositoryProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final logger = ref.watch(loggerProvider);
  
  final worker = SyncWorker(
    outboxRepo,
    coordinator,
    prefs,
    (coll, id, data) async {
      if (!ref.read(firebaseInitializedProvider)) {
        logger.warn('Skipping record push: Firebase not initialized.', category: 'SYNC');
        return;
      }
      logger.debug('Pushing to $coll/$id', category: 'FIREBASE');
      final dbRef = FirebaseFirestore.instance.collection(coll).doc(id);
      final existing = await dbRef.get();
      if (!existing.exists) {
        await dbRef.set(data);
        logger.debug('Successfully pushed $id', category: 'FIREBASE');
      } else {
        logger.debug('Document $id already exists, skipping.', category: 'FIREBASE');
      }
    },
    () {
      if (!ref.read(firebaseInitializedProvider)) return null;
      return FirebaseAuth.instance.currentUser?.uid;
    },
    syncWorkerStatusProvider,
    ref,
  );

  ref.onDispose(() => worker.dispose());
  return worker;
});

final unsyncedCountProvider = StreamProvider<int>((ref) {
  final outboxRepo = ref.watch(outboxRepositoryProvider);
  return outboxRepo.watchUnsyncedCount();
});











