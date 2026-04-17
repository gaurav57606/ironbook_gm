import 'dart:async';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';

/// In-memory fake repository for event sourcing.
/// Extremely fast, zero disk I/O, 100% deterministic.
class FakeEventRepository implements IEventRepository {
  final List<DomainEvent> _events = [];
  final StreamController<DomainEvent> _bus = StreamController<DomainEvent>.broadcast();
  
  bool failOnPersist = false;

  @override
  Future<void> persist(DomainEvent event) async {
    if (failOnPersist) throw Exception('Simulated Persistence Failure');
    
    // In a real repo, we'd sign it here, but Fakes can bypass security 
    // unless we are specifically testing security.
    _events.add(event);
    _bus.add(event);
  }

  @override
  Stream<DomainEvent> watch() => _bus.stream;

  @override
  Future<DomainEvent?> getById(String id) async {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async => _events.where((e) => !e.synced).toList();

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async => 
      _events.where((e) => e.entityId == entityId).toList();

  @override
  Future<List<DomainEvent>> getAll() async => List.from(_events);

  @override
  Future<void> markAsSynced(String eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _events[idx].synced = true;
    }
  }

  // Additional helper for tests
  void clear() => _events.clear();
  List<DomainEvent> debugEvents() => List.unmodifiable(_events);
}
