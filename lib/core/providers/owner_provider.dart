import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/owner_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/local/models/owner_profile_model.dart';
import '../data/local/models/domain_event_model.dart';
import '../services/hmac_service.dart';
import 'base_providers.dart';

final ownerRepositoryProvider = Provider<IOwnerRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftOwnerRepository(db);
});

final ownerProvider = StateNotifierProvider<OwnerNotifier, OwnerProfile?>((ref) {
  final repo = ref.watch(ownerRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return OwnerNotifier(repo, eventRepo, hmac);
});

class OwnerNotifier extends StateNotifier<OwnerProfile?> {
  final IOwnerRepository _repo;
  final IEventRepository _eventRepo;
  final HmacService _hmac;
  StreamSubscription? _eventSubscription;
  String _deviceId = 'device-unknown';

  OwnerNotifier(this._repo, this._eventRepo, this._hmac) : super(null) {
    _init();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();
    
    // 1. Listen for owner events
    _eventSubscription = _eventRepo.watch().listen((event) async {
      if (event.eventType == EventType.ownerProfileCreated || 
          event.eventType == EventType.ownerProfileUpdated) {
        debugPrint('[STATE] OwnerNotifier: Processing owner event');
        await _repo.applyEvent(event);
        if (mounted) {
          state = await _repo.getOwner();
        }
      }
    });

    // 2. Load initial state
    state = await _repo.getOwner();
  }

  Future<void> updateOwner(OwnerProfile profile) async {
    // Emit event
    final event = DomainEvent(
      entityId: 'owner',
      eventType: EventType.ownerProfileUpdated,
      deviceId: _deviceId,
      deviceTimestamp: DateTime.now(),
      payload: profile.toJson(),
    );

    await _eventRepo.persist(event);
    await _repo.upsertOwner(profile);
  }

  Future<void> rebuildCache() async {
    debugPrint('[STATE] OwnerNotifier: Full rebuild triggered');
    final events = await _eventRepo.getByEntityId('owner');
    if (events.isNotEmpty) {
      // Sort by timestamp and apply latest
      events.sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));
      final latest = events.last;
      await _repo.applyEvent(latest);
      if (mounted) {
        state = await _repo.getOwner();
      }
    }
  }
}
