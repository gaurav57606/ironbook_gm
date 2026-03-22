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
  });
}

@HiveType(typeId: 8)
class PlanComponentSnapshot extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late double price;

  PlanComponentSnapshot({required this.name, required this.price});
}
