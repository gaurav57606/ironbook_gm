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
  late int dailyCalories;

  @HiveField(4)
  late double adherence;

  @HiveField(5)
  late int waterGoalMl;

  @HiveField(6)
  String? hmacSignature;

  NutritionPlan({
    required this.id,
    required this.memberId,
    required this.planName,
    required this.dailyCalories,
    this.adherence = 0.0,
    this.waterGoalMl = 2000,
    this.hmacSignature,
  });

  NutritionPlan copyWith({
    String? memberId,
    String? planName,
    int? dailyCalories,
    double? adherence,
    int? waterGoalMl,
    String? hmacSignature,
  }) {
    return NutritionPlan(
      id: id,
      memberId: memberId ?? this.memberId,
      planName: planName ?? this.planName,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      adherence: adherence ?? this.adherence,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      hmacSignature: hmacSignature ?? this.hmacSignature,
    );
  }
}
