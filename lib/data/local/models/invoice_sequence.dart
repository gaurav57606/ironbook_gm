import 'package:hive/hive.dart';

part 'invoice_sequence.g.dart';

@HiveType(typeId: 12)
class InvoiceSequence extends HiveObject {
  @HiveField(0)
  late String prefix; // e.g. "INV-2026-"

  @HiveField(1)
  late int nextNumber;

  InvoiceSequence({required this.prefix, this.nextNumber = 1});

  factory InvoiceSequence.fromFirestore(Map<String, dynamic> data) {
    return InvoiceSequence(
      prefix: data['prefix'],
      nextNumber: data['nextNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'prefix': prefix,
      'nextNumber': nextNumber,
    };
  }

  String get nextInvoiceId {
    final id = '$prefix${nextNumber.toString().padLeft(4, '0')}';
    return id;
  }
}
