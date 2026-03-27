import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';

/// Worker responsible for pushing local events to Firestore.
/// Ensures idempotency using eventId as Firestore Document ID.
class SyncWorker {
  final IEventRepository _repo;
  final Future<void> Function(String collection, String id, Map<String, dynamic> data) _recordPusher;
  final String? Function() _currentUserId;
  bool _isSyncing = false;

  SyncWorker(this._repo, this._recordPusher, this._currentUserId);

  Future<void> sync() async {
    if (_isSyncing) {
      debugPrint('SyncWorker: already syncing, skipping...');
      return;
    }
    final userId = _currentUserId();
    if (userId == null) {
      debugPrint('SyncWorker: userId is null, skipping sync');
      return;
    }

    _isSyncing = true;
    try {
      final unsynced = _repo.getAllUnsynced();
      debugPrint('SyncWorker: Found ${unsynced.length} unsynced events for user $userId');
      if (unsynced.isEmpty) return;

      debugPrint('SyncWorker: Starting sync for ${unsynced.length} events');

      for (final event in unsynced) {
        debugPrint('SyncWorker: Syncing event ${event.id} (${event.eventType})');
        // Push individually for now or use a batch abstraction if needed. 
        // For idempotency, the key is the event.id
        await _recordPusher('users/$userId/events', event.id, event.toFirestore());
        await _repo.markAsSynced(event.id);
      }
      
      debugPrint('SyncWorker: Sync completed successfully');
    } catch (e) {
      debugPrint('SyncWorker Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Starts a periodic sync timer.
  void startPeriodicSync(Duration interval) {
    Timer.periodic(interval, (_) => sync());
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
