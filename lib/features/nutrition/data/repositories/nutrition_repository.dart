import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/features/nutrition/data/models/nutrition_plan_model.dart';
import 'package:ironbook_gm/features/nutrition/data/models/meal_item_model.dart';
import 'package:ironbook_gm/features/nutrition/domain/utils/nutrition_calculator.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

class NutritionRepository {
  final Box<NutritionPlan> _planBox;
  final Box<MealItem> _mealBox;
  final Box<WaterLog> _waterBox;
  final HmacService _hmac;

  NutritionRepository(this._planBox, this._mealBox, this._waterBox, this._hmac);

  Future<List<NutritionPlan>> getAll() async {
    return _planBox.values.toList();
  }

  Future<NutritionPlan?> getPlan(String memberId) async {
    return _planBox.get(memberId);
  }

  Future<void> assignPlan({
    required String memberId,
    required String planName,
    required int dailyCalories,
    int waterGoal = 2000,
  }) async {
    try {
      final plan = NutritionPlan(
        id: memberId,
        memberId: memberId,
        planName: planName,
        dailyCalories: dailyCalories,
        waterGoalMl: waterGoal,
      );
      
      // Sign for integrity
      final data = {
        'id': plan.id,
        'planName': plan.planName,
        'dailyCalories': plan.dailyCalories,
        'waterGoalMl': plan.waterGoalMl,
      };
      final signature = await _hmac.signSnapshot(plan.id, data);
      final signedPlan = plan..hmacSignature = signature;
      
      await _planBox.put(memberId, signedPlan);
    } catch (e) {
      throw Exception('Failed to assign nutrition plan: $e');
    }
  }

  Future<void> logMeal(MealItem meal) async {
    try {
      final data = {
        'id': meal.id,
        'memberId': meal.memberId,
        'foodName': meal.foodName,
        'grams': meal.grams,
        'calories': meal.calories,
        'timestamp': meal.timestamp.toIso8601String(),
      };
      final signature = await _hmac.signSnapshot(meal.id, data);
      final signedMeal = meal..hmacSignature = signature;
      
      await _mealBox.put(meal.id, signedMeal);
      await _updateAdherence(meal.memberId);
    } catch (e) {
      throw Exception('Failed to log meal: $e');
    }
  }

  Future<void> logWater(WaterLog log) async {
    try {
      final data = {
        'id': log.id,
        'memberId': log.memberId,
        'amountMl': log.amountMl,
        'timestamp': log.timestamp.toIso8601String(),
      };
      final signature = await _hmac.signSnapshot(log.id, data);
      final signedLog = log..hmacSignature = signature;
      
      await _waterBox.put(log.id, signedLog);
    } catch (e) {
      throw Exception('Failed to log water: $e');
    }
  }

  Future<List<MealItem>> getMealsForDay(String memberId, DateTime date) async {
    return _mealBox.values.where((m) => 
      m.memberId == memberId && 
      m.timestamp.year == date.year && 
      m.timestamp.month == date.month && 
      m.timestamp.day == date.day
    ).toList();
  }

  Future<int> getTotalWaterForDay(String memberId, DateTime date) async {
    return _waterBox.values
      .where((w) => 
        w.memberId == memberId && 
        w.timestamp.year == date.year && 
        w.timestamp.month == date.month && 
        w.timestamp.day == date.day
      )
      .fold<int>(0, (sum, w) => sum + w.amountMl);
  }

  Future<void> _updateAdherence(String memberId) async {
    final plan = await getPlan(memberId);
    if (plan == null) return;

    final meals = await getMealsForDay(memberId, DateTime.now());
    final totalConsumed = meals.fold(0.0, (sum, m) => sum + m.calories);
    
    final adherence = NutritionCalculator.calculateAdherence(totalConsumed, plan.dailyCalories.toDouble());
    await _planBox.put(memberId, plan.copyWith(adherence: adherence));
  }

  Future<void> deletePlan(String id) async {
    await _planBox.delete(id);
  }
}
