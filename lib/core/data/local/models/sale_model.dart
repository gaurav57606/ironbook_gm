import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  @HiveField(7)
  late String memberId;

  Sale({
    required this.id,
    required this.memberId,
    required this.date,
    required this.totalAmount,
    required this.paymentMethod,
    required this.items,
    required this.invoiceNumber,
    this.hmacSignature,
  });

  factory Sale.fromFirestore(Map<String, dynamic> data) {
    return Sale(
      id: data['id'],
      memberId: data['memberId'] ?? 'unknown',
      date: DateTime.parse(data['date']).toLocal(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      paymentMethod: data['paymentMethod'],
      invoiceNumber: data['invoiceNumber'],
      items: (data['items'] as List).map((i) => SaleItem(
        productId: i['productId'],
        memberId: data['memberId'] ?? 'unknown',
        productName: i['productName'],
        price: (i['price'] as num).toDouble(),
        quantity: i['quantity'],
      )).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'memberId': memberId,
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
      'hmacSignature': hmacSignature,
    };
  }

  factory Sale.fromDrift(dynamic d) {
    List<SaleItem> items = [];
    if (d.itemsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(d.itemsJson);
        items = decoded.map((i) => SaleItem(
          productId: i['productId'] ?? '',
          memberId: d.memberId ?? 'walk-in',
          productName: i['productName'] ?? '',
          price: (i['price'] as num?)?.toDouble() ?? 0.0,
          quantity: i['quantity'] ?? 1,
        )).toList();
      } catch (e) {
        debugPrint('Error decoding sale itemsJson: $e');
      }
    }

    return Sale(
      id: d.id,
      memberId: d.memberId ?? 'walk-in',
      date: d.date,
      totalAmount: d.totalAmount,
      paymentMethod: d.paymentMethod,
      invoiceNumber: d.invoiceNumber,
      items: items,
      hmacSignature: d.hmacSignature,
    );
  }

  factory Sale.fromPayload(String id, Map<String, dynamic> payload, DateTime timestamp) {
    return Sale(
      id: id,
      memberId: payload['memberId'] ?? 'walk-in',
      date: timestamp,
      totalAmount: (payload['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: payload['method'] ?? 'Cash',
      invoiceNumber: payload['invoiceNumber'] ?? 'SAL-0000',
      items: (payload['items'] as List? ?? []).map((i) {
          final iMap = Map<String, dynamic>.from(i);
          return SaleItem(
            productId: iMap['productId'] ?? '',
            memberId: payload['memberId'] as String? ?? 'walk-in',
            productName: iMap['productName'] as String? ?? 'Unknown',
            price: (iMap['price'] as num?)?.toDouble() ?? 0.0,
            quantity: iMap['qty'] ?? 1,
          );
      }).toList(),
    );
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
  @HiveField(4)
  late String memberId;

  SaleItem({
    required this.productId,
    required this.memberId,
    required this.productName,
    required this.price,
    required this.quantity,
  });
}









