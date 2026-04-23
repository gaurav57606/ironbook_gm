import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'base_providers.dart';

class PlanNotifier extends StateNotifier<List<Plan>> {
  final Box<Plan> _box;
  final IEventRepository _eventRepo;
  final SyncWorker _syncWorker;
  final HmacService _hmac;
  final String _deviceId;

  PlanNotifier(this._box, this._eventRepo, this._syncWorker, this._hmac, this._deviceId) : super([]) {
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
          components: (planMap['components'] as List? ?? []).map<PlanComponent>((c) {
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

  Future<void> _loadPlans() async {
    final plans = _box.values.toList();
    bool needsRepair = false;

    final verified = <Plan>[];
    for (final p in plans) {
      final isValid = await _hmac.verifySnapshot(p.id, p.toFirestore(), p.hmacSignature ?? '');
      if (!isValid) {
        debugPrint('PlanNotifier: Signature mismatch for plan ${p.id}. Flagging for repair.');
        needsRepair = true;
        continue;
      }
      verified.add(p);
    }

    state = verified;

    if (needsRepair) {
      debugPrint('PlanNotifier: Triggering auto-repair from event log.');
      await _reconcilePlans();
    }
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
    final signature = await _hmac.signSnapshot(plan.id, plan.toFirestore());
    final signed = plan..hmacSignature = signature;
    await _box.add(signed);
    state = [...state, signed];
    
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
    final signature = await _hmac.signSnapshot(plan.id, plan.toFirestore());
    final signed = plan..hmacSignature = signature;
    await signed.save();
    await _loadPlans();
    
    await _syncWorker.performSync();
  }
}

final planBoxProvider = Provider<Box<Plan>>((ref) => Hive.box<Plan>('plans'));

final planProvider = StateNotifierProvider<PlanNotifier, List<Plan>>((ref) {
  final box = ref.watch(planBoxProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final syncWorker = ref.watch(syncWorkerProvider);
  final hmac = ref.watch(hmacServiceProvider);
  
  const deviceId = 'device-plan-sync'; 

  return PlanNotifier(box, eventRepo, syncWorker, hmac, deviceId);
});











