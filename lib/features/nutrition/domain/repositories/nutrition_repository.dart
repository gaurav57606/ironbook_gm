import '../../data/models/nutrition_plan_model.dart';
import '../../data/models/meal_item_model.dart';
import 'package:ironbook_gm/features/nutrition/data/models/water_log_model.dart';

abstract class INutritionRepository {
  Future<List<NutritionPlan>> getAll();
  Future<NutritionPlan?> getPlan(String memberId);
  Future<void> assignPlan({
    required String memberId,
    required String planName,
    required int dailyCalories,
    int waterGoal = 2000,
  });
  Future<void> logMeal(MealItem meal);
  Future<void> logWater(WaterLog log);
  Future<List<MealItem>> getMealsForDay(String memberId, DateTime date);
  Future<int> getTotalWaterForDay(String memberId, DateTime date);
  Future<void> deletePlan(String id);
}
