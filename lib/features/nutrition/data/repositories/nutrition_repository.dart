import '../../../../core/data/local/drift/outbox_database.dart' as db;
import '../models/nutrition_plan_model.dart';
import '../models/meal_item_model.dart';
import '../models/water_log_model.dart';
import '../../domain/utils/nutrition_calculator.dart';
import '../../domain/repositories/nutrition_repository.dart';
import 'package:drift/drift.dart';
import '../../../../core/services/hmac_service.dart';

class DriftNutritionRepository implements INutritionRepository {
  final db.OutboxDatabase _db;
  final HmacService _hmac;

  DriftNutritionRepository(this._db, this._hmac);

  @override
  Future<List<NutritionPlan>> getAll() async {
    final rows = await _db.select(_db.nutritionPlans).get();
    return rows.map((row) => NutritionPlan.fromDrift(row)).toList();
  }

  @override
  Future<NutritionPlan?> getPlan(String memberId) async {
    final row = await (_db.select(_db.nutritionPlans)..where((t) => t.memberId.equals(memberId))).getSingleOrNull();
    if (row == null) return null;
    return NutritionPlan.fromDrift(row);
  }

  @override
  Future<void> assignPlan({
    required String memberId,
    required String planName,
    required int dailyCalories,
    int waterGoal = 2000,
  }) async {
    final data = {
      'id': memberId,
      'planName': planName,
      'dailyCalories': dailyCalories,
      'waterGoalMl': waterGoal,
    };
    final signature = await _hmac.signSnapshot(memberId, data);

    await _db.into(_db.nutritionPlans).insertOnConflictUpdate(
      db.NutritionPlansCompanion.insert(
        id: memberId,
        memberId: memberId,
        planName: planName,
        dailyCalories: dailyCalories,
        waterGoalMl: Value(waterGoal),
        hmacSignature: Value(signature),
      ),
    );
  }

  @override
  Future<void> logMeal(MealItem meal) async {
    final data = {
      'id': meal.id,
      'memberId': meal.memberId,
      'foodName': meal.foodName,
      'grams': meal.grams,
      'calories': meal.calories,
      'timestamp': meal.timestamp.toIso8601String(),
    };
    final signature = await _hmac.signSnapshot(meal.id, data);

    await _db.into(_db.mealItems).insertOnConflictUpdate(
      db.MealItemsCompanion.insert(
        id: meal.id,
        memberId: meal.memberId,
        foodName: meal.foodName,
        grams: meal.grams,
        calories: meal.calories,
        timestamp: meal.timestamp,
        hmacSignature: Value(signature),
      ),
    );
    await _updateAdherence(meal.memberId);
  }

  @override
  Future<void> logWater(WaterLog log) async {
    final data = {
      'id': log.id,
      'memberId': log.memberId,
      'amountMl': log.amountMl,
      'timestamp': log.timestamp.toIso8601String(),
    };
    final signature = await _hmac.signSnapshot(log.id, data);

    await _db.into(_db.waterLogs).insertOnConflictUpdate(
      db.WaterLogsCompanion.insert(
        id: log.id,
        memberId: log.memberId,
        amountMl: log.amountMl,
        timestamp: log.timestamp,
        hmacSignature: Value(signature),
      ),
    );
  }

  @override
  Future<List<MealItem>> getMealsForDay(String memberId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = await (_db.select(_db.mealItems)
          ..where((t) => t.memberId.equals(memberId) & t.timestamp.isBetweenValues(start, end)))
        .get();

    return rows.map((row) => MealItem.fromDrift(row)).toList();
  }

  @override
  Future<int> getTotalWaterForDay(String memberId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query = _db.selectOnly(_db.waterLogs)
      ..addColumns([_db.waterLogs.amountMl.sum()])
      ..where(_db.waterLogs.memberId.equals(memberId) & _db.waterLogs.timestamp.isBetweenValues(start, end));
    
    final result = await query.getSingle();
    return result.read(_db.waterLogs.amountMl.sum()) ?? 0;
  }

  Future<void> _updateAdherence(String memberId) async {
    final plan = await getPlan(memberId);
    if (plan == null) return;

    final meals = await getMealsForDay(memberId, DateTime.now());
    final totalConsumed = meals.fold(0.0, (sum, m) => sum + m.calories.toDouble());
    
    final adherence = NutritionCalculator.calculateAdherence(totalConsumed, plan.dailyCalories.toDouble());
    
    await (_db.update(_db.nutritionPlans)..where((t) => t.memberId.equals(memberId))).write(
      db.NutritionPlansCompanion(adherence: Value(adherence))
    );
  }

  @override
  Future<void> deletePlan(String id) async {
    await (_db.delete(_db.nutritionPlans)..where((t) => t.id.equals(id))).go();
  }
}
