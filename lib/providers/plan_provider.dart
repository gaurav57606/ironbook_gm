import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/models/plan_model.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/repositories/event_repository.dart';
import '../data/sync_worker.dart';

class PlanNotifier extends StateNotifier<List<Plan>> {
  final Box<Plan> _box;
  final IEventRepository _eventRepo;
  final SyncWorker _syncWorker;
  final String _deviceId;

  PlanNotifier(this._box, this._eventRepo, this._syncWorker, this._deviceId) : super([]) {
    _loadPlans();
  }

  void _loadPlans() {
    state = _box.values.toList();
  }

  Future<void> addPlan(Plan plan) async {
    await _box.add(plan);
    state = [...state, plan];

    // Emit sync event
    final event = DomainEvent(
      entityId: 'gym-plans',
      eventType: 'plansUpdated', 
      deviceId: _deviceId,
      payload: {'plans': state.map((p) => {
        'id': p.id,
        'name': p.name,
        'durationMonths': p.durationMonths,
        'active': p.active,
        'components': p.components.map((c) => {'id': c.id, 'name': c.name, 'price': c.price}).toList(),
      }).toList()},
    );

    await _eventRepo.persist(event);
    await _syncWorker.performSync();
  }

  Future<void> updatePlan(Plan plan) async {
    await plan.save();
    _loadPlans();

    final event = DomainEvent(
      entityId: 'gym-plans',
      eventType: 'plansUpdated',
      deviceId: _deviceId,
      payload: {'plans': state.map((p) => {
        'id': p.id,
        'name': p.name,
        'durationMonths': p.durationMonths,
        'active': p.active,
        'components': p.components.map((c) => {'id': c.id, 'name': c.name, 'price': c.price}).toList(),
      }).toList()},
    );
    await _eventRepo.persist(event);
    await _syncWorker.performSync();
  }
}

final planBoxProvider = Provider<Box<Plan>>((ref) => Hive.box<Plan>('plans'));

final planProvider = StateNotifierProvider<PlanNotifier, List<Plan>>((ref) {
  final box = ref.watch(planBoxProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final syncWorker = ref.watch(syncWorkerProvider);
  
  // Get device ID from auth provider if available or use a static one for now
  // We'll just generate one for now as we did in AuthNotifier
  const deviceId = 'device-plan-sync'; 

  return PlanNotifier(box, eventRepo, syncWorker, deviceId);
});
