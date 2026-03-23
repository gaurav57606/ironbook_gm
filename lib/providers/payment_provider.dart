import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/payment_model.dart';

final paymentsProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>((ref) {
  return PaymentNotifier();
});

final latestPaymentForMemberProvider = Provider.family<Payment?, String>((ref, memberId) {
  final payments = ref.watch(paymentsProvider);
  final memberPayments = payments.where((p) => p.memberId == memberId).toList();
  if (memberPayments.isEmpty) return null;
  // Sort by date descending
  memberPayments.sort((a, b) => b.date.compareTo(a.date));
  return memberPayments.first;
});

class PaymentNotifier extends StateNotifier<List<Payment>> {
  PaymentNotifier() : super([]) {
    _init();
  }

  void _init() {
    if (!Hive.isBoxOpen('payments')) return;
    final box = Hive.box<Payment>('payments');
    state = box.values.toList();
    
    box.listenable().addListener(() {
      state = box.values.toList();
    });
  }

  Future<void> addPayment(Payment payment) async {
    final box = Hive.box<Payment>('payments');
    await box.put(payment.id, payment);
  }
}
