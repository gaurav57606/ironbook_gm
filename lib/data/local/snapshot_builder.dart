import '../local/models/member_snapshot_model.dart';
import '../local/models/domain_event_model.dart';

/// Aggregator logic to apply events to snapshots (Event Sourcing).
class SnapshotBuilder {
  /// Applies a single event to a snapshot and returns the new state.
  static MemberSnapshot? apply(MemberSnapshot? current, DomainEvent event) {
    final payload = event.payload;

    final type = event.eventType;
    if (type == EventType.memberCreated.name) {
      return MemberSnapshot.fromPayload(event.entityId, payload);
    }

    if (current == null) return null;

    if (type == EventType.paymentAdded.name || type == EventType.membershipExtended.name) {
      final amount = payload['amount'] as num;
      final newExpiryStr = payload['newExpiry'] as String?;
      final newExpiry = newExpiryStr != null ? DateTime.parse(newExpiryStr) : null;
      
      return current.copyWith(
        totalPaid: current.totalPaid + amount.toInt(),
        expiryDate: newExpiry ?? current.expiryDate,
        paymentIds: [...current.paymentIds, payload['paymentId'] ?? event.id],
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.memberArchived.name) {
      return current.copyWith(
        archived: true,
        lastUpdated: event.deviceTimestamp,
      );
    }

    if (type == EventType.memberUpdated.name) {
      return current.copyWith(
        name: payload['name'],
        phone: payload['phone'],
        lastUpdated: event.deviceTimestamp,
      );
    }

    return current;
  }

  /// Rebuilds a member snapshot from a full list of events.
  static MemberSnapshot? rebuild(List<DomainEvent> events) {
    if (events.isEmpty) return null;
    
    // Ensure chronological order
    events.sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));
    
    MemberSnapshot? state;
    for (final event in events) {
      state = apply(state, event);
    }
    return state;
  }
}
