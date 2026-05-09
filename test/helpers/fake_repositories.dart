import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';

class FakeDriftEventRepository implements IEventRepository {
  final List<DomainEvent> _events = [];

  @override
  Future<void> persist(DomainEvent event) async {
    _events.add(event);
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async =>
      _events.where((e) => !e.synced).toList();
  @override
  Future<DomainEvent?> getById(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async =>
      _events.where((e) => e.entityId == entityId).toList();

  @override
  Future<Map<String, List<DomainEvent>>> getByEntityIds(List<String> entityIds) async {
    final result = <String, List<DomainEvent>>{};
    for (final id in entityIds) {
      result[id] = _events.where((e) => e.entityId == id).toList();
    }
    return result;
  }
  @override
  Future<List<DomainEvent>> getAll() async => List.unmodifiable(_events);
  @override
  Future<List<DomainEvent>> getEventsSince(DateTime since) async =>
      _events.where((e) => e.deviceTimestamp.isAfter(since)).toList();
  @override
  Future<void> markAsSynced(String eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _events[idx] = _events[idx].copyWith(synced: true);
    }
  }

  @override
  Future<void> persistSynced(DomainEvent event) async {
    _events.add(event.copyWith(synced: true));
  }

  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

class FakeClock extends IClock {
  DateTime _now = DateTime(2025, 1, 1, 12, 0, 0);

  @override
  DateTime get now => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  void setNow(DateTime dateTime) {
    _now = dateTime;
  }
}

class FakeSyncCoordinator extends Fake implements SyncCoordinator {
  @override
  void triggerSync() {}
  @override
  Stream<void> get onSyncRequested => const Stream.empty();
  @override
  Future<bool> acquireLock(String holderId) async => true;
  @override
  Future<void> releaseLock(String holderId) async {}

  @override
  Future<void> clearAllLocks() async {}
  
  @override
  void dispose() {}
  
  @override
  Future<bool> isLocked() async => false;
}
