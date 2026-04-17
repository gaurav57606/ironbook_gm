import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/snapshot_builder.dart';

void main() {
  group('SnapshotBuilder & Business Logic', () {
    test('MEMBER_CREATED should produce initial snapshot', () {
      final event = DomainEvent(
        id: 'evt-1',
        entityId: 'mem-1',
        eventType: EventType.memberCreated,
        deviceId: 'dev-1',
        deviceTimestamp: DateTime(2024, 3, 25),
        payload: {
          'name': 'John Doe',
          'phone': '1234567890',
          'joinDate': '2024-03-25T00:00:00Z',
          'planId': 'plan-1',
          'planName': 'Monthly',
          'expiryDate': '2024-04-25T00:00:00Z',
          'totalPaid': 0,
        },
      );

      final result = SnapshotBuilder.apply(null, event);

      expect(result, isNotNull);
      expect(result!.name, 'John Doe');
      expect(result.totalPaid, 0);
      expect(result.expiryDate, DateTime.parse('2024-04-25T00:00:00Z'));
    });

    test('PAYMENT_RECEIVED should update totalPaid and expiryDate', () {
      final initial = MemberSnapshot(
        memberId: 'mem-1',
        name: 'John Doe',
        phone: '1234567890',
        joinDate: DateTime(2024, 3, 25),
        totalPaid: 0,
        expiryDate: DateTime(2024, 4, 25),
      );

      final event = DomainEvent(
        id: 'evt-2',
        entityId: 'mem-1',
        eventType: EventType.paymentAdded,
        deviceId: 'dev-1',
        deviceTimestamp: DateTime(2024, 3, 26),
        payload: {
          'amount': 129800, // 1298.00 in paise
          'newExpiry': '2024-05-25T00:00:00Z',
          'paymentId': 'pay-1',
        },
      );

      final result = SnapshotBuilder.apply(initial, event);

      expect(result!.totalPaid, 129800);
      expect(result.expiryDate, DateTime.parse('2024-05-25T00:00:00Z'));
      expect(result.paymentIds, contains('pay-1'));
    });

    test('rebuild should process multiple events in order', () {
      final events = [
        DomainEvent(
          id: 'evt-1',
          entityId: 'mem-1',
          eventType: EventType.memberCreated,
          deviceId: 'dev-1',
          deviceTimestamp: DateTime(2024, 3, 25, 10),
          payload: {
            'name': 'John Doe',
            'phone': '1234567890',
            'joinDate': '2024-03-25T00:00:00Z',
          },
        ),
        DomainEvent(
          id: 'evt-2',
          entityId: 'mem-1',
          eventType: EventType.paymentAdded,
          deviceId: 'dev-1',
          deviceTimestamp: DateTime(2024, 3, 25, 11),
          payload: {
            'amount': 100000,
            'paymentId': 'pay-1',
          },
        ),
        DomainEvent(
          id: 'evt-3',
          entityId: 'mem-1',
          eventType: EventType.memberUpdated,
          deviceId: 'dev-1',
          deviceTimestamp: DateTime(2024, 3, 26),
          payload: {
            'name': 'John Updated',
            'phone': '0987654321',
          },
        ),
      ];

      final result = SnapshotBuilder.rebuild(events);

      expect(result!.name, 'John Updated');
      expect(result.totalPaid, 100000);
      expect(result.paymentIds.length, 1);
    });
  });
}
