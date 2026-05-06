import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';

import '../test_helper.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    await TestHelper.setupHive('integrity');

    HmacService.setKeyForTest('dGhpcy1pcy1hLXZlcnktc2VjdXJlLTMyLWJ5dGUta2V5');

    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FrozenClock(DateTime(2024, 3, 25))),
      ],
    );

    final plansBox = Hive.box<Plan>('plans');

    // Seed a test plan
    await plansBox.put('plan-1', Plan(
      id: 'plan-1',
      name: 'Monthly',
      durationMonths: 1,
      components: [PlanComponent(id: 'comp-1', name: 'Gym Access', price: 1298)],
    ));
  });

  tearDown(() async {
    await TestHelper.cleanHive();
  });

  test('Full Integrity Flow: Add Member -> Persist -> EventBus -> Notifier Update', () async {
    final notifier = container.read(membersProvider.notifier);
    
    // 1. Trigger Action
    await notifier.addMember(
      name: 'Integration Test',
      phone: '12345',
      planId: 'plan-1',
      joinDate: DateTime(2024, 3, 25),
    );

    // Give time for EventBus and SnapshotBuilder to complete
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. Verify State in Notifier
    final members = container.read(membersProvider);
    expect(members.length, 1);
    expect(members.first.name, 'Integration Test');

    // 3. Verify Local Persistence (Hive)
    final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    expect(snapshotBox.length, 1);
    final persistedSnapshot = await snapshotBox.getAt(0);
    expect(persistedSnapshot?.name, 'Integration Test');

    final eventBox = Hive.lazyBox<DomainEvent>('events');
    expect(eventBox.length, 1); // Only MEMBER_CREATED from addMember
    final firstEvent = await eventBox.getAt(0);
    expect(firstEvent?.eventType, EventType.memberCreated);
    expect(firstEvent?.hmacSignature.isNotEmpty, isTrue);

    // 4. Verify HMAC Integrity on Persisted Events
    for (int i = 0; i < eventBox.length; i++) {
      final event = await eventBox.getAt(i);
      if (event != null) {
        final isValid = await HmacService.verify(event);
        expect(isValid, isTrue, reason: 'Event ${event.eventType} should have valid HMAC');
      }
    }
  });
}


