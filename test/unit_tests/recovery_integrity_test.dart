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
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart' as manual;
import 'dart:io';

class MockEventRepository extends Mock implements IEventRepository {}
class MockMemberRepository extends Mock implements IMemberRepository {}
class MockPlanRepository extends Mock implements IPlanRepository {}
class MockPreferencesRepository extends Mock implements IPreferencesRepository {}
class MockClock extends Mock implements IClock {}
class MockHmacService extends Mock implements HmacService {}
class FakeDomainEvent extends Fake implements DomainEvent {}
class FakeMemberSnapshot extends Fake implements MemberSnapshot {}

void main() {
  late MockEventRepository mockEventRepo;
  late MockMemberRepository mockMemberRepo;
  late MockPlanRepository mockPlanRepo;
  late MockPreferencesRepository mockPrefRepo;
  late MockClock mockClock;
  late MockHmacService mockHmac;

  setUpAll(() async {
    registerFallbackValue(FakeDomainEvent());
    registerFallbackValue(FakeMemberSnapshot());
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(manual.DomainEventAdapter());
    // Use fully qualified name for MemberSnapshotAdapter to avoid ambiguity if it's also in .g.dart
    // Actually manual_adapters.dart doesn't have MemberSnapshotAdapter based on previous grep
    // So it must be coming from the .g.dart which is part of the model file.
  });

  setUp(() async {
    mockEventRepo = MockEventRepository();
    mockMemberRepo = MockMemberRepository();
    mockPlanRepo = MockPlanRepository();
    mockPrefRepo = MockPreferencesRepository();
    mockClock = MockClock();
    mockHmac = MockHmacService();

    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');
    when(() => mockHmac.signSnapshot(any(), any())).thenAnswer((_) async => 'mock-sig');
    when(() => mockHmac.verifySnapshot(any(), any(), any())).thenAnswer((_) async => true);
    when(() => mockClock.now).thenReturn(DateTime(2026, 1, 1));
    when(() => mockEventRepo.watch()).thenAnswer((_) => const Stream.empty());
    when(() => mockEventRepo.getEventsSince(any())).thenAnswer((_) async => []);
    when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => []);
    when(() => mockMemberRepo.getMembers(any())).thenAnswer((_) async => []);
    when(() => mockEventRepo.getEventsForEntities(any())).thenAnswer((_) async => []);
    when(() => mockPrefRepo.getInt(any())).thenAnswer((_) async => 0);
    when(() => mockPrefRepo.setInt(any(), any())).thenAnswer((_) async => {});
  });

  group('MemberNotifier Integrity Tests', () {
    test('Recovery: Rebuilds snapshots in batch from events', () async {
      final now = DateTime(2026, 1, 1);
      final event = DomainEvent(
        entityId: 'M1',
        eventType: EventType.memberCreated,
        deviceId: 'test-device',
        deviceTimestamp: now,
        payload: {
          'memberId': 'M1',
          'name': 'Ravi Kumar',
          'joinDate': now.toIso8601String(),
        },
      );

      // Simulate existing events in repo
      when(() => mockEventRepo.getEventsSince(any())).thenAnswer((_) async => [event]);
      when(() => mockMemberRepo.getMembers(any())).thenAnswer((_) async => []);
      when(() => mockEventRepo.getEventsForEntities(['M1'])).thenAnswer((_) async => [event]);
      when(() => mockMemberRepo.upsertMembers(any())).thenAnswer((_) async => {});

      // getAllMembers called at end of reconcile
      when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => [
        MemberSnapshot.fromPayload('M1', event.payload)
      ]);

      final notifier = MemberNotifier(
        mockEventRepo,
        mockMemberRepo,
        mockPlanRepo,
        mockPrefRepo,
        mockClock,
        mockHmac
      );
      
      // Wait for init/reconcile
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify state is populated
      expect(notifier.state.length, 1);
      expect(notifier.state.first.name, 'Ravi Kumar');

      // Verify upsertMembers was called
      verify(() => mockMemberRepo.upsertMembers(any())).called(1);
    });
  });
}
