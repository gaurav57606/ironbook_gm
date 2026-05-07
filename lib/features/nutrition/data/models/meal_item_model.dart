import 'package:hive/hive.dart';

@HiveType(typeId: 21)
class MealItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String memberId;

  @HiveField(2)
  late String foodName;

  @HiveField(3)
  late double grams;

  @HiveField(4)
  late int calories; // Calculated: (base_cal * grams) / 100

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  String? hmacSignature;

  MealItem({
    required this.id,
    required this.memberId,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.timestamp,
    this.hmacSignature,
  });

  factory MealItem.fromFirestore(Map<String, dynamic> data) {
    return MealItem(
      id: data['id'],
      memberId: data['memberId'],
      foodName: data['foodName'],
      grams: (data['grams'] as num).toDouble(),
      calories: data['calories'],
      timestamp: DateTime.parse(data['timestamp']).toLocal(),
      hmacSignature: data['hmacSignature'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'memberId': memberId,
      'foodName': foodName,
      'grams': grams,
      'calories': calories,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'hmacSignature': hmacSignature,
    };
  }

  factory MealItem.fromDrift(dynamic d) {
    return MealItem(
      id: d.id,
      memberId: d.memberId,
      foodName: d.foodName,
      grams: d.grams,
      calories: d.calories,
      timestamp: d.timestamp,
      hmacSignature: d.hmacSignature,
    );
  }
}
