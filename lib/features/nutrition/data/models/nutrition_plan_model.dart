import 'package:hive/hive.dart';

@HiveType(typeId: 20)
class NutritionPlan extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String memberId;

  @HiveField(2)
  late String planName;

  @HiveField(3)
  late String calories;

  @HiveField(4)
  late double adherence; // 0.0 to 1.0

  @HiveField(5)
  late DateTime assignedAt;

  NutritionPlan({
    required this.id,
    required this.memberId,
    required this.planName,
    required this.calories,
    this.adherence = 0.0,
    required this.assignedAt,
  });
}
