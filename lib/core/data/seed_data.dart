import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:flutter/foundation.dart';
import 'local/models/product_model.dart';
import 'local/models/domain_event_model.dart';
import 'local/models/member_snapshot_model.dart';
import 'local/models/plan_model.dart';
import 'local/models/plan_component_model.dart';
import 'local/models/owner_profile_model.dart';
import 'local/models/app_settings_model.dart';
import 'repositories/event_repository.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';

class SeedData {
  static const _uuid = Uuid();

  static Future<void> seedIfEmpty(ProviderContainer container) async {
    final plansBox = Hive.box<Plan>('plans');
    final membersBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    final ownerBox = Hive.box<OwnerProfile>('owner');
    final settingsBox = Hive.box<AppSettings>('settings');
    final productBox = Hive.box<Product>('products');
    final eventRepo = container.read(eventRepositoryProvider);
    final hmac = container.read(hmacServiceProvider);
    final pinService = container.read(pinServiceProvider);
    final storage = container.read(appSecureStorageProvider);
    const deviceId = 'seed-device';

    bool needsSeeding = plansBox.isEmpty;
    if (!needsSeeding) {
      final firstPlan = plansBox.values.first;
      if (firstPlan.hmacSignature == null) {
        debugPrint('SeedData: Found invalid data (no signatures). Re-seeding...');
        needsSeeding = true;
        await plansBox.clear();
        await membersBox.clear();
        await ownerBox.clear();
        await settingsBox.clear();
        await productBox.clear();
      }
    }

    if (!needsSeeding) return; 

    // Ensure PIN is set for testing
    await pinService.setPin('1234');
    await storage.write(key: 'onboarding_done', value: 'true');

    // Owner profile
    final owner = OwnerProfile(
      gymName: "Raj's Fitness",
      ownerName: 'Rajesh Kumar',
      phone: '+91 98765 00000',
      address: 'Sector 14, Gurugram, Haryana',
      gstin: '07ABCDE1234F1Z5',
      bankName: 'HDFC',
      accountNumber: '1234567890',
      ifsc: 'HDFC0001234',
    );
    await ownerBox.put('owner', owner);

    // Settings
    await settingsBox.put('app_settings', AppSettings());

    // Plans
    final gymAccess = PlanComponent(id: _uuid.v4(), name: 'Gym Access', price: 800);
    final locker = PlanComponent(id: _uuid.v4(), name: 'Locker', price: 150);
    final steam = PlanComponent(id: _uuid.v4(), name: 'Steam Room', price: 150);

    final monthly = Plan(
      id: _uuid.v4(),
      name: 'Monthly',
      durationMonths: 1,
      components: [gymAccess, locker, steam],
      active: true,
    );

    final quarterly = Plan(
      id: _uuid.v4(),
      name: 'Quarterly',
      durationMonths: 3,
      components: [gymAccess, locker, steam],
      active: true,
    );

    final halfYearly = Plan(
      id: _uuid.v4(),
      name: 'Half-Yearly',
      durationMonths: 6,
      components: [gymAccess, locker, steam],
      active: true,
    );

    final annual = Plan(
      id: _uuid.v4(),
      name: 'Annual',
      durationMonths: 12,
      components: [gymAccess, locker, steam],
      active: true,
    );

    final plans = [monthly, quarterly, halfYearly, annual];
    for (final p in plans) {
      final signature = await hmac.signSnapshot(p.id, p.toFirestore());
      p.hmacSignature = signature;
      await plansBox.put(p.id, p);
    }

    // Products
    final products = [
      Product(id: 'p1', name: 'Whey Protein', price: 120, category: 'Supplements', iconCodePoint: 0xe293),
      Product(id: 'p2', name: 'BCAA Powder', price: 80, category: 'Supplements', iconCodePoint: 0xe2e3),
      Product(id: 'p3', name: 'Pre-Workout', price: 95, category: 'Supplements', iconCodePoint: 0xe113),
      Product(id: 'p4', name: 'Creatine', price: 70, category: 'Supplements', iconCodePoint: 0xe54d),
      Product(id: 'p5', name: 'IronBook Tee', price: 45, category: 'Merch', iconCodePoint: 0xe170),
      Product(id: 'p6', name: 'Steel Shaker', price: 25, category: 'Merch', iconCodePoint: 0xe3ab),
    ];
    for (final p in products) {
      await productBox.put(p.id, p);
    }

    // Seed initial event to Drift Outbox
    final seedEvent = DomainEvent(
      entityId: 'gym-plans',
      eventType: EventType.plansUpdated,
      deviceId: deviceId,
      deviceTimestamp: DateTime.now(),
      payload: {'plans': plans.map((p) => p.toFirestore()).toList()},
    );
    await eventRepo.persist(seedEvent);

    // Members
    final now = DateTime.now();
    final members = [
      _makeMember('Karan Sharma', '9876543210', monthly.id, monthly.name,
        now.subtract(const Duration(days: 60)), now),
      _makeMember('Pooja Singh', '9876543211', quarterly.id, quarterly.name,
        now.subtract(const Duration(days: 95)), now.subtract(const Duration(days: 3))),
      _makeMember('Nitin Verma', '9876543212', monthly.id, monthly.name,
        now.subtract(const Duration(days: 38)), now.subtract(const Duration(days: 7))),
      _makeMember('Priya Agarwal', '9876543213', monthly.id, monthly.name,
        now.subtract(const Duration(days: 27)), now.add(const Duration(days: 3))),
      _makeMember('Arjun Kapoor', '9876543214', halfYearly.id, halfYearly.name,
        now.subtract(const Duration(days: 175)), now.add(const Duration(days: 5))),
      _makeMember('Rohit Mehta', '9876543215', annual.id, annual.name,
        now.subtract(const Duration(days: 147)), now.add(const Duration(days: 218))),
      _makeMember('Sneha Nair', '9876543216', monthly.id, monthly.name,
        now.subtract(const Duration(days: 18)), now.add(const Duration(days: 12))),
    ];

    for (final m in members) {
      final signature = await hmac.signSnapshot(m.memberId, m.toFirestore());
      final signed = m.copyWith(hmacSignature: signature);
      await membersBox.put(signed.memberId, signed);
    }
  }

  static MemberSnapshot _makeMember(String name, String phone, String planId, String planName,
    DateTime joinDate, DateTime expiryDate) {
    return MemberSnapshot(
      memberId: _uuid.v4(),
      name: name,
      phone: phone,
      planId: planId,
      planName: planName,
      joinDate: joinDate,
      expiryDate: expiryDate,
      totalPaid: 0,
      paymentIds: [],
      joinDateHistory: [],
      archived: false,
      lastUpdated: DateTime.now(),
    );
  }
}











