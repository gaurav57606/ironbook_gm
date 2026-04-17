import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import '../helpers/mocks.dart';

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
  Future<void> markAsSynced(String eventId) async {}
  
  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

void main() {
  group('Chaos Recovery Tests (TC-RECO-01)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ironbook_chaos');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(DomainEventAdapter());
      if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(MemberSnapshotAdapter());
      await Hive.openBox<MemberSnapshot>('snapshots');
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('Should recover state from events if snapshots box is empty/cleared', () async {
      final repo = MockRepo();
      final clock = SystemClock();
      
      // 1. Add some events to the repo
      repo.events.add(DomainEvent(
        entityId: 'm1',
        eventType: EventType.memberCreated,
        deviceId: 'd1',
        deviceTimestamp: DateTime.now(),
        payload: {'name': 'Survivor', 'joinDate': DateTime.now().toIso8601String()},
      ));

      // 2. Initialize Notifier with empty snapshots box
      final hmac = FakeHmacService();
      final notifier = MemberNotifier(repo, clock, hmac);
      
      // 3. Verify recovery
      expect(notifier.state.length, 1);
      expect(notifier.state.first.name, 'Survivor');
      
      final box = Hive.box<MemberSnapshot>('snapshots');
      expect(box.length, 1, reason: 'Snapshots should have been rebuilt in the box');
    });
  });
}
