import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/data/local/snapshot_builder.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';

void main() {
  group('Event Replay Unit Tests (TC-UNIT-07)', () {
    const memberId = 'member-123';
    final now = DateTime(2026, 3, 25);

    test('MEMBER_CREATED should initialize snapshot', () {
      final event = DomainEvent(
        entityId: memberId,
        eventType: EventType.memberCreated,
        deviceId: 'device-1',
        deviceTimestamp: now,
        payload: {
          'memberId': memberId,
          'name': 'John Doe',
          'phone': '1234567890',
          'joinDate': DateTime(2026, 1, 1).toIso8601String(),
          'expiryDate': DateTime(2026, 2, 1).toIso8601String(),
        },
      );

      final snapshot = SnapshotBuilder.apply(null, event);
      expect(snapshot?.name, 'John Doe');
      expect(snapshot?.memberId, memberId);
      expect(snapshot?.expiryDate, DateTime(2026, 2, 1));
    });

    test('PAYMENT_RECEIVED should update totalPaid and expiryDate', () {
      final base = MemberSnapshot(
        memberId: memberId,
        name: 'John Doe',
        joinDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 2, 1),
        totalPaid: 1000,
      );

      final event = DomainEvent(
        entityId: memberId,
        eventType: EventType.paymentAdded,
        deviceId: 'device-1',
        deviceTimestamp: now,
        payload: {
          'amount': 1500,
          'newExpiry': DateTime(2026, 3, 1).toIso8601String(),
          'paymentId': 'pay-1',
        },
      );

      final updated = SnapshotBuilder.apply(base, event);
      expect(updated?.totalPaid, 2500);
      expect(updated?.expiryDate, DateTime(2026, 3, 1));
      expect(updated?.paymentIds.contains('pay-1'), true);
    });

    test('MEMBER_ARCHIVED should set archived flag', () {
      final base = MemberSnapshot(
        memberId: memberId,
        name: 'John Doe',
        joinDate: DateTime(2026, 1, 1),
      );

      final event = DomainEvent(
        entityId: memberId,
        eventType: EventType.memberArchived,
        deviceId: 'device-1',
        deviceTimestamp: now,
        payload: {},
      );

      final updated = SnapshotBuilder.apply(base, event);
      expect(updated?.archived, true);
    });

    test('Full rebuild from event list should produce correct final state', () {
      final events = [
         DomainEvent(
          entityId: memberId,
          eventType: EventType.memberCreated,
          deviceId: 'device-1',
          deviceTimestamp: now.subtract(const Duration(days: 10)),
          payload: {'memberId': memberId, 'name': 'John', 'joinDate': now.toIso8601String()},
        ),
        DomainEvent(
          entityId: memberId,
          eventType: EventType.paymentAdded,
          deviceId: 'device-1',
          deviceTimestamp: now.subtract(const Duration(days: 5)),
          payload: {'amount': 1000, 'paymentId': 'p1'},
        ),
         DomainEvent(
          entityId: memberId,
          eventType: EventType.memberUpdated,
          deviceId: 'device-1',
          deviceTimestamp: now,
          payload: {'name': 'John Updated', 'phone': '999'},
        ),
      ];

      final snapshot = SnapshotBuilder.rebuild(events);
      expect(snapshot?.name, 'John Updated');
      expect(snapshot?.totalPaid, 1000);
    });
  });
}



