import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/settings_repository.dart';
import 'package:ironbook_gm/features/members/data/subscriptions_repository.dart';
import 'package:ironbook_gm/core/utils/subscription_duration_helper.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/services/membership_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/services/notification_service.dart';
import 'dart:async';

import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';

class PaymentNotifier extends StateNotifier<List<Payment>> {
  final db.OutboxDatabase _db;
  final ISequenceRepository _sequenceRepo;
  final IEventRepository _eventRepo;
  final IPaymentRepository _paymentRepo;
  final IMemberRepository _memberRepo;
  final IClock _clock;
  final HmacService _hmac;
  final MembershipService _membership;
  final SyncCoordinator _coordinator;
  final LoggerService _logger;
  final ISettingsRepository _settingsRepo;
  final ISubscriptionsRepository _subscriptionsRepo;
  String _deviceId = 'device-loading';
  Completer<void>? _syncLock;
  StreamSubscription? _eventSubscription;

  PaymentNotifier(
    db.OutboxDatabase db,
    this._sequenceRepo,
    this._eventRepo,
    this._paymentRepo,
    this._memberRepo,
    this._clock,
    this._hmac,
    this._membership,
    this._coordinator,
    this._logger, [
    ISettingsRepository? settingsRepo,
    ISubscriptionsRepository? subscriptionsRepo,
  ]) : _db = db,
       _settingsRepo = settingsRepo ?? DriftSettingsRepository(db),
       _subscriptionsRepo = subscriptionsRepo ?? SubscriptionsRepository(db),
       super([]) {
    _init();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _deviceId = await _hmac.getInstallationId();

      // 1. Listen for payment events (Single Source of Truth)
      _eventSubscription = _eventRepo.watch().listen((event) async {
        if (event.eventType == EventType.paymentRecorded) {
          if (!mounted) return;
          _logger.debug(
            'Processing payment event for ${event.entityId}', 
            category: 'STATE'
          );
          await _paymentRepo.applyEvent(event);
          if (!mounted) return;
          final paymentId = event.payload[EventPayloadKeys.paymentId] as String?;
          if (paymentId != null) {
            final payment = await _paymentRepo.getPayment(paymentId);
            if (payment != null && mounted) {
              final exists = state.any((p) => p.id == payment.id);
              if (!exists) {
                state = [payment, ...state];
              }
            }
          }
        }
      });

      // 2. Load all payments from Drift
      final payments = (await _paymentRepo.getAllPayments()).reversed.toList();
      if (mounted) {
        state = payments;
      }

      // 3. Reconcile
      if (mounted) {
        await _reconcilePayments();
      }
    } catch (e) {
      _logger.warn(
        'Init failed (likely due to disposal/teardown): $e', 
        category: 'STATE'
      );
    }
  }

  Future<void> rebuildCache() async {
    _logger.warn('Manual full payment rebuild triggered.', category: 'DB');
    await _reconcilePayments();
  }

  Future<void> _reconcilePayments() async {
    final recentEvents = await _eventRepo.getAllEvents();
    final paymentEvents = recentEvents.where((e) => e.eventType == EventType.paymentRecorded).toList();
    
    if (paymentEvents.isEmpty) return;

    final existingIds = state.map((p) => p.id).toSet();
    final missingEvents = paymentEvents.where((e) {
      final paymentId = e.payload[EventPayloadKeys.paymentId] as String?;
      return paymentId != null && !existingIds.contains(paymentId);
    }).toList();

    if (missingEvents.isEmpty) return;

    _logger.info(
      'Reconciling ${missingEvents.length} missing payments parallelized', 
      category: 'DB'
    );

    // Apply events in batches of 50
    for (var i = 0; i < missingEvents.length; i += 50) {
      final batch = missingEvents.skip(i).take(50);
      await Future.wait(batch.map((e) => _paymentRepo.applyEvent(e)));
    }

    state = (await _paymentRepo.getAllPayments()).reversed.toList();
  }

  @visibleForTesting
  set debugState(List<Payment> payments) => state = payments;

  // Duplicate Prevention: Track recent payments to avoid rapid double-taps
  final Map<String, DateTime> _recentPayments = {};

  Future<Payment> recordMemberPayment({
    required String memberId,
    required Plan plan,
    required String method,
    String? reference,
    DateTime? date,
  }) async {
    final nowTime = _clock.now;
    
    // Audit Check 6.1: Simple throttle (5 seconds) per member
    final lastAction = _recentPayments[memberId];
    if (lastAction != null && nowTime.difference(lastAction).inSeconds < 5) {
      _logger.warn(
        'Ignoring rapid duplicate payment for $memberId', 
        category: 'BILLING'
      );
      throw Exception('Payment already in progress. Please wait.');
    }
    _recentPayments[memberId] = nowTime;

    // Audit Check 1.8: Atomic Invoice Sequence
    while (_syncLock != null) {
      await _syncLock!.future;
    }
    _syncLock = Completer<void>();

    try {
      final now = date ?? _clock.now;
      
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
      
      // Safety Validation (Audit Check 1.6)
      _membership.validateMembership(
        joinDate: now,
        durationMonths: plan.durationMonths,
      );

      // Calculate new expiry using authoritative SubscriptionDurationHelper
      final settings = await _settingsRepo.getSettings();
      final mode = SubscriptionMode.fromString(settings.subscriptionMode);

      final DateTime baseDate;
      if (member?.expiryDate != null && member!.expiryDate!.isAfter(now)) {
        baseDate = member.expiryDate!;
      } else {
        baseDate = now;
      }

      final calculated = SubscriptionDurationHelper.calculateEndDate(
        startDate: baseDate,
        durationMonths: plan.durationMonths,
        mode: mode,
      );
      final newExpiryDate = DateTime(
        calculated.year,
        calculated.month,
        calculated.day,
        23,
        59,
        59,
        999,
      );

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
          'joinDate': baseDate.toUtc().toIso8601String(),
          EventPayloadKeys.newExpiry: newExpiryDate.toUtc().toIso8601String(),
          EventPayloadKeys.updatedAt: now.toUtc().toIso8601String(),
        },
      );
      
      await _db.transaction(() async {
        _logger.info(
          'Starting recordMemberPayment for $memberId', 
          category: 'TRANSACTION'
        );
        // 5. Emit Domain Event
        await _eventRepo.persist(event);

        // 6. Persist Cache in Drift
        await _paymentRepo.upsertPayment(payment);

        // NEW — create a subscription record first
        final newSub = await _subscriptionsRepo.createSubscription(
          memberId: memberId,
          startDate: baseDate,
          endDate: newExpiryDate,
          planId: plan.id,
          planName: plan.name,
          amountPaid: total,
        );

        // THEN update the member's denormalized cache fields (for fast list queries)
        if (member != null) {
          await _memberRepo.upsertMember(member.copyWith(
            joinDate: newSub.startDate,   // most recent join date
            expiryDate: newSub.endDate,
            planId: newSub.planId,
            planName: newSub.planName,
          ));
        }

        _logger.info(
          'recordMemberPayment transaction complete', 
          category: 'TRANSACTION'
        );
      });
      
      _coordinator.triggerSync();

      // Trigger Local & Cloud Notification for Hub (Live feel)
      await NotificationService.dispatchGymNotification(
        title: 'Payment Recorded',
        body: '₹${payment.amount.toInt()} received from ${member!.name} for ${payment.planName}',
        category: 'payment_received',
        payload: 'member:${payment.memberId}',
      );

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
  final db = ref.watch(outboxDatabaseProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);
  final membership = ref.watch(membershipServiceProvider);
  final logger = ref.watch(loggerProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final subscriptionsRepo = ref.watch(subscriptionsRepositoryProvider);
  
  return PaymentNotifier(
    db,
    sequenceRepo,
    eventRepo,
    paymentRepo,
    memberRepo,
    clock,
    hmac,
    membership,
    coordinator,
    logger,
    settingsRepo,
    subscriptionsRepo,
  );
});

final latestPaymentForMemberProvider = Provider.family<Payment?, String>((ref, memberId) {
  final payments = ref.watch(paymentsProvider);
  return payments.firstWhereOrNull((p) => p.memberId == memberId);
});











