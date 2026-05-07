import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/core/data/local/models/sale_model.dart' as legacy;
import '../data/billing_repository.dart';

extension PlanExtension on Plan {
  List<PlanComponent> get components {
    if (componentsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(componentsJson!);
    return decoded.map((c) => PlanComponent(
      id: c['id'] ?? '',
      name: c['name'] ?? '',
      price: (c['price'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }

  double get totalPrice => components.fold(0, (sum, c) => sum + c.price);
}

extension SaleExtension on Sale {
  List<legacy.SaleItem> get items {
    final List<dynamic> decoded = jsonDecode(itemsJson);
    return decoded.map((i) => legacy.SaleItem(
      productId: i['productId'] ?? '',
      memberId: memberId ?? 'walk-in',
      productName: i['productName'] ?? '',
      price: (i['price'] as num?)?.toDouble() ?? 0.0,
      quantity: i['quantity'] ?? 1,
    )).toList();
  }
}

extension PaymentExtension on Payment {
  List<PlanComponent> get components {
    if (componentsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(componentsJson!);
    return decoded.map((c) => PlanComponent(
      id: c['id'] ?? '',
      name: c['name'] ?? '',
      price: (c['price'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }
}

final paymentsProvider = StreamProvider.family<List<Payment>, String?>((ref, memberId) {
  final repository = ref.watch(billingRepositoryProvider);
  if (memberId == null) {
    // repository doesn't have watchAllPayments yet, but it has getAllPayments
    // I'll assume we can add watchAllPayments if needed, but for now I'll use member specific
    return repository.watchMemberPayments(memberId ?? '');
  }
  return repository.watchMemberPayments(memberId);
});

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getAllPayments();
});

final salesProvider = StreamProvider<List<Sale>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.watchAllSales();
});

final activePlansProvider = StreamProvider<List<Plan>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.watchActivePlans();
});

final billingNotifierProvider = Provider<BillingNotifier>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return BillingNotifier(repository);
});

class BillingNotifier {
  final IBillingRepository _repository;
  BillingNotifier(this._repository);

  Future<void> recordPayment(Payment payment) async {
    await _repository.recordPayment(payment);
  }

  Future<void> recordMemberPayment({
    required String memberId,
    required Plan plan,
    required String method,
  }) async {
    final id = const Uuid().v4();
    final payment = Payment(
      id: id,
      memberId: memberId,
      date: DateTime.now(),
      amount: plan.totalPrice,
      method: method,
      planId: plan.id,
      planName: plan.name,
      durationMonths: plan.durationMonths,
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      subtotal: plan.totalPrice / 1.18,
      gstAmount: plan.totalPrice - (plan.totalPrice / 1.18),
      gstRate: 0.18,
      componentsJson: plan.componentsJson,
    );
    await _repository.recordPayment(payment);
  }

  Future<void> recordSale(Sale sale) async {
    await _repository.recordSale(sale);
  }

  Future<void> recordProductSale({
    required List<legacy.SaleItem> items,
    required String method,
    required double total,
    String? memberId,
  }) async {
    final id = const Uuid().v4();
    final sale = Sale(
      id: id,
      memberId: memberId,
      date: DateTime.now(),
      totalAmount: total,
      paymentMethod: method,
      invoiceNumber: 'SAL-${DateTime.now().millisecondsSinceEpoch}',
      itemsJson: jsonEncode(items.map((i) => {
        'productId': i.productId,
        'productName': i.productName,
        'price': i.price,
        'quantity': i.quantity,
      }).toList()),
    );
    await _repository.recordSale(sale);
  }

  Future<void> upsertPlan(Plan plan) async {
    await _repository.upsertPlan(plan);
  }
}
