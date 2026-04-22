import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Payment extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String memberId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late String method;

  @HiveField(5)
  String? reference;

  @HiveField(6)
  late String planId;

  @HiveField(7)
  late String planName;

  @HiveField(8)
  late List<PlanComponentSnapshot> components;

  @HiveField(9)
  late String invoiceNumber;

  @HiveField(10)
  late double subtotal;

  @HiveField(11)
  late double gstAmount;

  @HiveField(12)
  late double gstRate;

  @HiveField(13)
  late int durationMonths;

  @HiveField(14)
  String? hmacSignature;

  Payment({
    required this.id,
    required this.memberId,
    required this.date,
    required this.amount,
    required this.method,
    this.reference,
    required this.planId,
    required this.planName,
    required this.components,
    required this.invoiceNumber,
    required this.subtotal,
    required this.gstAmount,
    required this.gstRate,
    required this.durationMonths,
    this.hmacSignature,
  });

  factory Payment.fromPayload(String id, Map<String, dynamic> payload, DateTime timestamp) {
    return Payment(
      id: id,
      memberId: payload['memberId'],
      date: timestamp,
      amount: (payload['amount'] as num).toDouble(),
      method: payload['paymentMethod'] ?? 'Cash',
      reference: payload['reference'],
      planId: payload['planId'] ?? 'unknown',
      planName: payload['planName'] ?? 'No Plan',
      invoiceNumber: payload['invoiceNumber'] ?? 'INV-0000',
      durationMonths: payload['durationMonths'] ?? 1,
      subtotal: (payload['amount'] as num).toDouble() / 1.18,
      gstAmount: (payload['amount'] as num).toDouble() - ((payload['amount'] as num).toDouble() / 1.18),
      gstRate: 0.18,
      components: [], // Simplified for reconciliation as components are snapshots
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'memberId': memberId,
      'date': date.toUtc().toIso8601String(),
      'amount': amount,
      'method': method,
      'reference': reference,
      'planId': planId,
      'planName': planName,
      'invoiceNumber': invoiceNumber,
      'durationMonths': durationMonths,
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'gstRate': gstRate,
    };
  }
}

@HiveType(typeId: 13)
class PlanComponentSnapshot extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late double price;

  PlanComponentSnapshot({required this.name, required this.price});
}
