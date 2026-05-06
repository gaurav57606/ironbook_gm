import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/nutrition_plan_model.dart';

class NutritionRepository {
  final Box<NutritionPlan> _box;

  NutritionRepository(this._box);

  Future<List<NutritionPlan>> getAll() async {
    return _box.values.toList();
  }

  Future<void> assignPlan({
    required String memberId,
    required String planName,
    required String calories,
  }) async {
    final plan = NutritionPlan(
      id: const Uuid().v4(),
      memberId: memberId,
      planName: planName,
      calories: calories,
      assignedAt: DateTime.now(),
    );
    await _box.put(plan.id, plan);
  }

  Future<void> updateAdherence(String id, double adherence) async {
    final plan = _box.get(id);
    if (plan != null) {
      plan.adherence = adherence;
      await plan.save();
    }
  }

  Future<void> deletePlan(String id) async {
    await _box.delete(id);
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final box = Hive.box<NutritionPlan>('nutrition');
  return NutritionRepository(box);
});

final nutritionPlansProvider = FutureProvider<List<NutritionPlan>>((ref) {
  return ref.watch(nutritionRepositoryProvider).getAll();
});
