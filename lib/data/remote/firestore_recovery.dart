import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../local/models/domain_event_model.dart';
import '../local/models/member_snapshot_model.dart';
import '../local/models/join_date_change_model.dart';
import '../../core/services/hmac_service.dart';
import '../../constants/event_payload_keys.dart';

class FirestoreRecovery {
  static Future<void> restoreAll({
    required HmacService hmacService,
    required void Function(int done, int total) onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Restore HMAC key
    // Note: getDeviceId should return the same ID used during backup
    final deviceId = user.uid; // Simplified for this logic
    await hmacService.restoreKeyFromFirestore(deviceId);

    // 2. Fetch events
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .orderBy('deviceTimestamp')
        .get();

    final eventsDocs = query.docs;
    final total = eventsDocs.length;

    final eventBox = Hive.lazyBox<DomainEvent>('events');
    final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');

    // 3. Replay
    for (int i = 0; i < total; i++) {
      onProgress(i + 1, total);

      final data = eventsDocs[i].data();
      final event = DomainEvent.fromFirestore(data);

      final isValid = await hmacService.verifyInstance(event);
      if (!isValid) {
        debugPrint('HMAC mismatch on event ${event.id} — skipping');
        continue;
      }

      event.synced = true;
      await eventBox.put(event.id, event);

      await _applyEventToSnapshot(event, snapshotBox);
    }
  }

  static Future<void> _applyEventToSnapshot(
    DomainEvent event,
    LazyBox<MemberSnapshot> snapshotBox,
  ) async {
    final type = event.eventType;
    
    switch (type) {
      case EventType.memberCreated:
        final snap = MemberSnapshot.fromPayload(event.entityId, event.payload);
        await snapshotBox.put(event.entityId, snap);
        break;
      case EventType.paymentAdded:
      case EventType.membershipRenewed:
      case EventType.paymentRecorded:
        final snap = await snapshotBox.get(event.entityId);
        if (snap == null) break;
        final newExpiryStr = event.payload[EventPayloadKeys.newExpiry];
        if (newExpiryStr != null) {
          snap.expiryDate = DateTime.parse(newExpiryStr);
        }
        snap.totalPaid += (event.payload[EventPayloadKeys.amount] as num).toInt();
        snap.paymentIds.add(event.payload[EventPayloadKeys.paymentId]);
        snap.lastUpdated = event.deviceTimestamp;
        await snapshotBox.put(event.entityId, snap);
        break;
      case EventType.joinDateEdited:
        final snap = await snapshotBox.get(event.entityId);
        if (snap == null) break;
        snap.joinDate = DateTime.parse(event.payload['newDate']);
        snap.joinDateHistory.add(JoinDateChange(
          previousDate: DateTime.parse(event.payload['previousDate']),
          newDate: DateTime.parse(event.payload['newDate']),
          reason: event.payload['reason'],
          changedAt: event.deviceTimestamp,
        ));
        await snapshotBox.put(event.entityId, snap);
        break;
      case EventType.memberArchived:
        final snap = await snapshotBox.get(event.entityId);
        if (snap == null) break;
        snap.archived = true;
        await snapshotBox.put(event.entityId, snap);
        break;
      default:
        break;
    }
  }
}
