import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/shared/utils/event_bus.dart';
import '../local/models/domain_event_model.dart';
import '../local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

abstract class IEventRepository {
  Future<void> persist(DomainEvent event);
  Future<List<DomainEvent>> getAllUnsynced();
  Future<List<DomainEvent>> getAll(); 
  Future<DomainEvent?> getById(String id);
  Future<List<DomainEvent>> getByEntityId(String entityId);
  Future<Map<String, List<DomainEvent>>> getByEntityIds(List<String> entityIds);
  Future<List<DomainEvent>> getEventsSince(DateTime since);
  Future<void> markAsSynced(String eventId);
  Future<void> persistSynced(DomainEvent event); 
  Stream<DomainEvent> watch();
}

class DriftEventRepository implements IEventRepository {
  final OutboxDatabase _db;
  final EventBus _eventBus;
  final HmacService _hmacService;
  final SyncCoordinator _syncCoordinator;

  DriftEventRepository(
    this._db,
    this._eventBus,
    this._hmacService,
    this._syncCoordinator,
  );

  @override
  Future<void> persist(DomainEvent event) async {
    if (event.hmacSignature.isEmpty) {
      event.hmacSignature = await _hmacService.signEvent(event);
    }

    await _db.into(_db.outboxEvents).insert(
      OutboxEventsCompanion.insert(
        id: event.id,
        entityId: event.entityId,
        eventType: event.eventType.name,
        payloadJson: jsonEncode(event.payload),
        deviceTimestamp: event.deviceTimestamp.millisecondsSinceEpoch,
        isSynced: Value(event.synced ? 1 : 0),
        hmacSignature: Value(event.hmacSignature),
        deviceId: Value(event.deviceId),
      ),
      mode: InsertMode.insertOrReplace,
    );

    _eventBus.publish(event);
    if (!kIsWeb) {
      _syncCoordinator.triggerSync();
    }
  }

  @override
  Future<List<DomainEvent>> getAll() async {
    final docs = await _db.select(_db.outboxEvents).get();
    final events = docs.map((d) => DomainEvent.fromOutbox(d)).toList();
    
    final List<DomainEvent> validEvents = [];
    for (final e in events) {
      if (await _hmacService.verifyInstance(e)) {
        validEvents.add(e);
      } else {
        debugPrint('DriftEventRepository: TAMPER DETECTED for event ${e.id}. Skipping.');
      }
    }
    return validEvents;
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async {
    final docs = await (_db.select(_db.outboxEvents)..where((t) => t.isSynced.equals(0))).get();
    return docs.map((d) => DomainEvent.fromOutbox(d)).toList();
  }

  @override
  Future<DomainEvent?> getById(String id) async {
    final doc = await (_db.select(_db.outboxEvents)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (doc != null) {
      final event = DomainEvent.fromOutbox(doc);
      if (await _hmacService.verifyInstance(event)) {
        return event;
      }
    }
    return null;
  }

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async {
    final docs = await (_db.select(_db.outboxEvents)..where((t) => t.entityId.equals(entityId))).get();
    return docs.map((d) => DomainEvent.fromOutbox(d)).toList();
  }

  @override
  Future<Map<String, List<DomainEvent>>> getByEntityIds(List<String> entityIds) async {
    final docs = await (_db.select(_db.outboxEvents)..where((t) => t.entityId.isIn(entityIds))).get();
    final Map<String, List<DomainEvent>> results = {};
    for (final doc in docs) {
      final event = DomainEvent.fromOutbox(doc);
      results.putIfAbsent(event.entityId, () => []).add(event);
    }
    return results;
  }

  @override
  Future<List<DomainEvent>> getEventsSince(DateTime since) async {
    final docs = await (_db.select(_db.outboxEvents)..where((t) => t.deviceTimestamp.isBiggerThanValue(since.millisecondsSinceEpoch))).get();
    final events = docs.map((d) => DomainEvent.fromOutbox(d)).toList();
    
    final List<DomainEvent> validEvents = [];
    for (final e in events) {
      if (await _hmacService.verifyInstance(e)) {
        validEvents.add(e);
      }
    }
    return validEvents;
  }

  @override
  Future<void> markAsSynced(String eventId) async {
    await (_db.update(_db.outboxEvents)..where((t) => t.id.equals(eventId))).write(
      const OutboxEventsCompanion(isSynced: Value(1)),
    );
  }

  @override
  Future<void> persistSynced(DomainEvent event) async {
    event.synced = true;
    await persist(event);
  }

  @override
  Stream<DomainEvent> watch() => _eventBus.stream;
}

final eventRepositoryProvider = Provider<IEventRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  final bus = ref.watch(eventBusProvider);
  final hmac = ref.watch(hmacServiceProvider);
  final syncCoord = ref.watch(syncCoordinatorProvider);

  return DriftEventRepository(db, bus, hmac, syncCoord);
});
