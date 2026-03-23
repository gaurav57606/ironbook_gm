import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/local/models/payment_model.dart';
import '../data/local/models/plan_model.dart';
import '../data/local/models/app_settings_model.dart';
import '../core/utils/invoice_number.dart';
import '../core/services/hmac_service.dart';

final membersProvider = StateNotifierProvider<MemberNotifier, List<MemberSnapshot>>((ref) {
  return MemberNotifier();
});

class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final String _deviceId = 'device-${const Uuid().v4().substring(0, 8)}';

  MemberNotifier() : super([]) {
    _init();
  }

  void _init() {
    if (!Hive.isBoxOpen('snapshots')) return;
    final box = Hive.box<MemberSnapshot>('snapshots');
    state = box.values.toList();
    
    // Listen for changes
    box.listenable().addListener(() {
      state = box.values.toList();
    });
  }

  Future<void> addMember({
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
    String? method,
  }) async {
    final memberId = const Uuid().v4();
    final now = DateTime.now();
    
    // 1. Fetch Plan & Settings
    final plansBox = Hive.box<Plan>('plans');
    final settingsBox = Hive.box<AppSettings>('settings');
    
    final plan = plansBox.get(planId);
    final settings = settingsBox.get('settings', defaultValue: AppSettings())!;
    
    if (plan == null) throw Exception('Plan not found');

    // 2. Billing Calculations
    final subtotal = plan.totalPrice;
    final gstAmount = (subtotal * settings.gstRate) / 100;
    final totalAmount = subtotal + gstAmount;
    final expiryDate = joinDate.add(Duration(days: plan.durationMonths * 30));

    // 3. Generate Invoice Number
    final invoiceNumber = InvoiceNumberGenerator.next(now.year);

    // 4. Create Payment object
    final paymentId = const Uuid().v4();
    final payment = Payment(
      id: paymentId,
      memberId: memberId,
      date: now,
      amount: totalAmount,
      method: method ?? 'Cash',
      planId: planId,
      planName: plan.name,
      components: plan.components.map((c) => PlanComponentSnapshot(name: c.name, price: c.price)).toList(),
      invoiceNumber: invoiceNumber,
      subtotal: subtotal,
      gstAmount: gstAmount,
      gstRate: settings.gstRate,
      durationMonths: plan.durationMonths,
    );

    // 5. Create Domain Events
    final memberEvent = DomainEvent(
      entityId: memberId,
      eventType: 'MEMBER_CREATED',
      deviceId: _deviceId,
      payload: {
        'memberId': memberId,
        'name': name,
        'phone': phone,
        'planId': planId,
        'planName': plan.name,
        'joinDate': joinDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
      },
    );
    HmacService.sign(memberEvent);

    final paymentEvent = DomainEvent(
      entityId: paymentId,
      eventType: 'PAYMENT_RECEIVED',
      deviceId: _deviceId,
      payload: {
        'paymentId': paymentId,
        'memberId': memberId,
        'amount': totalAmount,
        'invoiceNumber': invoiceNumber,
        'planId': planId,
      },
    );
    HmacService.sign(paymentEvent);

    // 6. Create Snapshot
    final snapshot = MemberSnapshot(
      memberId: memberId,
      name: name,
      phone: phone,
      joinDate: joinDate,
      planId: planId,
      planName: plan.name,
      expiryDate: expiryDate,
      totalPaid: totalAmount,
      paymentIds: [paymentId],
    );

    // 7. Persist to Hive
    final eventBox = Hive.box<DomainEvent>('events');
    final snapshotBox = Hive.box<MemberSnapshot>('snapshots');
    final paymentBox = Hive.box<Payment>('payments');
    
    await eventBox.addAll([memberEvent, paymentEvent]);
    await paymentBox.put(paymentId, payment);
    await snapshotBox.put(memberId, snapshot);
  }

  Future<void> renewMember({
    required String memberId,
    required String planId,
    required String method,
  }) async {
    final now = DateTime.now();
    
    final snapshotsBox = Hive.box<MemberSnapshot>('snapshots');
    final plansBox = Hive.box<Plan>('plans');
    final settingsBox = Hive.box<AppSettings>('settings');
    final paymentsBox = Hive.box<Payment>('payments');
    final eventBox = Hive.box<DomainEvent>('events');

    final member = snapshotsBox.get(memberId);
    final plan = plansBox.get(planId);
    final settings = settingsBox.get('settings', defaultValue: AppSettings())!;

    if (member == null || plan == null) return;

    // 1. Billing Calculations
    final subtotal = plan.totalPrice;
    final gstAmount = (subtotal * settings.gstRate) / 100;
    final totalAmount = subtotal + gstAmount;
    
    // Calculate new expiry (Extend from current expiry if active, or from now if expired)
    DateTime baseDate = member.expiryDate ?? now;
    if (baseDate.isBefore(now)) baseDate = now;
    final newExpiryDate = baseDate.add(Duration(days: plan.durationMonths * 30));

    // 2. Generate Invoice
    final invoiceNumber = InvoiceNumberGenerator.next(now.year);
    final paymentId = const Uuid().v4();
    
    final payment = Payment(
      id: paymentId,
      memberId: memberId,
      date: now,
      amount: totalAmount,
      method: method,
      planId: planId,
      planName: plan.name,
      components: plan.components.map((c) => PlanComponentSnapshot(name: c.name, price: c.price)).toList(),
      invoiceNumber: invoiceNumber,
      subtotal: subtotal,
      gstAmount: gstAmount,
      gstRate: settings.gstRate,
      durationMonths: plan.durationMonths,
    );

    // 3. Update Member
    member.expiryDate = newExpiryDate;
    member.totalPaid += totalAmount;
    member.planId = planId;
    member.planName = plan.name;
    member.paymentIds.add(paymentId);
    member.lastUpdated = now;

    // 4. Events
    final renewEvent = DomainEvent(
      entityId: paymentId,
      eventType: 'MEMBERSHIP_RENEWED',
      deviceId: _deviceId,
      payload: {
        'memberId': memberId,
        'planId': planId,
        'amount': totalAmount,
        'newExpiry': newExpiryDate.toIso8601String(),
        'invoiceNumber': invoiceNumber,
      },
    );
    HmacService.sign(renewEvent);

    // 5. Persist
    await eventBox.add(renewEvent);
    await paymentsBox.put(paymentId, payment);
    await snapshotsBox.put(memberId, member);
  }
}
