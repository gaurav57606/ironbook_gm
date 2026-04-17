import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'local/models/member_snapshot_model.dart';
import 'local/models/plan_model.dart';
import 'local/models/plan_component_model.dart';
import 'local/models/owner_profile_model.dart';
import 'local/models/app_settings_model.dart';

class SeedData {
  static const _uuid = Uuid();

  static Future<void> seedIfEmpty() async {
    final plansBox = Hive.box<Plan>('plans');
    final membersBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    final ownerBox = Hive.box<OwnerProfile>('owner');
    final settingsBox = Hive.box<AppSettings>('settings');

    if (plansBox.isNotEmpty) return; // Already seeded

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

    await plansBox.putAll({
      monthly.id: monthly,
      quarterly.id: quarterly,
      halfYearly.id: halfYearly,
      annual.id: annual,
    });

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
      await membersBox.put(m.memberId, m);
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
