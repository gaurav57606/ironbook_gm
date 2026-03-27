import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hmac_service.dart';
import '../../core/utils/event_bus.dart';
import '../local/models/domain_event_model.dart';

abstract class IEventRepository {
  Future<void> persist(DomainEvent event);
  List<DomainEvent> getAllUnsynced();
  DomainEvent? getById(String id);
  List<DomainEvent> getByEntityId(String entityId);
  Future<void> markAsSynced(String eventId);
  Stream<DomainEvent> watch();
}

class HiveEventRepository implements IEventRepository {
  final Box<DomainEvent> _box;
  final EventBus _eventBus;

  HiveEventRepository(this._box, this._eventBus);

  @override
  Future<void> persist(DomainEvent event) async {
    debugPrint('HiveEventRepository: Persisting event ${event.eventType} (ID: ${event.id})...');
    // 1. Sign the event (Security Enforcement)
    event.hmacSignature = await HmacService.sign(event);
    debugPrint('HiveEventRepository: HMAC generated.');
    
    // 2. Write-Ahead Log (WAL)
    await _box.put(event.id, event);
    
    // 3. Dispatch to internal bus for Snapshot rebuilding
    _eventBus.publish(event);
    debugPrint('HiveEventRepository: Event persisted: ${event.eventType}');
  }

  @override
  List<DomainEvent> getAllUnsynced() {
    final all = _box.values.toList();
    final unsynced = all.where((e) => !e.synced).toList();
    debugPrint('HiveEventRepository: Total events: ${all.length}, Unsynced: ${unsynced.length}');
    return unsynced;
  }

  @override
  DomainEvent? getById(String id) => _box.get(id);

  @override
  List<DomainEvent> getByEntityId(String entityId) {
    return _box.values.where((e) => e.entityId == entityId).toList();
  }

  @override
  Future<void> markAsSynced(String eventId) async {
    final event = _box.get(eventId);
    if (event != null) {
      event.synced = true;
      await _box.put(eventId, event);
    }
  }

  @override
  Stream<DomainEvent> watch() => _eventBus.stream;
}

final eventRepositoryProvider = Provider<IEventRepository>((ref) {
  final box = Hive.box<DomainEvent>('events');
  final bus = ref.watch(eventBusProvider);
  return HiveEventRepository(box, bus);
});
