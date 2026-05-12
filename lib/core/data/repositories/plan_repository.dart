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
    if (event.eventType == EventType.plansUpdated) {
      final planData = event.payload['plans'] as List?;
      if (planData != null) {
        // Simple strategy: iterate and upsert
        for (final data in planData) {
          final planMap = Map<String, dynamic>.from(data);
          final plan = domain.Plan(
            id: planMap['id'],
            name: planMap['name'],
            durationMonths: planMap['durationMonths'] ?? 1,
            active: planMap['active'] ?? true,
            price: (planMap['price'] as num?)?.toDouble() ?? 
                   (planMap['components'] as List? ?? []).fold(0.0, (sum, c) => sum + (c['price'] as num? ?? 0.0)),
            components: (planMap['components'] as List? ?? []).map<PlanComponent>((c) {
              final cMap = Map<String, dynamic>.from(c);
              return PlanComponent(
                id: cMap['id'] ?? '',
                name: cMap['name'] ?? '',
                price: (cMap['price'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList(),
          );
          await upsertPlan(plan);
        }
      }
    }
  }
}

final planRepositoryProvider = Provider<IPlanRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftPlanRepository(db);
});
