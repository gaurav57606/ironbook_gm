import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/nutrition/data/models/nutrition_plan_model.dart';
import 'package:ironbook_gm/features/nutrition/data/models/meal_item_model.dart';
import 'package:ironbook_gm/features/nutrition/data/repositories/nutrition_repository.dart';
import 'package:ironbook_gm/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

import 'package:ironbook_gm/features/nutrition/data/models/water_log_model.dart';

final nutritionRepositoryProvider = Provider<INutritionRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return DriftNutritionRepository(db, hmac);
});

class NutritionState {
  final NutritionPlan? plan;
  final List<MealItem> todaysMeals;
  final int todaysWaterMl;
  final bool isLoading;

  NutritionState({
    this.plan,
    this.todaysMeals = const [],
    this.todaysWaterMl = 0,
    this.isLoading = false,
  });

  NutritionState copyWith({
    NutritionPlan? plan,
    List<MealItem>? todaysMeals,
    int? todaysWaterMl,
    bool? isLoading,
  }) {
    return NutritionState(
      plan: plan ?? this.plan,
      todaysMeals: todaysMeals ?? this.todaysMeals,
      todaysWaterMl: todaysWaterMl ?? this.todaysWaterMl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  final INutritionRepository _repo;
  final String _memberId;

  NutritionNotifier(this._repo, this._memberId) : super(NutritionState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    final plan = await _repo.getPlan(_memberId);
    final meals = await _repo.getMealsForDay(_memberId, DateTime.now());
    final water = await _repo.getTotalWaterForDay(_memberId, DateTime.now());
    
    state = NutritionState(
      plan: plan,
      todaysMeals: meals,
      todaysWaterMl: water,
      isLoading: false,
    );
  }

  Future<void> logMeal(MealItem meal) async {
    await _repo.logMeal(meal);
    await loadData();
  }

  Future<void> logWater(int ml) async {
    final log = WaterLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: _memberId,
      amountMl: ml,
      timestamp: DateTime.now(),
    );
    await _repo.logWater(log);
    await loadData();
  }

  Future<void> assignPlan(String name, int calories, {int waterGoal = 2000}) async {
    await _repo.assignPlan(
      memberId: _memberId,
      planName: name,
      dailyCalories: calories,
      waterGoal: waterGoal,
    );
    await loadData();
  }
}

final nutritionPlansProvider = FutureProvider<List<NutritionPlan>>((ref) {
  return ref.watch(nutritionRepositoryProvider).getAll();
});

final nutritionProvider = StateNotifierProvider.family<NutritionNotifier, NutritionState, String>((ref, memberId) {
  final repo = ref.watch(nutritionRepositoryProvider);
  return NutritionNotifier(repo, memberId);
});
