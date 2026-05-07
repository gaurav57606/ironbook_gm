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
}

@HiveType(typeId: 22)
class WaterLog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String memberId;

  @HiveField(2)
  late int amountMl;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  String? hmacSignature;

  WaterLog({
    required this.id,
    required this.memberId,
    required this.amountMl,
    required this.timestamp,
    this.hmacSignature,
  });
}
