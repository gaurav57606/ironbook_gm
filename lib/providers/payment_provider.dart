import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../data/local/models/payment_model.dart';
import '../data/local/models/invoice_sequence.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/local/models/plan_model.dart';
import '../data/repositories/event_repository.dart';
import '../core/utils/clock.dart';
import '../core/services/hmac_service.dart';
import '../providers/base_providers.dart';
import '../constants/event_payload_keys.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../core/utils/date_utils.dart';
import 'dart:async';

class PaymentNotifier extends StateNotifier<List<Payment>> {
  final Box<Payment> _paymentBox;
  final Box<InvoiceSequence> _sequenceBox;
  final IEventRepository _eventRepo;
  final IClock _clock;
  final HmacService _hmac;
  String _deviceId = 'device-loading';
  
  Completer<void>? _syncLock;
 
  PaymentNotifier(
    this._paymentBox,
    this._sequenceBox,
    this._eventRepo,
    this._clock,
    this._hmac,
  ) : super([]) {
    _init();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();
    _loadPayments();
    await _reconcilePayments();
  }

  Future<void> _reconcilePayments() async {
    final allEvents = await _eventRepo.getAll();
    final paymentEvents = allEvents.where((e) => e.eventType == EventType.paymentRecorded).toList();
    
    bool updatedAny = false;
    for (final event in paymentEvents) {
      final paymentId = event.payload[EventPayloadKeys.paymentId] as String?;
      if (paymentId == null) continue;

      if (!_paymentBox.containsKey(paymentId)) {
        final payment = Payment.fromPayload(paymentId, event.payload, event.deviceTimestamp);
        await _paymentBox.put(paymentId, payment);
        updatedAny = true;
      }
    }

    if (updatedAny) {
      _loadPayments();
    }
  }

  @visibleForTesting
  set debugState(List<Payment> payments) => state = payments;

  void _loadPayments() {
    state = _paymentBox.values.toList().reversed.toList();
  }

  Future<Payment> recordMemberPayment({
    required String memberId,
    required Plan plan,
    required String method,
    String? reference,
  }) async {
    // Audit Check 1.8: Atomic Invoice Sequence
    while (_syncLock != null) {
      await _syncLock!.future;
    }
    _syncLock = Completer<void>();

    try {
      final now = _clock.now;
      
      // 1. Get/Create Invoice Sequence
      var sequence = _sequenceBox.get('default');
      if (sequence == null) {
        sequence = InvoiceSequence(prefix: 'INV-${now.year}-');
      }

      final invoiceNumber = sequence.nextInvoiceId;
      
      // 2. Increment Sequence
      sequence.nextNumber++;
      await _sequenceBox.put('default', sequence);

      // 3. Calculate GST (Assume 18% inclusive)
      final total = plan.totalPrice;
      final subtotal = total / 1.18;
      const gstRate = 0.18;
      final gstAmount = total - subtotal;

      // 4. Create Payment Record (Deterministic UTC)
      final snapshotsBox = Hive.lazyBox<MemberSnapshot>('snapshots');
      final member = await snapshotsBox.get(memberId);
      
      // Calculate new expiry
      DateTime baseDate = member?.expiryDate ?? now;
      if (baseDate.isBefore(now)) baseDate = now;
      final newExpiryDate = AppDateUtils.addMonths(baseDate, plan.durationMonths);

      final payment = Payment(
        id: const Uuid().v4(),
        memberId: memberId,
        date: now,
        amount: total,
        method: method,
        reference: reference,
        planId: plan.id,
        planName: plan.name,
        durationMonths: plan.durationMonths,
        invoiceNumber: invoiceNumber,
        subtotal: subtotal,
        gstAmount: gstAmount,
        gstRate: gstRate,
        components: plan.components.map((c) => PlanComponentSnapshot(
          name: c.name,
          price: c.price,
        )).toList(),
      );

      // 5. Emit Domain Event FIRST (Enforce Outbox-First Rule)
      final event = DomainEvent(
        entityId: memberId, // Target is the member for state updates
        eventType: EventType.paymentRecorded,
        deviceId: _deviceId,
        deviceTimestamp: now,
        payload: {
          EventPayloadKeys.memberId: memberId,
          EventPayloadKeys.paymentId: payment.id,
          EventPayloadKeys.amount: total,
          EventPayloadKeys.paymentMethod: method,
          EventPayloadKeys.invoiceNumber: invoiceNumber,
          EventPayloadKeys.planId: plan.id,
          EventPayloadKeys.planName: plan.name,
          EventPayloadKeys.durationMonths: plan.durationMonths,
          EventPayloadKeys.newExpiry: newExpiryDate.toUtc().toIso8601String(),
          EventPayloadKeys.updatedAt: now.toUtc().toIso8601String(),
        },
      );
      
      // This will throw if the Drift Outbox write fails, preventing local Hive corruption
      await _eventRepo.persist(event);

      // 6. Persist Cache Locally
      await _paymentBox.put(payment.id, payment);
      state = [payment, ...state];

      return payment;
    } finally {
      final lock = _syncLock;
      _syncLock = null;
      lock?.complete();
    }
  }

  Payment? getLatestForMember(String memberId) {
    return state.firstWhereOrNull((p) => p.memberId == memberId);
  }
}

final paymentBoxProvider = Provider<Box<Payment>>((ref) => Hive.box<Payment>('payments'));
final sequenceBoxProvider = Provider<Box<InvoiceSequence>>((ref) => Hive.box<InvoiceSequence>('invoice_sequences'));

final paymentsProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>((ref) {
  final paymentBox = ref.watch(paymentBoxProvider);
  final sequenceBox = ref.watch(sequenceBoxProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  
  return PaymentNotifier(paymentBox, sequenceBox, eventRepo, clock, hmac);
});

final latestPaymentForMemberProvider = Provider.family<Payment?, String>((ref, memberId) {
  final payments = ref.watch(paymentsProvider);
  return payments.firstWhereOrNull((p) => p.memberId == memberId);
});
