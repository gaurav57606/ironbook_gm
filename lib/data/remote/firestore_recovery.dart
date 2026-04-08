import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../local/models/domain_event_model.dart';
import '../local/models/member_snapshot_model.dart';
import '../local/models/join_date_change_model.dart';
import '../../core/services/hmac_service.dart';

class FirestoreRecovery {
  static Future<void> restoreAll({
    required void Function(int done, int total) onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Restore HMAC key
    // Note: getDeviceId should return the same ID used during backup
    final deviceId = user.uid; // Simplified for this logic
    await HmacService.restoreKeyFromFirestore(deviceId);

    // 2. Fetch events
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .orderBy('deviceTimestamp')
        .get();

    final eventsDocs = query.docs;
    final total = eventsDocs.length;

    final eventBox = Hive.box<DomainEvent>('events');
    final snapshotBox = Hive.box<MemberSnapshot>('snapshots');

    // ⚡ Bolt Optimization: Batch database writes using memory maps to reduce disk I/O
    final Map<String, DomainEvent> eventsBatch = {};
    final Map<String, MemberSnapshot> snapshotsBatch = {};

    // 3. Replay
    for (int i = 0; i < total; i++) {
      onProgress(i + 1, total);

      final data = eventsDocs[i].data();
      final event = DomainEvent.fromFirestore(data);

      final isValid = await HmacService.verify(event);
      if (!isValid) {
        debugPrint('HMAC mismatch on event ${event.id} — skipping');
        continue;
      }

      event.synced = true;
      eventsBatch[event.id] = event;

      _applyEventToSnapshotBatch(event, snapshotBox, snapshotsBatch);
    }

    // ⚡ Bolt Optimization: Write batched data to Hive outside the loop
    if (eventsBatch.isNotEmpty) {
      await eventBox.putAll(eventsBatch);
    }
    if (snapshotsBatch.isNotEmpty) {
      await snapshotBox.putAll(snapshotsBatch);
    }
  }

  static void _applyEventToSnapshotBatch(
    DomainEvent event,
    Box<MemberSnapshot> snapshotBox,
    Map<String, MemberSnapshot> snapshotsBatch,
  ) {
    // ⚡ Bolt Optimization: Use .where().firstOrNull instead of .firstWhere() to prevent StateError exceptions
    final type = EventType.values.where((e) => e.name == event.eventType).firstOrNull;
    
    switch (type) {
      case EventType.memberCreated:
        final snap = MemberSnapshot.fromPayload(event.entityId, event.payload);
        snapshotsBatch[event.entityId] = snap;
        break;
      case EventType.paymentAdded:
        final snap = snapshotsBatch[event.entityId] ?? snapshotBox.get(event.entityId);
        if (snap == null) break;
        snap.expiryDate = DateTime.parse(event.payload['newExpiryDate']);
        snap.totalPaid += (event.payload['amount'] as num).toInt();
        snap.paymentIds.add(event.payload['paymentId']);
        snap.lastUpdated = event.deviceTimestamp;
        snapshotsBatch[event.entityId] = snap;
        break;
      case EventType.joinDateEdited:
        final snap = snapshotsBatch[event.entityId] ?? snapshotBox.get(event.entityId);
        if (snap == null) break;
        snap.joinDate = DateTime.parse(event.payload['newDate']);
        snap.joinDateHistory.add(JoinDateChange(
          previousDate: DateTime.parse(event.payload['previousDate']),
          newDate: DateTime.parse(event.payload['newDate']),
          reason: event.payload['reason'],
          changedAt: event.deviceTimestamp,
        ));
        snapshotsBatch[event.entityId] = snap;
        break;
      case EventType.memberArchived:
        final snap = snapshotsBatch[event.entityId] ?? snapshotBox.get(event.entityId);
        if (snap == null) break;
        snap.archived = true;
        snapshotsBatch[event.entityId] = snap;
        break;
      default:
        break;
    }
  }
}
