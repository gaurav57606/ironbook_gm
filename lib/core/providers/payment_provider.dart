import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'dart:async';

import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';

class PaymentNotifier extends StateNotifier<List<Payment>> {
  final ISequenceRepository _sequenceRepo;
  final IEventRepository _eventRepo;
  final IPaymentRepository _paymentRepo;
  final IMemberRepository _memberRepo;
  final IClock _clock;
  final HmacService _hmac;
  String _deviceId = 'device-loading';
  
  Completer<void>? _syncLock;
 
  PaymentNotifier(
    this._sequenceRepo,
    this._eventRepo,
    this._paymentRepo,
    this._memberRepo,
    this._clock,
    this._hmac,
  ) : super([]) {
    _init();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();

    // 1. Listen for payment events
    _eventRepo.watch().listen((event) async {
      if (event.eventType == EventType.paymentRecorded) {
        await _paymentRepo.applyEvent(event);
        final paymentId = event.payload[EventPayloadKeys.paymentId] as String?;
        if (paymentId != null) {
          final payment = await _paymentRepo.getPayment(paymentId);
          if (payment != null) {
            state = [payment, ...state];
          }
        }
      }
    });

    // 2. Load all payments from Drift
    state = (await _paymentRepo.getAllPayments()).reversed.toList();

    // 3. Reconcile
    await _reconcilePayments();
  }

  Future<void> _reconcilePayments() async {
    final recentEvents = await _eventRepo.getAll();
    final paymentEvents = recentEvents.where((e) => e.eventType == EventType.paymentRecorded).toList();
    
    if (paymentEvents.isEmpty) return;

    final existingIds = state.map((p) => p.id).toSet();
    final missingEvents = paymentEvents.where((e) {
      final paymentId = e.payload[EventPayloadKeys.paymentId] as String?;
      return paymentId != null && !existingIds.contains(paymentId);
    }).toList();

    if (missingEvents.isEmpty) return;

    debugPrint('PaymentNotifier: Reconciling ${missingEvents.length} missing payments in batches');

    // Batch process missing payments in chunks of 50 to avoid long locks
    for (var i = 0; i < missingEvents.length; i += 50) {
      final batch = missingEvents.skip(i).take(50).toList();
      await _paymentRepo.applyEvents(batch);
    }

    state = (await _paymentRepo.getAllPayments()).reversed.toList();
  }

  @visibleForTesting
  set debugState(List<Payment> payments) => state = payments;

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
      
      // 1. Get Next Invoice Number via Drift
      final prefix = 'INV-${now.year}-';
      final invoiceNumber = await _sequenceRepo.getNextInvoiceNumber(prefix);

      // 3. Calculate GST (Assume 18% inclusive)
      final total = plan.totalPrice;
      final subtotal = total / 1.18;
      const gstRate = 0.18;
      final gstAmount = total - subtotal;

      // 4. Create Payment Record (Deterministic UTC)
      final member = await _memberRepo.getMember(memberId);
      
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

      // 5. Emit Domain Event FIRST
      final event = DomainEvent(
        entityId: memberId, 
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
      
      await _eventRepo.persist(event);

      // 6. Persist Cache in Drift
      await _paymentRepo.upsertPayment(payment);
      
      // Optimized: Avoid redundant fetch, use local object but ensure it matches repo state
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

final paymentsProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>((ref) {
  final sequenceRepo = ref.watch(sequenceRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final memberRepo = ref.watch(memberRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  
  return PaymentNotifier(sequenceRepo, eventRepo, paymentRepo, memberRepo, clock, hmac);
});

final latestPaymentForMemberProvider = Provider.family<Payment?, String>((ref, memberId) {
  final payments = ref.watch(paymentsProvider);
  return payments.firstWhereOrNull((p) => p.memberId == memberId);
});
