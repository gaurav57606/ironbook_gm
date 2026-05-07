import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

abstract class IBillingRepository {
  // Payments
  Future<void> recordPayment(Payment payment);
  Future<List<Payment>> getMemberPayments(String memberId);
  Stream<List<Payment>> watchMemberPayments(String memberId);
  Future<List<Payment>> getAllPayments();

  // Sales
  Future<void> recordSale(Sale sale);
  Future<List<Sale>> getAllSales();
  Stream<List<Sale>> watchAllSales();

  // Plans
  Future<void> upsertPlan(Plan plan);
  Future<List<Plan>> getActivePlans();
  Stream<List<Plan>> watchActivePlans();
  Future<Plan?> getPlanById(String id);
}

class BillingRepository implements IBillingRepository {
  final OutboxDatabase _db;

  BillingRepository(this._db);

  @override
  Future<void> recordPayment(Payment payment) async {
    await _db.into(_db.payments).insertOnConflictUpdate(payment);
  }

  @override
  Future<List<Payment>> getMemberPayments(String memberId) async {
    return (_db.select(_db.payments)..where((t) => t.memberId.equals(memberId))).get();
  }

  @override
  Stream<List<Payment>> watchMemberPayments(String memberId) {
    return (_db.select(_db.payments)..where((t) => t.memberId.equals(memberId))).watch();
  }

  @override
  Future<List<Payment>> getAllPayments() async {
    return _db.select(_db.payments).get();
  }

  @override
  Future<void> recordSale(Sale sale) async {
    await _db.into(_db.sales).insertOnConflictUpdate(sale);
  }

  @override
  Future<List<Sale>> getAllSales() async {
    return _db.select(_db.sales).get();
  }

  @override
  Stream<List<Sale>> watchAllSales() {
    return _db.select(_db.sales).watch();
  }

  @override
  Future<void> upsertPlan(Plan plan) async {
    await _db.into(_db.plans).insertOnConflictUpdate(plan);
  }

  @override
  Future<List<Plan>> getActivePlans() async {
    return (_db.select(_db.plans)..where((t) => t.active.equals(true))).get();
  }

  @override
  Stream<List<Plan>> watchActivePlans() {
    return (_db.select(_db.plans)..where((t) => t.active.equals(true))).watch();
  }

  @override
  Future<Plan?> getPlanById(String id) async {
    return (_db.select(_db.plans)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

final billingRepositoryProvider = Provider<IBillingRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return BillingRepository(db);
});
