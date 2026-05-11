import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/services/membership_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as drift;
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart' hide MemberSnapshotAdapter;

class MockEventRepository extends Mock implements IEventRepository {}
class MockMemberRepository extends Mock implements IMemberRepository {}
class MockPlanRepository extends Mock implements IPlanRepository {}
class MockPreferencesRepository extends Mock implements IPreferencesRepository {}
class MockClock extends Mock implements IClock {}
class MockHmacService extends Mock implements HmacService {}
class MockSyncCoordinator extends Mock implements SyncCoordinator {}
class MockOutboxDatabase extends Mock implements drift.OutboxDatabase {}
class MockMembershipService extends Mock implements MembershipService {}

void main() {
  late MockEventRepository mockRepo;
  late MockMemberRepository mockMemberRepo;
  late MockPlanRepository mockPlanRepo;
  late MockPreferencesRepository mockPrefRepo;
  late MockClock mockClock;
  late MockSyncCoordinator mockCoordinator;
  late MockHmacService mockHmac;
  late MockOutboxDatabase mockDb;
  late MockMembershipService mockMembership;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('member_benchmark');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(DomainEventAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(MemberSnapshotAdapter());
    
    registerFallbackValue(DomainEvent(
      entityId: 'dummy',
      eventType: EventType.memberCreated,
      payload: {},
      deviceId: 'dummy',
      deviceTimestamp: DateTime.now(),
    ));
  });

  setUp(() async {
    mockRepo = MockEventRepository();
    mockMemberRepo = MockMemberRepository();
    mockPlanRepo = MockPlanRepository();
    mockPrefRepo = MockPreferencesRepository();
    mockClock = MockClock();
    mockCoordinator = MockSyncCoordinator();
    mockHmac = MockHmacService();
    mockDb = MockOutboxDatabase();
    mockMembership = MockMembershipService();

    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');
    when(() => mockHmac.signSnapshot(any(), any())).thenAnswer((_) async => 'mock-sig');
    when(() => mockHmac.verifySnapshot(any(), any(), any())).thenAnswer((_) async => true);
    when(() => mockHmac.verifyInstance(any())).thenAnswer((_) async => true);
    when(() => mockCoordinator.triggerSync()).thenReturn(null);

    when(() => mockClock.now).thenReturn(DateTime(2026, 1, 1));
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());
    
    when(() => mockPrefRepo.getInt(any())).thenAnswer((_) async => 0);
    when(() => mockPrefRepo.setInt(any(), any())).thenAnswer((_) async => true);
    
    when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => []);
    when(() => mockMemberRepo.applyEvent(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    if (Hive.isBoxOpen('events')) await Hive.box<DomainEvent>('events').close();
    if (Hive.isBoxOpen('snapshots')) await Hive.lazyBox<MemberSnapshot>('snapshots').close();
  });

  test('Benchmark: MemberNotifier.init with 5 members', () async {
    const membersCount = 5;
    final now = DateTime(2026, 1, 1);
    final allEvents = <DomainEvent>[];

    for (int i = 0; i < membersCount; i++) {
      final id = 'M$i';
      allEvents.add(DomainEvent(
        entityId: id,
        eventType: EventType.memberCreated,
        deviceId: 'test-device',
        deviceTimestamp: now.subtract(const Duration(days: 1)),
        payload: {
          'memberId': id,
          'name': 'Member $i',
          'joinDate': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
      ));
    }

    when(() => mockRepo.getAll()).thenAnswer((_) async => allEvents);
    when(() => mockRepo.getEventsSince(any())).thenAnswer((_) async => allEvents);
    for (int i = 0; i < membersCount; i++) {
      final id = 'M$i';
      final memberEvents = [allEvents[i]];
      when(() => mockRepo.getByEntityId(id)).thenAnswer((_) async => memberEvents);
      
      final memberSnapshot = MemberSnapshot.fromPayload(id, allEvents[i].payload);
      when(() => mockMemberRepo.getMember(id)).thenAnswer((_) async => memberSnapshot);
    }
    
    when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => 
      allEvents.map((e) => MemberSnapshot.fromPayload(e.entityId, e.payload)).toList()
    );

    // Open boxes
    await Hive.openBox<DomainEvent>('events');
    final snapshotBox = await Hive.openLazyBox<MemberSnapshot>('snapshots');
    await snapshotBox.clear();

    final stopwatch = Stopwatch()..start();
    final notifier = MemberNotifier(mockDb as drift.OutboxDatabase, mockRepo, mockMemberRepo, mockPlanRepo, mockPrefRepo, mockClock, mockHmac, mockMembership, mockCoordinator);

    await notifier.init();
    stopwatch.stop();

    // ignore: avoid_print
    print('BASELINE: Time to reconcile $membersCount members: ${stopwatch.elapsedMilliseconds}ms');
    expect(notifier.state.length, membersCount);
  });
}
