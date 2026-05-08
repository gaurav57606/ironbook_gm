import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'base_providers.dart';

class PlanNotifier extends StateNotifier<List<Plan>> {
  final db.OutboxDatabase _db;
  final IEventRepository _eventRepo;
  final IPlanRepository _planRepo;
  final SyncWorker _syncWorker;
  final HmacService _hmac;
  String _deviceId = 'device-plan-sync';
  StreamSubscription? _eventSubscription;

  PlanNotifier(
    db.OutboxDatabase db,
    this._eventRepo,
    this._planRepo,
    this._syncWorker,
    this._hmac,
  ) : _db = db, super([]) {
    _init();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();

    // 1. Listen for events (Single Source of Truth)
    _eventSubscription = _eventRepo.watch().listen((event) async {
      if (event.eventType == EventType.plansUpdated) {
        debugPrint('[STATE] PlanNotifier: Processing plans update event');
        await _planRepo.applyEvent(event);
        if (mounted) {
          state = await _planRepo.getAllPlans();
        }
      }
    });

    // 2. Load all plans from Drift
    debugPrint('[DB] PlanNotifier: Loading initial plans from repository');
    state = await _planRepo.getAllPlans();
    debugPrint('[STATE] PlanNotifier: Loaded ${state.length} plans');

    // 3. Reconcile
    await _reconcilePlans();
  }

  Future<void> _reconcilePlans() async {
    final allEvents = await _eventRepo.getAll();
    final planEvents = allEvents.where((e) => e.eventType == EventType.plansUpdated).toList();
    
    if (planEvents.isEmpty) return;

    // Get the latest plan update
    final latestEvent = planEvents.reduce((a, b) => a.deviceTimestamp.isAfter(b.deviceTimestamp) ? a : b);
    
    // We can just use applyEvent here
    await _planRepo.applyEvent(latestEvent);
    state = await _planRepo.getAllPlans();
  }

  @visibleForTesting
  set debugState(List<Plan> plans) => state = plans;

  Future<void> addPlan(Plan plan) async {
    final now = DateTime.now();
    
    // Emit sync event FIRST
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

    await _db.transaction(() async {
      debugPrint('[TRANSACTION] PlanNotifier: Starting addPlan for ${plan.id}');
      await _eventRepo.persist(event);

      // Persist Locally in Drift
      debugPrint('[DB] PlanNotifier: Adding plan ${plan.name}');
      await _planRepo.upsertPlan(plan);
      debugPrint('[TRANSACTION] PlanNotifier: addPlan transaction complete');
    });

    debugPrint('[SYNC] PlanNotifier: Triggering sync');
    await _syncWorker.performSync();
  }

  Future<void> updatePlan(Plan plan) async {
    final now = DateTime.now();
    
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

    await _db.transaction(() async {
      debugPrint('[TRANSACTION] PlanNotifier: Starting updatePlan for ${plan.id}');
      await _eventRepo.persist(event);

      // Persist Locally in Drift
      await _planRepo.upsertPlan(plan);
      debugPrint('[TRANSACTION] PlanNotifier: updatePlan transaction complete');
    });
    
    await _syncWorker.performSync();
  }
}

final planProvider = StateNotifierProvider<PlanNotifier, List<Plan>>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  final planRepo = ref.watch(planRepositoryProvider);
  final syncWorker = ref.watch(syncWorkerProvider);
  final db = ref.watch(outboxDatabaseProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return PlanNotifier(db, eventRepo, planRepo, syncWorker, hmac);
});











