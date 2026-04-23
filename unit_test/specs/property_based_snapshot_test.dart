import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/snapshot_builder.dart';
import '../../test/helpers/property_tester.dart';
import 'dart:math';

void main() {
  group('Snapshot Property-Based Tests', () {
    final random = Random(42); // Seeded for determinism

    List<DomainEvent> generateRandomEvents(int count) {
      final events = <DomainEvent>[];
      const memberId = 'member-1';
      
      for (int i = 0; i < count; i++) {
        final now = DateTime(2024, 3, 25).add(Duration(days: i));
        
        if (i == 0) {
          events.add(DomainEvent(
            id: 'ev-$i',
            entityId: memberId,
            eventType: EventType.memberCreated,
            payload: {
              'name': 'User $i',
              'phone': '123',
              'joinDate': now.toIso8601String(),
            },
            deviceTimestamp: now,
            deviceId: 'dev-1',
          ));
        } else {
          // Randomly choose between update and payment
          if (random.nextBool()) {
            events.add(DomainEvent(
              id: 'ev-$i',
              entityId: memberId,
              eventType: EventType.memberUpdated,
              payload: {'name': 'User $i updated'},
              deviceTimestamp: now,
              deviceId: 'dev-1',
            ));
          } else {
            events.add(DomainEvent(
              id: 'ev-$i',
              entityId: memberId,
              eventType: EventType.paymentAdded,
              payload: {
                'paymentId': 'pay-$i',
                'amount': 10000,
                'newExpiry': now.add(const Duration(days: 30)).toIso8601String(),
              },
              deviceTimestamp: now,
              deviceId: 'dev-1',
            ));
          }
        }
      }
      return events;
    }

    test('Invariant: Rebuild(events) == IncrementalApply(events) for 100 random sequences', () {
      for (int i = 0; i < 100; i++) {
        final events = generateRandomEvents(1 + random.nextInt(20));
        SnapshotPropertyTester.verifyInvariants(events);
      }
    });

    test('Ordering Invariant: Rebuild result should be independent of event order if timestamps are same (NOT TRUE in ES, but we verify stable arrival)', () {
      // In Event Sourcing, order of application matters if events are causal.
      // We verify that SnapshotBuilder handles sequential ordering correctly.
      final now = DateTime(2024, 3, 25);
      final events = [
        DomainEvent(id: '1', entityId: 'm1', eventType: EventType.memberCreated, payload: {'name': 'A', 'phone': '1', 'joinDate': now.toIso8601String()}, deviceTimestamp: now, deviceId: 'd1'),
        DomainEvent(id: '2', entityId: 'm1', eventType: EventType.memberUpdated, payload: {'name': 'B'}, deviceTimestamp: now.add(const Duration(minutes: 1)), deviceId: 'd1'),
      ];
      
      final result = SnapshotBuilder.rebuild(events);
      expect(result?.name, 'B');
    });
  });
}



