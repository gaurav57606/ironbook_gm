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

    for (final event in unsynced) {
      try {
        if (!await HmacService.verify(event)) {
          debugPrint('HMAC mismatch on event ${event.id} — not syncing');
          continue;
        }

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('events')
            .doc(event.id)
            .set(event.toEssentialFirestore());

        event.synced = true;
        await event.save();
      } catch (e) {
        debugPrint('Sync failed for event ${event.id}: $e');
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

