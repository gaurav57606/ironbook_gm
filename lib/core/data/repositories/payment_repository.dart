import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart' as db;
import '../local/models/payment_model.dart' as domain;
import '../../providers/base_providers.dart';

import '../local/models/domain_event_model.dart';
import '../../constants/event_payload_keys.dart';

abstract class IPaymentRepository {
  Future<void> upsertPayment(domain.Payment payment);
  Future<domain.Payment?> getPayment(String id);
  Future<List<domain.Payment>> getPaymentsByMember(String memberId);
  Future<List<domain.Payment>> getAllPayments();
  Future<void> applyEvent(DomainEvent event);
  Future<double> getTotalRevenue();
  Future<List<double>> getWeeklyRevenue(DateTime now);
  Future<double> getRevenueBetween(DateTime start, DateTime end);
}

class DriftPaymentRepository implements IPaymentRepository {
  final db.OutboxDatabase _db;

  DriftPaymentRepository(this._db);

  @override
  Future<void> upsertPayment(domain.Payment payment) async {
    debugPrint('[DB] PaymentRepository: Upserting payment ${payment.id} (Invoice: ${payment.invoiceNumber})');
    await _db.into(_db.payments).insertOnConflictUpdate(
      db.PaymentsCompanion.insert(
        id: payment.id,
        memberId: payment.memberId,
        date: payment.date,
        amount: payment.amount,
        method: payment.method,
        reference: Value(payment.reference),
        planId: Value(payment.planId),
        planName: Value(payment.planName),
        invoiceNumber: payment.invoiceNumber,
        durationMonths: Value(payment.durationMonths),
        subtotal: payment.subtotal,
        gstAmount: payment.gstAmount,
        gstRate: Value(payment.gstRate),
        componentsJson: Value(jsonEncode(payment.components.map((c) => {
          'name': c.name,
          'price': c.price,
        }).toList())),
        hmacSignature: Value(payment.hmacSignature ?? ''),
      ),
    );
  }

  @override
  Future<domain.Payment?> getPayment(String id) async {
    final doc = await (_db.select(_db.payments)..where((t) => t.id.equals(id))).getSingleOrNull();
    return doc != null ? domain.Payment.fromDrift(doc) : null;
  }

  @override
  Future<List<domain.Payment>> getPaymentsByMember(String memberId) async {
    final docs = await (_db.select(_db.payments)..where((t) => t.memberId.equals(memberId))).get();
    return docs.map((d) => domain.Payment.fromDrift(d)).toList();
  }

  @override
  Future<List<domain.Payment>> getAllPayments() async {
    final docs = await _db.select(_db.payments).get();
    return docs.map((d) => domain.Payment.fromDrift(d)).toList();
  }

  @override
  Future<void> applyEvent(DomainEvent event) async {
    await _db.transaction(() async {
      if (event.eventType == EventType.paymentRecorded) {
        final paymentId = event.payload[EventPayloadKeys.paymentId] as String?;
        if (paymentId != null) {
          debugPrint('[DB] PaymentRepository: Applying paymentRecorded event for $paymentId');
          final payment = domain.Payment.fromPayload(paymentId, event.payload, event.deviceTimestamp);
          await upsertPayment(payment);
        }
      }
    });
  }

  @override
  Future<double> getTotalRevenue() async {
    final amountExp = _db.payments.amount.sum();
    final query = _db.selectOnly(_db.payments)..addColumns([amountExp]);
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  @override
  Future<List<double>> getWeeklyRevenue(DateTime now) async {
    final List<double> weekly = List.filled(7, 0.0);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // We fetch only recent payments and group in Dart for simplicity,
    // which is still much faster than replaying the whole event log.
    final docs = await (_db.select(_db.payments)
      ..where((t) => t.date.isBiggerThanValue(sevenDaysAgo)))
      .get();
    
    for (final doc in docs) {
      final dayIndex = now.difference(doc.date).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        weekly[6 - dayIndex] += doc.amount;
      }
    }
    return weekly;
  }

  @override
  Future<double> getRevenueBetween(DateTime start, DateTime end) async {
    final amountExp = _db.payments.amount.sum();
    final query = _db.selectOnly(_db.payments)
      ..where(_db.payments.date.isBiggerOrEqualValue(start) &
          _db.payments.date.isSmallerOrEqualValue(end))
      ..addColumns([amountExp]);
    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }
}

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftPaymentRepository(db);
});
