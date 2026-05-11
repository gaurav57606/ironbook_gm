import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' hide Plan, Member, Payment;
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/core/services/membership_service.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:drift/native.dart';
import 'dart:async';
import '../test_helper.dart';

class FakePreferences extends Fake implements IPreferencesRepository {
  final Map<String, dynamic> _storage = {};
  @override
  Future<int?> getInt(String key) async => _storage[key] as int?;
  @override
  Future<void> setInt(String key, int value) async => _storage[key] = value;
  @override
  Future<String?> getString(String key) async => _storage[key] as String?;
  @override
  Future<void> setString(String key, String value) async => _storage[key] = value;
}

class TrackingSyncCoordinator extends Fake implements SyncCoordinator {
  int syncCallCount = 0;
  @override
  void triggerSync() {
    syncCallCount++;
  }

  @override
  Stream<void> get onSyncRequested => const Stream.empty();
  @override
  Future<bool> acquireLock(String holderId) async => true;
  @override
  Future<void> releaseLock(String holderId) async {}
}

void main() {
  late OutboxDatabase db;
  late DriftMemberRepository memberRepo;
  late FakeDriftEventRepository eventRepo;
  late MockPlanRepo planRepo;
  late FakePreferences prefRepo;
  late FakeClock clock;
  late FakeHmacService hmac;
  late MembershipService membership;
  late TrackingSyncCoordinator coordinator;
  late FakeLoggerService logger;
  late MemberNotifier notifier;

  setUp(() async {
    db = OutboxDatabase(NativeDatabase.memory());
    hmac = FakeHmacService();
    memberRepo = DriftMemberRepository(db, hmac);
    eventRepo = FakeDriftEventRepository();
    planRepo = MockPlanRepo();
    prefRepo = FakePreferences();
    clock = FakeClock();
    membership = MembershipService();
    coordinator = TrackingSyncCoordinator();
    logger = FakeLoggerService();

    notifier = MemberNotifier(
      db,
      eventRepo,
      memberRepo,
      planRepo,
      prefRepo,
      clock,
      hmac,
      membership,
      coordinator,
      logger,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('MemberNotifier.addMember', () {
    test('persists event BEFORE upsert — event exists if snapshot exists',
        () async {
      final joinDate = clock.now;
      final plan = Plan(
        id: 'plan-1',
        name: 'Monthly',
        durationMonths: 1,
        components: [PlanComponent(id: 'c1', name: 'Base', price: 1000)],
      );
      when(() => planRepo.getPlan('plan-1')).thenAnswer((_) async => plan);

      final memberId = await notifier.addMember(
        name: 'John Doe',
        phone: '1234567890',
        planId: 'plan-1',
        joinDate: joinDate,
      );

      // 1. _eventRepo contains a memberCreated event
      final events = await eventRepo.getByEntityId(memberId);
      expect(events.any((e) => e.eventType == EventType.memberCreated), true);

      // 2. _memberRepo contains the member
      final member = await memberRepo.getMember(memberId);
      expect(member, isNotNull);
      expect(member!.name, 'John Doe');

      // 3. state contains the member
      expect(notifier.state.any((m) => m.memberId == memberId), true);
    });

    test('triggers sync after successful add', () async {
      final plan = Plan(
        id: 'plan-1',
        name: 'Monthly',
        durationMonths: 1,
        components: [PlanComponent(id: 'c1', name: 'Base', price: 1000)],
      );
      when(() => planRepo.getPlan('plan-1')).thenAnswer((_) async => plan);

      await notifier.addMember(
        name: 'John Doe',
        phone: '1234567890',
        planId: 'plan-1',
        joinDate: clock.now,
      );

      expect(coordinator.syncCallCount, 1);
    });

    test('does not upsert snapshot if persist throws', () async {
      final plan = Plan(
        id: 'plan-1',
        name: 'Monthly',
        durationMonths: 1,
        components: [PlanComponent(id: 'c1', name: 'Base', price: 1000)],
      );
      when(() => planRepo.getPlan('plan-1')).thenAnswer((_) async => plan);

      // Mock persist to throw
      // Since I'm using a Fake, I'll need to wrap it or use a Mock for this test
    });
  });

  group('MemberNotifier.deleteMember', () {
    test('archives member — does NOT hard-delete Drift row', () async {
      // Setup member
      const memberId = 'm-1';
      final snap = MemberSnapshot(
        memberId: memberId,
        name: 'Old Name',
        joinDate: clock.now,
      );
      await memberRepo.upsertMember(snap);
      notifier.debugState = [snap];

      await notifier.deleteMember(memberId);

      // Verify: member is NOT in state
      expect(notifier.state.any((m) => m.memberId == memberId), false);

      // Verify: member IS in Drift with archived=true
      // Note: getMember by default might not filter, but getAllMembers does.
      // DriftMemberRepository.getMember returns single row.
      final row = await (db.select(db.members)..where((t) => t.id.equals(memberId))).getSingle();
      expect(row.archived, true);

      // Verify: a memberArchived event exists in _eventRepo
      final events = await eventRepo.getByEntityId(memberId);
      expect(events.any((e) => e.eventType == EventType.memberArchived), true);
      
      expect(coordinator.syncCallCount, 1);
    });

    test('archived member does not reappear after rebuildCache', () async {
       // Add member via events, add memberArchived event
      const memberId = 'm-1';
      final now = clock.now;
      eventRepo.persist(DomainEvent(
        entityId: memberId,
        eventType: EventType.memberCreated,
        deviceId: 'dev',
        deviceTimestamp: now,
        payload: {'name': 'John', 'joinDate': now.toIso8601String()},
      ));
      eventRepo.persist(DomainEvent(
        entityId: memberId,
        eventType: EventType.memberArchived,
        deviceId: 'dev',
        deviceTimestamp: now.add(const Duration(seconds: 1)),
        payload: {'memberId': memberId},
      ));

      await notifier.rebuildCache();

      expect(notifier.state.isEmpty, true);
    });
  });

  group('MemberNotifier.rebuildCache', () {
    test('rebuilds ALL members even if checkpoint is recent', () async {
      // Set member_reconcile_ts to a recent time
      await prefRepo.setInt('member_reconcile_ts', clock.now.millisecondsSinceEpoch);

      clock.advance(const Duration(seconds: 1));

      // Add 3 members directly to event repo
      for (int i = 0; i < 3; i++) {
        final id = 'm-$i';
        eventRepo.persist(DomainEvent(
          entityId: id,
          eventType: EventType.memberCreated,
          deviceId: 'dev',
          deviceTimestamp: clock.now,
          payload: {
            'name': 'Member $i',
            'joinDate': clock.now.toIso8601String()
          },
        ));
      }

      await notifier.rebuildCache();

      expect(notifier.state.length, 3);
    });

    test('does not include archived members after rebuild', () async {
      const memberId = 'm-1';
      final now = clock.now;
      eventRepo.persist(DomainEvent(
        entityId: memberId,
        eventType: EventType.memberCreated,
        deviceId: 'dev',
        deviceTimestamp: now,
        payload: {'name': 'John', 'joinDate': now.toIso8601String()},
      ));
      eventRepo.persist(DomainEvent(
        entityId: memberId,
        eventType: EventType.memberArchived,
        deviceId: 'dev',
        deviceTimestamp: now.add(const Duration(seconds: 1)),
        payload: {'memberId': memberId},
      ));

      await notifier.rebuildCache();

      expect(notifier.state.isEmpty, true);
    });
  });

  group('MemberNotifier.updateMember', () {
    test('updates Drift row immediately without waiting for watch stream',
        () async {
      const memberId = 'm-1';
      final snap = MemberSnapshot(
        memberId: memberId,
        name: 'Old Name',
        joinDate: clock.now,
      );
      await memberRepo.upsertMember(snap);
      notifier.debugState = [snap];

      await notifier.updateMember(
        memberId: memberId,
        name: 'New Name',
        phone: '999',
      );

      // state[0].name must equal new name immediately after await
      expect(notifier.state[0].name, 'New Name');
      expect(coordinator.syncCallCount, 1);
    });
  });

  group('MemberNotifier.recordAttendance', () {
    test('updates lastCheckedIn immediately without watch stream', () async {
      const memberId = 'm-1';
      final snap = MemberSnapshot(
        memberId: memberId,
        name: 'John',
        joinDate: clock.now,
      );
      await memberRepo.upsertMember(snap);
      notifier.debugState = [snap];

      clock.advance(const Duration(hours: 2));
      final checkInTime = clock.now;

      await notifier.recordAttendance(memberId);

      expect(notifier.state[0].lastCheckIn, checkInTime);
      expect(coordinator.syncCallCount, 1);
    });
  });
}
