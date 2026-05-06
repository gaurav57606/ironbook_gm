import 'package:hive/hive.dart';

@HiveType(typeId: 14)
class Product extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late double price;
  @HiveField(3)
  late String category;
  @HiveField(4)
  late int iconCodePoint; // Using codePoint for icon persistence

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.iconCodePoint,
  });

  factory Product.fromFirestore(Map<String, dynamic> data) {
    return Product(
      id: data['id'],
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      category: data['category'],
      iconCodePoint: data['iconCodePoint'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'iconCodePoint': iconCodePoint,
    };
  }
}









