import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hmac_service.dart';
import '../../core/utils/event_bus.dart';
import '../local/models/domain_event_model.dart';
import '../../providers/base_providers.dart';

abstract class IEventRepository {
  Future<void> persist(DomainEvent event);
  Future<List<DomainEvent>> getAllUnsynced();
  Future<List<DomainEvent>> getAll(); // Audit 1.5: Support full reconciliation
  Future<DomainEvent?> getById(String id);
  Future<List<DomainEvent>> getByEntityId(String entityId);
  Future<void> markAsSynced(String eventId);
  Stream<DomainEvent> watch();
}

class HiveEventRepository implements IEventRepository {
  final LazyBox<DomainEvent> _box;
  final EventBus _eventBus;
  final HmacService _hmacService;

  // Audit 6.2: In-memory index for performance (IDs only)
  final Set<String> _unsyncedIds = {};

  HiveEventRepository(this._box, this._eventBus, this._hmacService) {
    // We can't iterate values of LazyBox in constructor sync,
    // but we can schedule a microtask or just rely on persist/markSynced
  }

  // Helper to load unsynced index asynchronously
  Future<void> ensureIndexLoaded() async {
    if (_unsyncedIds.isNotEmpty) return;
    final futures = _box.keys.map((k) => _box.get(k));
    final results = await Future.wait(futures);
    for (final event in results) {
      if (event != null && !event.synced) {
        _unsyncedIds.add(event.id);
      }
    }
  }

  @override
  Future<void> persist(DomainEvent event) async {
    debugPrint(
        'HiveEventRepository: Persisting event ${event.eventType} (ID: ${event.id})...');
    // 1. Sign the event (Security Enforcement)
    event.hmacSignature = await _hmacService.signEvent(event);
    debugPrint('HiveEventRepository: HMAC generated.');

    // 2. Write-Ahead Log (WAL)
    _unsyncedIds.add(event.id);
    await _box.put(event.id, event);

    // 3. Dispatch to internal bus for Snapshot rebuilding
    _eventBus.publish(event);
    debugPrint('HiveEventRepository: Event persisted: ${event.eventType}');
  }

  @override
  Future<List<DomainEvent>> getAll() async {
    final futures = _box.keys.map((k) => _box.get(k));
    final results = await Future.wait(futures);
    return results.whereType<DomainEvent>().toList();
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async {
    await ensureIndexLoaded();
    final futures = _unsyncedIds.map((id) => _box.get(id));
    final results = await Future.wait(futures);
    return results.whereType<DomainEvent>().toList();
  }

  @override
  Future<DomainEvent?> getById(String id) async => await _box.get(id);

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async {
    final futures = _box.keys.map((k) => _box.get(k));
    final results = await Future.wait(futures);
    return results
        .whereType<DomainEvent>()
        .where((e) => e.entityId == entityId)
        .toList();
  }

  @override
  Future<void> markAsSynced(String eventId) async {
    final event = await _box.get(eventId);
    if (event != null) {
      event.synced = true;
      _unsyncedIds.remove(eventId);
      await _box.put(eventId, event);
    }
  }

  @override
  Stream<DomainEvent> watch() => _eventBus.stream;
}

final eventRepositoryProvider = Provider<IEventRepository>((ref) {
  final box = Hive.lazyBox<DomainEvent>('events');
  final bus = ref.watch(eventBusProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return HiveEventRepository(box, bus, hmac);
});
