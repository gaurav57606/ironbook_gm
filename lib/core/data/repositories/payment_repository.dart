import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart' as db;
import '../local/models/payment_model.dart' as domain;
import '../../providers/base_providers.dart';

import '../local/models/domain_event_model.dart';
import '../../constants/event_payload_keys.dart';

abstract class IPaymentRepository {
  Future<void> upsertPayment(domain.Payment payment);
  Future<void> upsertPayments(List<domain.Payment> payments);
  Future<domain.Payment?> getPayment(String id);
  Future<List<domain.Payment>> getPaymentsByMember(String memberId);
  Future<List<domain.Payment>> getAllPayments();
  Future<void> applyEvent(DomainEvent event);
  Future<void> applyEvents(List<DomainEvent> events);
}

class DriftPaymentRepository implements IPaymentRepository {
  final db.OutboxDatabase _db;

  DriftPaymentRepository(this._db);

  @override
  Future<void> upsertPayment(domain.Payment payment) async {
    await _db.into(_db.payments).insertOnConflictUpdate(
      _toCompanion(payment),
    );
  }

  @override
  Future<void> upsertPayments(List<domain.Payment> payments) async {
    final companions = payments.map((p) => _toCompanion(p)).toList();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.payments, companions);
    });
  }

  db.PaymentsCompanion _toCompanion(domain.Payment payment) {
    return db.PaymentsCompanion.insert(
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
    if (event.eventType == EventType.paymentRecorded) {
      final paymentId = event.payload[EventPayloadKeys.paymentId] as String?;
      if (paymentId != null) {
        final payment = domain.Payment.fromPayload(paymentId, event.payload, event.deviceTimestamp);
        await upsertPayment(payment);
      }
    }
  }

  @override
  Future<void> applyEvents(List<DomainEvent> events) async {
    final payments = <domain.Payment>[];
    for (final event in events) {
      if (event.eventType == EventType.paymentRecorded) {
        final paymentId = event.payload[EventPayloadKeys.paymentId] as String?;
        if (paymentId != null) {
          payments.add(domain.Payment.fromPayload(paymentId, event.payload, event.deviceTimestamp));
        }
      }
    }
    if (payments.isNotEmpty) {
      await upsertPayments(payments);
    }
  }
}

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftPaymentRepository(db);
});
