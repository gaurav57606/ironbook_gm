import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/domain_event_model.dart';
import '../core/services/hmac_service.dart';

class SyncEngine {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Box<DomainEvent> _eventBox;

  SyncEngine(this._firestore, this._auth, this._eventBox);

  Future<void> pushPendingEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final unsynced = _eventBox.values
        .where((e) => !e.synced)
        .toList()
      ..sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));

    if (unsynced.isEmpty) return;

    final eventsCollection = _firestore.collection('users').doc(user.uid).collection('events');

    // Process in chunks of 500 for Firestore batch limits
    const chunkSize = 500;
    for (var i = 0; i < unsynced.length; i += chunkSize) {
      final chunk = unsynced.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      final Map<dynamic, DomainEvent> syncedUpdates = {};

      for (final event in chunk) {
        try {
          if (!await HmacService.verify(event)) {
            debugPrint('HMAC mismatch on event ${event.id} — not syncing');
            continue;
          }

          final docRef = eventsCollection.doc(event.id);
          batch.set(docRef, event.toEssentialFirestore());

          syncedUpdates[event.key] = event;
        } catch (e) {
          debugPrint('Sync preparation failed for event ${event.id}: $e');
        }
      }

      if (syncedUpdates.isNotEmpty) {
        try {
          await batch.commit();
          // Only update memory state if commit succeeds
          for (final event in syncedUpdates.values) {
            event.synced = true;
          }
          // Batch update local Hive database to reduce disk I/O
          await _eventBox.putAll(syncedUpdates);
        } catch (e) {
          debugPrint('Batch commit failed: $e');
          // If batch fails, we don't update local synced status
        }
      }
    }
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final box = Hive.box<DomainEvent>('events');
  return SyncEngine(firestore, auth, box);
});

