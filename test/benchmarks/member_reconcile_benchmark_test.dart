import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart';

class MockEventRepository extends Mock implements IEventRepository {}
class MockClock extends Mock implements IClock {}
class MockHmacService extends Mock implements HmacService {}

void main() {
  late MockEventRepository mockRepo;
  late MockClock mockClock;
  late MockHmacService mockHmac;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('member_benchmark');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(DomainEventAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(MemberSnapshotAdapter());
  });

  setUp(() async {
    mockRepo = MockEventRepository();
    mockClock = MockClock();
    mockHmac = MockHmacService();

    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');
    when(() => mockHmac.signSnapshot(any(), any())).thenAnswer((_) async => 'mock-sig');
    when(() => mockHmac.verifySnapshot(any(), any(), any())).thenAnswer((_) async => true);
    when(() => mockHmac.verifyInstance(any())).thenAnswer((_) async => true);

    when(() => mockClock.now).thenReturn(DateTime(2026, 1, 1));
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    if (Hive.isBoxOpen('events')) await Hive.box<DomainEvent>('events').close();
    if (Hive.isBoxOpen('snapshots')) await Hive.lazyBox<MemberSnapshot>('snapshots').close();
  });

  test('Benchmark: MemberNotifier.init with 5 members', () async {
    final membersCount = 5;
    final now = DateTime(2026, 1, 1);
    final allEvents = <DomainEvent>[];

    for (int i = 0; i < membersCount; i++) {
      final id = 'M$i';
      allEvents.add(DomainEvent(
        entityId: id,
        eventType: EventType.memberCreated,
        deviceId: 'test-device',
        deviceTimestamp: now.subtract(Duration(days: 1)),
        payload: {
          'memberId': id,
          'name': 'Member $i',
          'joinDate': now.subtract(Duration(days: 1)).toIso8601String(),
        },
      ));
    }

    when(() => mockRepo.getAll()).thenAnswer((_) async => allEvents);
    for (int i = 0; i < membersCount; i++) {
      final id = 'M$i';
      final memberEvents = [allEvents[i]];
      when(() => mockRepo.getByEntityId(id)).thenAnswer((_) async => memberEvents);
    }

    // Open boxes
    await Hive.openBox<DomainEvent>('events');
    final snapshotBox = await Hive.openLazyBox<MemberSnapshot>('snapshots');
    await snapshotBox.clear();

    final stopwatch = Stopwatch()..start();
    final notifier = MemberNotifier(mockRepo, mockClock, mockHmac);

    await notifier.init();
    stopwatch.stop();

    print('BASELINE: Time to reconcile $membersCount members: ${stopwatch.elapsedMilliseconds}ms');
    expect(notifier.state.length, membersCount);
  });
}
