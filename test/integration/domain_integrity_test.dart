import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ironbook_test');
    Hive.init(tempDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DomainEventAdapter());
      Hive.registerAdapter(MemberSnapshotAdapter());
      Hive.registerAdapter(PaymentAdapter());
      Hive.registerAdapter(PlanAdapter());
      Hive.registerAdapter(PlanComponentAdapter());
      Hive.registerAdapter(PlanComponentSnapshotAdapter());
      Hive.registerAdapter(InvoiceSequenceAdapter());
      Hive.registerAdapter(AppSettingsAdapter());
    }

    HmacService.setKeyForTest('dGhpcy1pcy1hLXZlcnktc2VjdXJlLTMyLWJ5dGUta2V5');

    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FrozenClock(DateTime(2024, 3, 25))),
      ],
    );

    // Open boxes needed for the test
    await Hive.openBox<DomainEvent>('events');
    await Hive.openBox<MemberSnapshot>('snapshots');
    final plansBox = await Hive.openBox<Plan>('plans');
    await Hive.openBox<AppSettings>('settings');

    // Seed a test plan
    await plansBox.put('plan-1', Plan(
      id: 'plan-1',
      name: 'Monthly',
      durationMonths: 1,
      components: [PlanComponent(id: 'comp-1', name: 'Gym Access', price: 1298)],
    ));
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
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
    final snapshotBox = Hive.box<MemberSnapshot>('snapshots');
    expect(snapshotBox.length, 1);
    expect(snapshotBox.values.first.name, 'Integration Test');

    final eventBox = Hive.box<DomainEvent>('events');
    expect(eventBox.length, 2);
    expect(eventBox.values.any((e) => e.eventType == 'MEMBER_CREATED'), isTrue);
    expect(eventBox.values.any((e) => e.eventType == 'PAYMENT_RECEIVED'), isTrue);
    expect(eventBox.values.every((e) => e.hmacSignature.isNotEmpty), isTrue);

    // 4. Verify HMAC Integrity on Persisted Events
    for (final event in eventBox.values) {
      final isValid = await HmacService.verify(event);
      expect(isValid, isTrue, reason: 'Event ${event.eventType} should have valid HMAC');
    }
  });
}
