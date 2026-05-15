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

import 'package:ironbook_gm/core/services/notification_service.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';

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
      // 0. Provisioning Guard: Ensure cloud key exists before pushing events signed with it.
      final hmac = _ref.read(hmacServiceProvider);
      final isKeyProvisioned = await hmac.verifyCloudKeyPresence();
      if (!isKeyProvisioned) {
        _ref.read(loggerProvider).warn('Device key not found in cloud. Attempting provisioning...', category: 'SYNC');
        try {
          await hmac.syncCurrentKeyToCloud();
          _ref.read(loggerProvider).info('Cloud key provisioned successfully.', category: 'SYNC');
        } catch (provisionError) {
          _ref.read(loggerProvider).error('Cloud key provisioning failed. Blocking sync.', category: 'SYNC', error: provisionError);
          rethrow; // This will trigger the catch block below and handle lock release
        }
      }
      final unsyncedEvents = await _outboxRepo.getUnsyncedEvents();
      final memberRepo = _ref.read(memberRepositoryProvider);
      final unsyncedSnapshots = await memberRepo.getUnsyncedMembers();

      if (unsyncedEvents.isEmpty && unsyncedSnapshots.isEmpty) {
         _ref.read(loggerProvider).info('Nothing to sync (Events: 0, Snapshots: 0).', category: 'SYNC');
         _consecutiveFailures = 0; 
         await _prefs.setInt('sync_consecutive_failures', 0);
         return;
      }

      if (unsyncedEvents.isNotEmpty) {
        _ref.read(loggerProvider).info('Starting batch sync for ${unsyncedEvents.length} events', category: 'SYNC');

        // Audit Check: Use Firestore WriteBatch for atomic, high-throughput sync
        // Process in chunks of 50 (Firestore limit)
        for (var i = 0; i < unsyncedEvents.length; i += 50) {
          final chunk = unsyncedEvents.skip(i).take(50).toList();
          _ref.read(loggerProvider).debug('Processing sync chunk: ${chunk.length} items', category: 'SYNC');
          
          try {
            if (!const bool.fromEnvironment('FLUTTER_TEST')) {
              final batch = FirebaseFirestore.instance.batch();
              for (final event in chunk) {
                final docRef = FirebaseFirestore.instance.collection('users/$uid/events').doc(event.id);
                batch.set(docRef, event.toFirestore());
              }
              await batch.commit().timeout(const Duration(seconds: 30));
            } else {
              // In tests, we still use the recordPusher for compatibility with mocks
              for (final event in chunk) {
                await _recordPusher('users/$uid/events', event.id, event.toFirestore())
                    .timeout(const Duration(seconds: 15));
              }
            }
            
            await _outboxRepo.markBatchSynced(chunk.map((e) => e.id).toList());
            _ref.read(loggerProvider).debug('Successfully synced chunk of ${chunk.length} items', category: 'SYNC');
          } catch (chunkError) {
            _ref.read(loggerProvider).error(
              'Failed to sync chunk starting at index $i', 
              category: 'SYNC', 
              error: chunkError
            );
            
            // Operational Resilience: Fallback to individual sync for this chunk to identify problematic items
            _ref.read(loggerProvider).info('Falling back to individual sync for problematic chunk...', category: 'SYNC');
            for (final event in chunk) {
              try {
                await _recordPusher('users/$uid/events', event.id, event.toFirestore())
                    .timeout(const Duration(seconds: 15));
                await _outboxRepo.markSynced(event.id);
              } catch (itemError) {
                _ref.read(loggerProvider).error('Individual sync failure for event ${event.id}', category: 'SYNC', error: itemError);
                final errorStr = itemError.toString().toLowerCase();
                if (errorStr.contains('network') || errorStr.contains('unavailable') || errorStr.contains('deadline')) {
                  rethrow;
                }
              }
            }
          }
        }
      }
      
      _consecutiveFailures = 0;
      await _prefs.setInt('sync_consecutive_failures', 0);
      _lastSuccessAt = DateTime.now();
      
      // Update global sync health in preferences (Drift-backed)
      await _ref.read(preferencesRepositoryProvider).setString(
        'last_successful_sync_at', 
        _lastSuccessAt!.toIso8601String()
      );

      _ref.read(loggerProvider).info('Sync batch completed successfully', category: 'SYNC');
      
      // 3. Snapshot Projection Layer: Sync current state of affected entities
      await _syncSnapshots(uid);

      _ref.read(loggerProvider).setHealthSignal('last_sync_success', _lastSuccessAt!.toIso8601String());
      _ref.read(loggerProvider).setHealthSignal('sync_status', 'healthy');
    } catch (e, stack) {
      _consecutiveFailures++;
      await _prefs.setInt('sync_consecutive_failures', _consecutiveFailures);
      _lastErrorAt = DateTime.now();
      
      // Categorize error for better observability
      String category = 'SYNC_UNKNOWN';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') category = 'SYNC_AUTH';
        if (e.code == 'unavailable' || e.code == 'network-request-failed') category = 'SYNC_NETWORK';
      } else if (e is TimeoutException) {
        category = 'SYNC_TIMEOUT';
      }

      _lastErrorMessage = '[$category] ${e.toString()}';
      _ref.read(loggerProvider).error(
        'Sync failure ($_consecutiveFailures consecutive)', 
        category: category, 
        error: e, 
        stackTrace: stack
      );
      
      _ref.read(loggerProvider).setHealthSignal('last_sync_error', _lastErrorAt!.toIso8601String());
      _ref.read(loggerProvider).setHealthSignal('sync_status', 'failed_$_consecutiveFailures');
      
      // Trigger notification on persistent failure
      if (_consecutiveFailures >= 3) {
        NotificationService.sendSyncAlert(error: _lastErrorMessage!);
      }

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

  Future<void> _syncSnapshots(String uid) async {
    final memberRepo = _ref.read(memberRepositoryProvider);
    final logger = _ref.read(loggerProvider);
    
    try {
      final unsynced = await memberRepo.getUnsyncedMembers();
      if (unsynced.isEmpty) {
        logger.debug('No unsynced snapshots found.', category: 'SYNC');
        return;
      }

      logger.info('SYNC: Snapshot push started for ${unsynced.length} members...', category: 'SYNC');
      
      final hmac = _ref.read(hmacServiceProvider);
      var batch = FirebaseFirestore.instance.batch();
      int count = 0;
      final List<String> syncedIds = [];

      for (final member in unsynced) {
        logger.debug('SYNC: Preparing snapshot for ${member.memberId} (${member.name})', category: 'SYNC');
        
        // Ensure signed
        String signature = member.hmacSignature ?? '';
        if (signature.isEmpty) {
          logger.debug('SYNC: Generating missing HMAC for ${member.memberId}', category: 'SYNC');
          signature = await hmac.signSnapshot(member.memberId, member.toFirestore());
        }
        final signedMember = member.copyWith(hmacSignature: signature);

        if (!const bool.fromEnvironment('FLUTTER_TEST')) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('snapshots')
              .doc('members')
              .collection('items')
              .doc(member.memberId);
          
          final payload = signedMember.toFirestore();
          logger.debug('SYNC: Adding to batch: users/$uid/snapshots/members/items/${member.memberId} (Size: ${payload.toString().length} chars)', category: 'SYNC');
          
          batch.set(docRef, payload);
        } else {
          // In tests, we use the recordPusher
          await _recordPusher('users/$uid/snapshots/members/items', member.memberId, signedMember.toFirestore());
        }
        syncedIds.add(member.memberId);
        count++;
        
        // Process in chunks of 100 (more conservative than 500 for snapshots which are larger)
        if (count >= 100) {
          if (!const bool.fromEnvironment('FLUTTER_TEST')) {
            logger.info('SYNC: Committing batch of $count snapshots...', category: 'SYNC');
            await batch.commit();
            logger.info('SYNC: Batch commit successful.', category: 'SYNC');
          }
          
          // Post-Upload Verification
          for (final id in syncedIds) {
            await memberRepo.markSynced(id);
          }
          
          if (!const bool.fromEnvironment('FLUTTER_TEST')) {
            // Sample check for the last ID in this batch
            final lastId = syncedIds.last;
            final verifyDoc = await FirebaseFirestore.instance
                .collection('users/$uid/snapshots/members/items')
                .doc(lastId).get();
            
            if (verifyDoc.exists) {
              logger.info('SYNC: Verification successful for $lastId', category: 'SYNC');
            } else {
              logger.error('SYNC: Verification FAILED for $lastId after commit!', category: 'SYNC');
            }
          }

          batch = FirebaseFirestore.instance.batch();
          syncedIds.clear();
          count = 0;
        }
      }

      if (count > 0) {
        if (!const bool.fromEnvironment('FLUTTER_TEST')) {
          logger.info('SYNC: Committing final batch of $count snapshots...', category: 'SYNC');
          await batch.commit();
          logger.info('SYNC: Final batch commit successful.', category: 'SYNC');
          
          // Sample check for the last ID
          final lastId = syncedIds.last;
          final verifyDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('snapshots')
              .doc('members')
              .collection('items')
              .doc(lastId).get();
          
          if (verifyDoc.exists) {
            logger.info('SYNC: Final verification successful for $lastId', category: 'SYNC');
          } else {
            logger.error('SYNC: Final verification FAILED for $lastId after commit!', category: 'SYNC');
          }
        }

        for (final id in syncedIds) {
          await memberRepo.markSynced(id);
        }
      }
      
      logger.info('Successfully projected ${unsynced.length} snapshots to cloud.', category: 'SYNC');
    } catch (e) {
      logger.error('Failed to sync snapshots', category: 'SYNC', error: e);
      // We don't rethrow here because event sync already succeeded
    }
  }

  /// Starts a periodic sync timer with exponential backoff on failure.
  void startPeriodicSync(Duration baseInterval) {
    if (const bool.fromEnvironment('FLUTTER_TEST')) return;
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

final syncHealthProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(preferencesRepositoryProvider);
  final lastSyncStr = await prefs.getString('last_successful_sync_at');
  if (lastSyncStr == null) return true; // Never synced yet, assume okay or pending

  try {
    final lastSync = DateTime.parse(lastSyncStr);
    final diff = DateTime.now().difference(lastSync);
    return diff.inDays < 7;
  } catch (_) {
    return true;
  }
});











