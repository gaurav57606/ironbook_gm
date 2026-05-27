import '../local/models/member_snapshot_model.dart';
import '../local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:flutter/foundation.dart';

/// Aggregator logic to apply events to snapshots (Event Sourcing).
class SnapshotBuilder {
  /// Applies a single event to a snapshot and returns the new state.
  static MemberSnapshot? apply(MemberSnapshot? current, DomainEvent event) {
    final payload = event.payload;

    final type = event.eventType;
    if (type == EventType.memberCreated) {
      return MemberSnapshot.fromPayload(event.entityId, payload);
    }

    if (current == null) return null;

    if (type == EventType.paymentAdded || 
        type == EventType.membershipExtended || 
        type == EventType.membershipRenewed || 
        type == EventType.paymentRecorded) {
      final amount = payload[EventPayloadKeys.amount] as num?;
      final newExpiryStr = payload[EventPayloadKeys.newExpiry] as String?;
      final newExpiry = newExpiryStr != null ? DateTime.parse(newExpiryStr) : null;
      final newJoinStr = payload['joinDate'] as String?;
      final newJoin = newJoinStr != null ? DateTime.parse(newJoinStr) : null;
      
      return current.copyWith(
        totalPaid: current.totalPaid + (amount?.toInt() ?? 0),
        joinDate: newJoin ?? current.joinDate,
        expiryDate: newExpiry ?? current.expiryDate,
        planId: payload[EventPayloadKeys.planId] ?? current.planId,
        planName: payload[EventPayloadKeys.planName] ?? current.planName,
        paymentIds: [...current.paymentIds, payload[EventPayloadKeys.paymentId] ?? event.id],
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.planAssigned) {
      return current.copyWith(
        planId: payload[EventPayloadKeys.planId],
        planName: payload[EventPayloadKeys.planName],
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.joinDateEdited) {
      final newJoinDateStr = payload[EventPayloadKeys.joinDate] as String?;
      final newJoinDate = newJoinDateStr != null ? DateTime.parse(newJoinDateStr) : null;
      final newExpiryStr = payload[EventPayloadKeys.newExpiry] as String?;
      final newExpiry = newExpiryStr != null ? DateTime.parse(newExpiryStr) : null;
      return current.copyWith(
        joinDate: newJoinDate ?? current.joinDate,
        expiryDate: newExpiry ?? current.expiryDate,
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.checkInRecorded) {
      return current.copyWith(
        lastCheckIn: event.deviceTimestamp,
        lastCheckInDevice: event.deviceId,
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.memberArchived) {
      return current.copyWith(
        archived: true,
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.memberUpdated) {
      return current.copyWith(
        name: payload[EventPayloadKeys.name] ?? current.name,
        phone: payload[EventPayloadKeys.phone] ?? current.phone,
        photoPath: payload['photoPath'] ?? current.photoPath,
        photoUrl: payload['photoUrl'] ?? current.photoUrl,
        lastUpdated: event.deviceTimestamp,
      );
    }

    return current;
  }

  /// Rebuilds a member snapshot from a full list of events.
  static MemberSnapshot? rebuild(List<DomainEvent> events) {
    if (events.isEmpty) return null;
    
    // Ensure chronological order
    final sortedEvents = List<DomainEvent>.from(events)
      ..sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));
    
    MemberSnapshot? state;
    for (final event in sortedEvents) {
      try {
        state = apply(state, event);
      } catch (e) {
        // Log error but continue with other events for maximum data recovery
        debugPrint('SnapshotBuilder: Error applying event ${event.id}: $e');
      }
    }
    return state;
  }
}










