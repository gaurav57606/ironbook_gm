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
      
      return current.copyWith(
        totalPaid: current.totalPaid + (amount?.toInt() ?? 0),
        expiryDate: newExpiry ?? current.expiryDate,
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
      return current.copyWith(
        lastUpdated: event.deviceTimestamp,
      );
      // NOTE: joinDate is typically final in the snapshot, but if edited, 
      // we'd need to update it. MemberSnapshot doesn't have joinDate in copyWith yet.
      // For now, we update lastUpdated to trigger a re-render.
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










