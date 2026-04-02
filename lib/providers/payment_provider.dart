import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../data/local/models/payment_model.dart';
import '../data/local/models/invoice_sequence.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/local/models/plan_model.dart';
import '../data/repositories/event_repository.dart';

class PaymentNotifier extends StateNotifier<List<Payment>> {
  final Box<Payment> _paymentBox;
  final Box<InvoiceSequence> _sequenceBox;
  final IEventRepository _eventRepo;
  final String _deviceId;

  PaymentNotifier(
    this._paymentBox,
    this._sequenceBox,
    this._eventRepo,
    this._deviceId,
  ) : super([]) {
    _loadPayments();
  }

  void _loadPayments() {
    state = _paymentBox.values.toList().reversed.toList();
  }

  Future<Payment> recordMemberPayment({
    required String memberId,
    required Plan plan,
    required String method,
    String? reference,
  }) async {
    // 1. Get/Create Invoice Sequence
    var sequence = _sequenceBox.get('default');
    if (sequence == null) {
      sequence = InvoiceSequence(prefix: 'INV-${DateTime.now().year}-');
      await _sequenceBox.put('default', sequence);
    }

    final invoiceNumber = sequence.nextInvoiceId;
    
    // 2. Increment Sequence
    sequence.nextNumber++;
    await sequence.save();

    // 3. Calculate GST (Assume 18% inclusive for matching the UI design precision)
    // Total = Subtotal + (Subtotal * 0.18) => Total = Subtotal * 1.18
    // Subtotal = Total / 1.18
    final total = plan.totalPrice;
    final subtotal = total / 1.18;
    const gstRate = 0.18;
    final gstAmount = total - subtotal;

    // 4. Create Payment Record
    final payment = Payment(
      id: const Uuid().v4(),
      memberId: memberId,
      date: DateTime.now(),
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

    // 5. Persist Locally
    await _paymentBox.put(payment.id, payment);
    state = [payment, ...state];

    // 6. Emit Domain Event for Sync
    final event = DomainEvent(
      entityId: payment.id,
      eventType: 'PAYMENT_RECORDED',
      deviceId: _deviceId,
      payload: {
        'memberId': memberId,
        'amount': total,
        'method': method,
        'invoiceNumber': invoiceNumber,
        'planId': plan.id,
        'timestamp': payment.date.toIso8601String(),
      },
    );
    await _eventRepo.persist(event);

    return payment;
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
  
  const deviceId = 'device-billing-v1';

  return PaymentNotifier(paymentBox, sequenceBox, eventRepo, deviceId);
});

final latestPaymentForMemberProvider = Provider.family<Payment?, String>((ref, memberId) {
  final payments = ref.watch(paymentsProvider);
  return payments.firstWhereOrNull((p) => p.memberId == memberId);
});
