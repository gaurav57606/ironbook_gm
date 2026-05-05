import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/shared/utils/event_bus.dart';
import '../local/models/domain_event_model.dart';
import '../local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

abstract class IEventRepository {
  Future<void> persist(DomainEvent event);
  Future<List<DomainEvent>> getAllUnsynced();
  Future<List<DomainEvent>> getAll(); // Audit 1.5: Support full reconciliation
  Future<DomainEvent?> getById(String id);
  Future<List<DomainEvent>> getByEntityId(String entityId);
  Future<void> markAsSynced(String eventId);
  Future<void> persistSynced(
    DomainEvent event,
  ); // Recovery: Persist without Outbox
  Stream<DomainEvent> watch();
}

class HiveEventRepository implements IEventRepository {
  final LazyBox<DomainEvent> _box;
  final EventBus _eventBus;
  final HmacService _hmacService;
  final OutboxRepository _outboxRepo;
  final SyncCoordinator _syncCoordinator;

  // Audit 6.2: In-memory index for performance (IDs only)
  final Set<String> _unsyncedIds = {};
  final Map<String, List<String>> _entityIndex = {};
  bool _isIndexLoaded = false;
  Future<void>? _loadingIndex;

  HiveEventRepository(
    this._box,
    this._eventBus,
    this._hmacService,
    this._outboxRepo,
    this._syncCoordinator,
  );

  // Helper to load indexes asynchronously
  Future<void> ensureIndexLoaded() async {
    if (_isIndexLoaded) return;
    if (_loadingIndex != null) return _loadingIndex;

    _loadingIndex = _loadIndex();
    return _loadingIndex;
  }

  Future<void> _loadIndex() async {
    _unsyncedIds.clear();
    _entityIndex.clear();

    // Audit 6.2: Parallelize Hive access
    final events = await Future.wait(_box.keys.map((key) => _box.get(key)));
    for (final event in events) {
      if (event != null) {
        if (!event.synced) {
          _unsyncedIds.add(event.id);
        }
        _entityIndex.putIfAbsent(event.entityId, () => []).add(event.id);
      }
    }
    _isIndexLoaded = true;
    _loadingIndex = null;
  }

  @override
  Future<void> persist(DomainEvent event) async {
    debugPrint(
      'HiveEventRepository: ACID Dual-Write Start: ${event.eventType}',
    );

    // 1. Sign (Security Enforcement)
    event.hmacSignature = await _hmacService.signEvent(event);

    try {
      // 2. Drift Outbox write (The Source of Truth for Sync)
      // Audit Hardening: On Web, sql.js might be missing. We allow local-only mode if this fails.
      try {
        await _outboxRepo.insertEvent(event);
        debugPrint('HiveEventRepository: 1/2 Drift Outbox Success');
      } catch (e) {
        if (kIsWeb) {
          debugPrint(
            'HiveEventRepository: Drift Outbox skipped on Web (sql.js missing/error): $e',
          );
        } else {
          rethrow;
        }
      }

      // 3. Local Hive write (The Source of Truth for Local UI)
      _unsyncedIds.add(event.id);
      _entityIndex.putIfAbsent(event.entityId, () => []).add(event.id);
      await _box.put(event.id, event);
      debugPrint('HiveEventRepository: 2/2 Hive Event Log Success');

      // 4. Dispatch and Trigger
      _eventBus.publish(event);
      // Trigger sync only if not on web or if we want to try (it will fail gracefully anyway)
      if (!kIsWeb) {
        _syncCoordinator.triggerSync();
      }
    } catch (e) {
      debugPrint('HiveEventRepository: ACID FAILURE - Transaction Aborted: $e');
      rethrow;
    }
  }

  @override
  Future<List<DomainEvent>> getAll() async {
    final List<DomainEvent> validEvents = [];
    final allEvents = await Future.wait(_box.keys.map((key) => _box.get(key)));
    final nonNullEvents = allEvents.whereType<DomainEvent>().toList();

    final verificationResults = await Future.wait(
      nonNullEvents.map((e) => _hmacService.verifyInstance(e)),
    );

    for (int i = 0; i < nonNullEvents.length; i++) {
      if (verificationResults[i]) {
        validEvents.add(nonNullEvents[i]);
      } else {
        debugPrint(
          'HiveEventRepository: TAMPER DETECTED for event ${nonNullEvents[i].id}. Skipping.',
        );
      }
    }
    return validEvents;
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async {
    await ensureIndexLoaded();
    final List<DomainEvent> unsynced = [];

    final allEvents = await Future.wait(_unsyncedIds.map((id) => _box.get(id)));
    final nonNullEvents = allEvents.whereType<DomainEvent>().toList();

    final verificationResults = await Future.wait(
      nonNullEvents.map((e) => _hmacService.verifyInstance(e)),
    );

    for (int i = 0; i < nonNullEvents.length; i++) {
      if (verificationResults[i]) {
        unsynced.add(nonNullEvents[i]);
      }
    }
    return unsynced;
  }

  @override
  Future<DomainEvent?> getById(String id) async {
    final event = await _box.get(id);
    if (event != null && await _hmacService.verifyInstance(event)) {
      return event;
    }
    return null;
  }

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async {
    await ensureIndexLoaded();
    final eventIds = _entityIndex[entityId] ?? [];
    final List<DomainEvent> results = [];

    final allEvents = await Future.wait(eventIds.map((id) => _box.get(id)));
    final nonNullEvents = allEvents.whereType<DomainEvent>().toList();

    final verificationResults = await Future.wait(
      nonNullEvents.map((e) => _hmacService.verifyInstance(e)),
    );

    for (int i = 0; i < nonNullEvents.length; i++) {
      if (verificationResults[i]) {
        results.add(nonNullEvents[i]);
      }
    }
    return results;
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
  Future<void> persistSynced(DomainEvent event) async {
    debugPrint(
      'HiveEventRepository: Persisting recovered/synced event: ${event.id}',
    );
    // 1. Ensure signed
    if (event.hmacSignature.isEmpty) {
      event.hmacSignature = await _hmacService.signEvent(event);
    }

    // 2. Direct to Hive (Bypass Outbox)
    _entityIndex.putIfAbsent(event.entityId, () => []).add(event.id);
    await _box.put(event.id, event);

    // 3. Dispatch
    _eventBus.publish(event);
  }

  @override
  Stream<DomainEvent> watch() => _eventBus.stream;
}

final eventRepositoryProvider = Provider<IEventRepository>((ref) {
  final box = Hive.lazyBox<DomainEvent>('events');
  final bus = ref.watch(eventBusProvider);
  final hmac = ref.watch(hmacServiceProvider);
  final outboxRepo = ref.watch(outboxRepositoryProvider);
  final syncCoord = ref.watch(syncCoordinatorProvider);

  return HiveEventRepository(box, bus, hmac, outboxRepo, syncCoord);
});
