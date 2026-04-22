import 'package:hive/hive.dart';

@HiveType(typeId: 15)
class Sale extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late DateTime date;
  
  @HiveField(2)
  late double totalAmount;
  
  @HiveField(3)
  late String paymentMethod;
  
  @HiveField(4)
  late List<SaleItem> items;
  
  @HiveField(5)
  late String invoiceNumber;

  @HiveField(6)
  String? hmacSignature;

  Sale({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.paymentMethod,
    required this.items,
    required this.invoiceNumber,
    this.hmacSignature,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'date': date.toUtc().toIso8601String(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'invoiceNumber': invoiceNumber,
      'items': items.map((i) => {
        'productId': i.productId,
        'productName': i.productName,
        'price': i.price,
        'quantity': i.quantity,
      }).toList(),
    };
  }
}

@HiveType(typeId: 16)
class SaleItem extends HiveObject {
  @HiveField(0)
  late String productId;
  @HiveField(1)
  late String productName;
  @HiveField(2)
  late double price;
  @HiveField(3)
  late int quantity;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });
}
