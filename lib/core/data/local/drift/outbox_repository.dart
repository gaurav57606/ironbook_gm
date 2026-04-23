import 'dart:convert';
import 'package:drift/drift.dart';
import 'outbox_database.dart';
import '../models/domain_event_model.dart';

class OutboxRepository {
  final OutboxDatabase _db;

  OutboxRepository(this._db);

  Future<void> insertEvent(DomainEvent event) async {
    final companion = OutboxEventsCompanion.insert(
      id: event.id,
      entityId: event.entityId,
      eventType: event.eventType.name,
      payloadJson: jsonEncode(event.payload),
      deviceTimestamp: event.deviceTimestamp.millisecondsSinceEpoch,
      isSynced: Value(event.synced ? 1 : 0),
      hmacSignature: Value(event.hmacSignature),
      deviceId: Value(event.deviceId),
    );
    
    await _db.into(_db.outboxEvents).insert(
      companion,
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<List<OutboxEvent>> getUnsynced() async {
    return (_db.select(_db.outboxEvents)..where((t) => t.isSynced.equals(0))).get();
  }

  Future<List<DomainEvent>> getUnsyncedEvents() async {
    final docs = await getUnsynced();
    return docs.map((d) => DomainEvent.fromOutbox(d)).toList();
  }

  Future<void> markSynced(String id) async {
    await (_db.update(_db.outboxEvents)..where((t) => t.id.equals(id))).write(
      const OutboxEventsCompanion(isSynced: Value(1)),
    );
  }

  Future<int> countUnsynced() async {
    final countExp = _db.outboxEvents.id.count();
    final query = _db.selectOnly(_db.outboxEvents)
      ..addColumns([countExp])
      ..where(_db.outboxEvents.isSynced.equals(0));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Stream<int> watchUnsyncedCount() {
    final countExp = _db.outboxEvents.id.count();
    final query = _db.selectOnly(_db.outboxEvents)
      ..addColumns([countExp])
      ..where(_db.outboxEvents.isSynced.equals(0));
    
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> seedFromHive(List<DomainEvent> events) async {
    await _db.batch((batch) {
      for (final event in events) {
        if (!event.synced) {
          batch.insert(
            _db.outboxEvents,
            OutboxEventsCompanion.insert(
              id: event.id,
              entityId: event.entityId,
              eventType: event.eventType.name,
              payloadJson: jsonEncode(event.payload),
              deviceTimestamp: event.deviceTimestamp.millisecondsSinceEpoch,
              isSynced: const Value(0),
              hmacSignature: Value(event.hmacSignature),
              deviceId: Value(event.deviceId),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  Future<void> clearAll() async {
    await _db.delete(_db.outboxEvents).go();
  }
}









