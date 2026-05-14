import '../test_helper.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' hide OwnerProfile, Payment, Plan, Sale, Product, InvoiceSequence;
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/shared/utils/event_bus.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';

void main() {
  late ProviderContainer container;
  late OutboxDatabase db;

  setUp(() async {
    // Both are needed for now as some parts might still touch Hive (like Plans)
    await TestHelper.setupHive('integrity');
    db = TestHelper.setupDrift();

    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FakeClock()),
        outboxDatabaseProvider.overrideWithValue(db),
        hmacServiceProvider.overrideWithValue(FakeHmacService()),
        outboxRepositoryProvider.overrideWith((ref) => OutboxRepository(db)),
        memberRepositoryProvider.overrideWithValue(DriftMemberRepository(db, FakeHmacService())),
        eventRepositoryProvider.overrideWith((ref) => DriftEventRepository(db, EventBus(), FakeHmacService(), FakeSyncCoordinator())),
        planRepositoryProvider.overrideWithValue(DriftPlanRepository(db)),
        preferencesRepositoryProvider.overrideWithValue(DriftPreferencesRepository(db)),
      ],
    );

    // Seed a test plan in Drift
    final planRepo = DriftPlanRepository(db);
    await planRepo.upsertPlan(Plan(
      id: 'plan-1',
      name: 'Monthly',
      durationMonths: 1,
      price: 1298,
      components: [PlanComponent(id: 'comp-1', name: 'Gym Access', price: 1298)],
    ));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await TestHelper.cleanHive();
  });

  test('Full Integrity Flow: Add Member -> Drift Persistence -> Event Log', () async {
    final notifier = container.read(membersProvider.notifier);
    
    // 1. Trigger Action
    await notifier.addMember(
      name: 'Integration Test',
      phone: '12345',
      planId: 'plan-1',
      joinDate: DateTime(2025, 1, 1),
    );

    // Give time for async persistence
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Verify State in Notifier
    final members = container.read(membersProvider);
    expect(members.length, 1);
    expect(members.first.name, 'Integration Test');

    // 3. Verify Drift Persistence (Snapshot)
    final memberRepo = DriftMemberRepository(db, FakeHmacService());
    final persistedMember = await memberRepo.getMember(members.first.memberId);
    expect(persistedMember, isNotNull);
    expect(persistedMember!.name, 'Integration Test');

    // 4. Verify Outbox Log
    final outboxRepo = OutboxRepository(db);
    final events = await outboxRepo.getUnsyncedEvents();
    expect(events.any((e) => e.eventType == EventType.memberCreated), isTrue);
    
    // 5. Verify HMAC (using actual service if needed, but FakeHmacService is used in test_helper)
    // In a real integration test, we'd want to test the actual HMAC logic.
    // For now, confirming it was called.
    expect(events.first.hmacSignature, isNotEmpty);
  });
}
