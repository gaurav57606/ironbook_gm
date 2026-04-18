import 'package:flutter/foundation.dart';
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
    _init();
  }

  Future<void> _init() async {
    _loadPlans();
    await _reconcilePlans();
  }

  Future<void> _reconcilePlans() async {
    final allEvents = await _eventRepo.getAll();
    final planEvents = allEvents.where((e) => e.eventType == EventType.plansUpdated).toList();
    
    if (planEvents.isEmpty) return;

    // Get the latest plan update
    final latestEvent = planEvents.reduce((a, b) => a.deviceTimestamp.isAfter(b.deviceTimestamp) ? a : b);
    final planData = latestEvent.payload['plans'] as List?;
    
    if (planData != null) {
      await _box.clear();
      for (final data in planData) {
        final planMap = Map<String, dynamic>.from(data);
        final plan = Plan(
          id: planMap['id'],
          name: planMap['name'],
          durationMonths: planMap['durationMonths'] ?? 1,
          active: planMap['active'] ?? true,
          components: (planMap['components'] as List? ?? []).map((c) {
            final cMap = Map<String, dynamic>.from(c);
            return PlanComponent(
              id: cMap['id'] ?? '',
              name: cMap['name'] ?? '',
              price: (cMap['price'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList(),
        );
        await _box.put(plan.id, plan);
      }
      _loadPlans();
    }
  }

  @visibleForTesting
  set debugState(List<Plan> plans) => state = plans;

  void _loadPlans() {
    state = _box.values.toList();
  }

  Future<void> addPlan(Plan plan) async {
    final now = DateTime.now();
    
    // Emit sync event FIRST (Enforce Outbox-First Rule)
    final event = DomainEvent(
      entityId: 'gym-plans',
      eventType: EventType.plansUpdated, 
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {'plans': [...state, plan].map((p) => {
        'id': p.id,
        'name': p.name,
        'durationMonths': p.durationMonths,
        'active': p.active,
        'components': p.components.map((c) => {'id': c.id, 'name': c.name, 'price': c.price}).toList(),
      }).toList()},
    );

    // Anchor point: Drift Outbox write
    await _eventRepo.persist(event);

    // Persist Cache Locally
    await _box.add(plan);
    state = [...state, plan];
    
    await _syncWorker.performSync();
  }

  Future<void> updatePlan(Plan plan) async {
    final now = DateTime.now();
    
    // Temporary state to build the payload
    final updatedList = state.map((p) => p.id == plan.id ? plan : p).toList();

    final event = DomainEvent(
      entityId: 'gym-plans',
      eventType: EventType.plansUpdated,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {'plans': updatedList.map((p) => {
        'id': p.id,
        'name': p.name,
        'durationMonths': p.durationMonths,
        'active': p.active,
        'components': p.components.map((c) => {'id': c.id, 'name': c.name, 'price': c.price}).toList(),
      }).toList()},
    );

    // Anchor point: Drift Outbox write
    await _eventRepo.persist(event);

    // Persist Cache Locally
    await plan.save();
    _loadPlans();
    
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
