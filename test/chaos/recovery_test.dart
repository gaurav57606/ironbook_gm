import '../test_helper.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as drift;
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo implements IEventRepository {
  final List<DomainEvent> events = [];

  @override
  Future<void> persist(DomainEvent event) async {
    events.add(event);
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async => events;

  @override
  Future<DomainEvent?> getById(String id) async {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async =>
      events.where((e) => e.entityId == entityId).toList();

  @override
  Future<List<DomainEvent>> getAll() async => List.from(events);
  @override
  Future<List<DomainEvent>> getEventsSince(DateTime since) async {
    return events.where((e) => e.deviceTimestamp.isAfter(since)).toList();
  }

  @override
  Future<void> markAsSynced(String eventId) async {}

  @override
  Future<void> persistSynced(DomainEvent event) async {
    events.add(event);
  }

  @override
  Stream<DomainEvent> watch() => const Stream.empty();

  @override
  Future<Map<String, List<DomainEvent>>> getByEntityIds(
      List<String> entityIds) async {
    final Map<String, List<DomainEvent>> result = {};
    for (final id in entityIds) {
      result[id] = events.where((e) => e.entityId == id).toList();
    }
    return result;
  }
}

class MockSyncCoordinator extends Mock implements SyncCoordinator {}
class MockOutboxDatabase extends Mock implements drift.OutboxDatabase {}

void main() {
  group('Chaos Recovery Tests (TC-RECO-01)', () {
    setUp(() async {
      await TestHelper.setupHive('chaos');
    });

    tearDown(() async {
      await TestHelper.cleanHive();
    });

    test('Should recover state from events if snapshots box is empty/cleared',
        () async {
      final repo = MockRepo();
      final clock = SystemClock();

      // 1. Add some events to the repo
      repo.events.add(DomainEvent(
        entityId: 'm1',
        eventType: EventType.memberCreated,
        deviceId: 'd1',
        deviceTimestamp: DateTime.now(),
        payload: {
          'name': 'Survivor',
          'joinDate': DateTime.now().toIso8601String()
        },
      ));

      // 2. Initialize Notifier with empty snapshots box
      final hmac = FakeHmacService();
      final mockMemberRepo = MockMemberRepo();
      when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => []);

      final notifier = MemberNotifier(
        MockOutboxDatabase() as drift.OutboxDatabase,
        repo,
        mockMemberRepo,
        MockPlanRepo(),
        MockPreferencesRepo(),
        clock,
        hmac,
        MockSyncCoordinator(),
      );

      // Wait for init to complete
      await Future.delayed(Duration.zero);

      // 3. Verify recovery
      expect(notifier.state.length, 1);
      expect(notifier.state.first.name, 'Survivor');

      final box = Hive.lazyBox<MemberSnapshot>('snapshots');
      expect(box.length, 1,
          reason: 'Snapshots should have been rebuilt in the box');
    });
  });
}
