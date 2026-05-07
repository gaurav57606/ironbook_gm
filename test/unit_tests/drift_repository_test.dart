import '../test_helper.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';

void main() {
  late OutboxDatabase db;
  late DriftMemberRepository memberRepo;
  late OutboxRepository outboxRepo;
  late MockHmacService mockHmac;

  setUp(() {
    db = TestHelper.setupDrift();
    mockHmac = MockHmacService();
    memberRepo = DriftMemberRepository(db, mockHmac);
    outboxRepo = OutboxRepository(db);

    // Default HMAC stub
    when(() => mockHmac.signSnapshot(any(), any())).thenAnswer((_) async => 'valid-sig');
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftMemberRepository Tests', () {
    final testMember = MemberSnapshot(
      memberId: 'm1',
      name: 'Test User',
      phone: '1234567890',
      joinDate: DateTime(2025, 1, 1),
      planId: 'p1',
      planName: 'Gold',
      expiryDate: DateTime(2025, 7, 1),
      totalPaid: 1000,
    );

    test('upsertMember: should insert and retrieve a member', () async {
      await memberRepo.upsertMember(testMember);

      final retrieved = await memberRepo.getMember('m1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test User');
      expect(retrieved.hmacSignature, 'valid-sig');
    });

    test('deleteMember: should remove a member', () async {
      await memberRepo.upsertMember(testMember);
      await memberRepo.deleteMember('m1');

      final retrieved = await memberRepo.getMember('m1');
      expect(retrieved, isNull);
    });

    test('applyEvent: should update member state from event', () async {
      await memberRepo.upsertMember(testMember);

      final updateEvent = DomainEvent(
        id: 'e1',
        entityId: 'm1',
        eventType: EventType.memberUpdated,
        deviceId: 'd1',
        deviceTimestamp: DateTime.now(),
        payload: {'name': 'Updated Name'},
      );

      await memberRepo.applyEvent(updateEvent);

      final retrieved = await memberRepo.getMember('m1');
      expect(retrieved!.name, 'Updated Name');
    });

    test('watchAllMembers: should emit updates when members change', () async {
      final stream = memberRepo.watchAllMembers();
      
      // We expect at least the update after upsert. 
      // The initial empty list might be emitted too fast or skipped depending on implementation.
      // So we use emitsThrough to find our member.
      expectLater(stream, emitsThrough(contains(predicate<MemberSnapshot>((m) => m.memberId == 'm1'))));

      await memberRepo.upsertMember(testMember);
    });
  });

  group('OutboxRepository Tests', () {
    final testEvent = DomainEvent(
      id: 'e1',
      entityId: 'm1',
      eventType: EventType.memberCreated,
      deviceId: 'd1',
      deviceTimestamp: DateTime(2025, 1, 1),
      payload: {'name': 'New User'},
      hmacSignature: 'event-sig',
    );

    test('enqueueEvent: should store event in outbox', () async {
      await outboxRepo.insertEvent(testEvent);

      final unsynced = await outboxRepo.getUnsyncedEvents();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, 'e1');
      expect(unsynced.first.synced, false);
    });

    test('markSynced: should update event sync status', () async {
      await outboxRepo.insertEvent(testEvent);
      await outboxRepo.markSynced('e1');

      final unsynced = await outboxRepo.getUnsyncedEvents();
      expect(unsynced, isEmpty);
    });

    test('purgeSyncedBefore: should remove old synced events', () async {
      await outboxRepo.insertEvent(testEvent);
      await outboxRepo.markSynced('e1');
      
      // Before clear
      final allCount = await db.select(db.outboxEvents).get();
      expect(allCount.length, 1);

      await outboxRepo.purgeSyncedBefore(DateTime.now().add(const Duration(seconds: 1)));

      // After clear
      final afterCount = await db.select(db.outboxEvents).get();
      expect(afterCount, isEmpty);
    });
  });
}
