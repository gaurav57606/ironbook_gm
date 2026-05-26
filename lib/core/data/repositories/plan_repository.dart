import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart' as db;
import '../local/models/plan_model.dart' as domain;
import '../../providers/base_providers.dart';

import '../local/models/domain_event_model.dart';
import '../local/models/plan_component_model.dart';

abstract class IPlanRepository {
  Future<void> upsertPlan(domain.Plan plan);
  Future<domain.Plan?> getPlan(String id);
  Future<List<domain.Plan>> getAllPlans();
  Future<void> applyEvent(DomainEvent event);
  Future<void> deletePlan(String id);
}

class DriftPlanRepository implements IPlanRepository {
  final db.OutboxDatabase _db;

  DriftPlanRepository(this._db);

  @override
  Future<void> upsertPlan(domain.Plan plan) async {
    await _db.into(_db.plans).insertOnConflictUpdate(
      db.PlansCompanion.insert(
        id: plan.id,
        name: plan.name,
        durationMonths: plan.durationMonths,
        price: plan.price,
        active: Value(plan.active),
        componentsJson: Value(jsonEncode(plan.components.map((c) => {
          'id': c.id,
          'name': c.name,
          'price': c.price,
        }).toList())),
        hmacSignature: Value(plan.hmacSignature ?? ''),
      ),
    );
  }

  @override
  Future<domain.Plan?> getPlan(String id) async {
    final query = _db.select(_db.plans)..where((t) => t.id.equals(id));
    final doc = await query.getSingleOrNull();
    return doc != null ? domain.Plan.fromDrift(doc) : null;
  }

  @override
  Future<List<domain.Plan>> getAllPlans() async {
    final docs = await _db.select(_db.plans).get();
    return docs.map((d) => domain.Plan.fromDrift(d)).toList();
  }

  @override
  Future<void> applyEvent(DomainEvent event) async {
    if (event.eventType != EventType.plansUpdated) return;

    final planData = event.payload['plans'] as List?;
    if (planData == null) return;

    // Parse all plans from the event payload first (before touching DB)
    final incomingPlans = planData.map((data) {
      final planMap = Map<String, dynamic>.from(data as Map);
      return domain.Plan(
        id: planMap['id'] as String,
        name: planMap['name'] as String,
        durationMonths: (planMap['durationMonths'] as num?)?.toInt() ?? 1,
        active: planMap['active'] as bool? ?? true,
        price: (planMap['price'] as num?)?.toDouble() ??
            (planMap['components'] as List? ?? []).fold<double>(
              0.0, (sum, c) => sum + ((c['price'] as num?)?.toDouble() ?? 0.0)),
        components: (planMap['components'] as List? ?? []).map<PlanComponent>((c) {
          final cMap = Map<String, dynamic>.from(c as Map);
          return PlanComponent(
            id: cMap['id'] as String? ?? '',
            name: cMap['name'] as String? ?? '',
            price: (cMap['price'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList(),
      );
    }).toList();

    // Atomic replace: delete all existing plans, then insert incoming
    await _db.transaction(() async {
      await _db.delete(_db.plans).go();   // clear slate
      for (final plan in incomingPlans) {
        await upsertPlan(plan);           // insert each plan from event
      }
    });
  }

  @override
  Future<void> deletePlan(String id) async {
    await (_db.delete(_db.plans)..where((t) => t.id.equals(id))).go();
  }
}

final planRepositoryProvider = Provider<IPlanRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftPlanRepository(db);
});
