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

  Future<void> markBatchSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.outboxEvents)..where((t) => t.id.isIn(ids))).write(
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

  Future<void> purgeSyncedBefore(DateTime cutoff) async {
    await (_db.delete(_db.outboxEvents)
      ..where((t) => t.isSynced.equals(1) & 
                     t.deviceTimestamp.isSmallerThanValue(cutoff.millisecondsSinceEpoch)))
    .go();
  }

  Future<PinAttempt?> getPinAttempts() async {
    return (_db.select(_db.pinAttempts)..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  Future<void> updatePinAttempts({required int count, DateTime? lockoutUntil}) async {
    await _db.into(_db.pinAttempts).insert(
      PinAttemptsCompanion(
        id: const Value(1),
        count: Value(count),
        lastAttemptAt: Value(DateTime.now()),
        lockoutUntil: Value(lockoutUntil),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> resetPinAttempts() async {
    await _db.into(_db.pinAttempts).insert(
      const PinAttemptsCompanion(
        id: Value(1),
        count: Value(0),
        lastAttemptAt: Value(null),
        lockoutUntil: Value(null),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> clearAll() async {
    await _db.batch((batch) {
      batch.deleteAll(_db.outboxEvents);
      batch.deleteAll(_db.members);
      batch.deleteAll(_db.payments);
      batch.deleteAll(_db.plans);
      batch.deleteAll(_db.sales);
      batch.deleteAll(_db.pinAttempts);
      batch.deleteAll(_db.invoiceSequences);
      batch.deleteAll(_db.products);
      batch.deleteAll(_db.preferences);
      batch.deleteAll(_db.ownerProfiles);
      batch.deleteAll(_db.appSettingsTable);
      batch.deleteAll(_db.notifications);
    });
  }

  // --- Notifications ---

  Future<void> insertNotification(Notification notification) async {
    await _db.into(_db.notifications).insert(
          NotificationsCompanion.insert(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            timestamp: notification.timestamp,
            category: notification.category,
            isRead: Value(notification.isRead),
            payload: Value(notification.payload),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Stream<List<Notification>> watchNotifications() {
    return (_db.select(_db.notifications)
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderMode.desc),
          ]))
        .watch();
  }

  Future<void> markNotificationAsRead(String id) async {
    await (_db.update(_db.notifications)..where((t) => t.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(1)),
    );
  }

  Future<void> markAllNotificationsAsRead() async {
    await _db.update(_db.notifications).write(
          const NotificationsCompanion(isRead: Value(1)),
        );
  }

  Future<void> deleteNotification(String id) async {
    await (_db.delete(_db.notifications)..where((t) => t.id.equals(id))).go();
  }
}
