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

  factory NutritionPlan.fromFirestore(Map<String, dynamic> data) {
    return NutritionPlan(
      id: data['id'],
      memberId: data['memberId'],
      planName: data['planName'],
      dailyCalories: data['dailyCalories'],
      adherence: (data['adherence'] as num?)?.toDouble() ?? 0.0,
      waterGoalMl: data['waterGoalMl'] ?? 2000,
      hmacSignature: data['hmacSignature'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'memberId': memberId,
      'planName': planName,
      'dailyCalories': dailyCalories,
      'adherence': adherence,
      'waterGoalMl': waterGoalMl,
      'hmacSignature': hmacSignature,
    };
  }

  factory NutritionPlan.fromDrift(dynamic d) {
    return NutritionPlan(
      id: d.id,
      memberId: d.memberId,
      planName: d.planName,
      dailyCalories: d.dailyCalories,
      adherence: d.adherence,
      waterGoalMl: d.waterGoalMl,
      hmacSignature: d.hmacSignature,
    );
  }

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
