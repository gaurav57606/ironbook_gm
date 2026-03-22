import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/local/models/domain_event_model.dart';
import '../core/services/hmac_service.dart';

class SyncEngine {
  static Future<void> pushPendingEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final eventBox = Hive.box<DomainEvent>('events');
    final unsynced = eventBox.values
        .where((e) => !e.synced)
        .toList()
      ..sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));

    for (final event in unsynced) {
      try {
        if (!await HmacService.verify(event)) {
          debugPrint('HMAC mismatch on event ${event.id} — not syncing');
          continue;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('events')
            .doc(event.id)
            .set(event.toFirestore());

        event.synced = true;
        await event.save();
      } catch (e) {
        debugPrint('Sync failed for event ${event.id}: $e');
      }
    }
  }
}
