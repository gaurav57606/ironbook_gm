import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/security/play_integrity_service.dart';
import 'package:ironbook_gm/core/data/local/snapshot_builder.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart' hide MemberSnapshotAdapter;
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'dart:io';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:drift/native.dart';

class MockOutboxDatabase extends Mock implements OutboxDatabase {}

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    
    // Register adapters for testing
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(DomainEventAdapter());
    if (!Hive.isAdapterRegistered(11)) {
        // EventType adapter usually registered via HiveInit, 
        // but for unit tests we might need manual registration if not using HiveInit.
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MemberSnapshotAdapter());
  });

  group('Sprint 2: App Attestation (Play Integrity)', () {
    test('Should generate a unique nonce and validate a simulated token', () async {
      final service = PlayIntegrityService();
      final nonce = service.generateNonce();
      expect(nonce, isNotEmpty);
      
      final token = await service.getIntegrityToken(nonce);
      expect(token, isNotNull);
      
      final isValid = await service.isDeviceIntegrityValid();
      expect(isValid, isTrue);
    });
  });

  group('Sprint 2: Snapshot Reconstruction Refinement', () {
    test('Should apply checkInRecorded and planAssigned events correctly', () {
      final baseDate = DateTime(2026, 1, 1);
      final initial = MemberSnapshot(
        memberId: 'm1',
        name: 'John Doe',
        joinDate: baseDate,
      );

      // 1. Plan Assigned
      final planEvent = DomainEvent(
        entityId: 'm1',
        eventType: EventType.planAssigned,
        deviceId: 'd1',
        deviceTimestamp: baseDate.add(const Duration(hours: 1)),
        payload: {
          EventPayloadKeys.planId: 'p1',
          EventPayloadKeys.planName: 'Platinum',
        },
      );

      final withPlan = SnapshotBuilder.apply(initial, planEvent);
      expect(withPlan?.planId, 'p1');

      // 2. Check-In Recorded
      final checkInTime = baseDate.add(const Duration(days: 1));
      final checkInEvent = DomainEvent(
        entityId: 'm1',
        eventType: EventType.checkInRecorded,
        deviceId: 'd1',
        deviceTimestamp: checkInTime,
        payload: {
          EventPayloadKeys.memberId: 'm1',
        },
      );

      final withCheckIn = SnapshotBuilder.apply(withPlan, checkInEvent);
      expect(withCheckIn?.lastCheckIn, checkInTime);
      expect(withCheckIn?.lastCheckInDevice, 'd1');
    });

    test('Should handle corrupt events gracefully during rebuild', () {
      final events = <DomainEvent>[
        DomainEvent(
          entityId: 'm1',
          eventType: EventType.memberCreated,
          deviceId: 'd1',
          deviceTimestamp: DateTime.now(),
          payload: {'name': 'Valid'},
        ),
        DomainEvent(
          entityId: 'm1',
          eventType: EventType.paymentAdded,
          deviceId: 'd1',
          deviceTimestamp: DateTime.now(),
          payload: {
              'amount': 'not_a_number',
          },
        ),
      ];

      // Rebuild should not throw
      expect(() => SnapshotBuilder.rebuild(events), returnsNormally);
    });
  });

  group('Sprint 2: Sync Coordination (Locking)', () {
    test('Should coordinate locks between holders', () async {
      final db = OutboxDatabase(NativeDatabase.memory());
      final coordinator = SyncCoordinator(db);
      await coordinator.clearAllLocks();
      
      final ok = await coordinator.acquireLock('h1');
      expect(ok, isTrue);
      
      final fail = await coordinator.acquireLock('h2');
      expect(fail, isFalse);
      
      await coordinator.releaseLock('h1');
      
      final ok2 = await coordinator.acquireLock('h2');
      expect(ok2, isTrue);
    });
  });
}


