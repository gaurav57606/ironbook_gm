import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'base_providers.dart';

final ownerBoxProvider = Provider<Box<OwnerProfile>>((ref) => Hive.box<OwnerProfile>('owner'));

final ownerProvider = StateNotifierProvider<OwnerNotifier, OwnerProfile?>((ref) {
  final box = ref.watch(ownerBoxProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return OwnerNotifier(box, eventRepo, hmac);
});

class OwnerNotifier extends StateNotifier<OwnerProfile?> {
  final Box<OwnerProfile> _box;
  final IEventRepository _eventRepo;
  final HmacService _hmac;
  String _deviceId = 'device-loading';

  OwnerNotifier(this._box, this._eventRepo, this._hmac) : super(null) {
    _init();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();
    await _loadProfile();
    await _reconcileProfile();
  }

  Future<void> _loadProfile() async {
    final profile = _box.get('owner');
    if (profile == null) return;

    final isValid = await _hmac.verifySnapshot('owner', profile.toFirestore(), profile.hmacSignature ?? '');
    if (!isValid) {
      debugPrint('OwnerNotifier: Signature mismatch for business profile. Integrity compromised.');
      return;
    }
    state = profile;
  }

  Future<void> _reconcileProfile() async {
    final allEvents = await _eventRepo.getAll();
    final profileEvents = allEvents.where((e) => e.eventType == EventType.ownerProfileUpdated).toList();
    if (profileEvents.isEmpty) return;

    final latest = profileEvents.reduce((a, b) => a.deviceTimestamp.isAfter(b.deviceTimestamp) ? a : b);
    final payload = latest.payload;

    final profile = OwnerProfile(
      gymName: payload['gymName'] ?? '',
      ownerName: payload['ownerName'] ?? '',
      phone: payload['phone'] ?? '',
      address: payload['address'] ?? '',
      gstin: payload['gstin'],
      bankName: payload['bankName'],
      accountNumber: payload['accountNumber'],
      ifsc: payload['ifsc'],
      upiId: payload['upiId'],
      level: payload['level'] ?? 1,
      exp: payload['exp'] ?? 0,
      strength: (payload['strength'] as num?)?.toDouble() ?? 0.5,
      endurance: (payload['endurance'] as num?)?.toDouble() ?? 0.5,
      dexterity: (payload['dexterity'] as num?)?.toDouble() ?? 0.5,
      selectedCharacterId: payload['selectedCharacterId'] ?? 'warrior',
    );

    final signature = await _hmac.signSnapshot('owner', profile.toFirestore());
    profile.hmacSignature = signature;
    await _box.put('owner', profile);
    state = profile;
  }

  Future<void> updateOwner(OwnerProfile profile) async {
    final now = DateTime.now();
    
    // 1. Emit Domain Event (ACID Anchor)
    final event = DomainEvent(
      entityId: 'owner',
      eventType: EventType.ownerProfileUpdated,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: profile.toFirestore(),
    );
    await _eventRepo.persist(event);

    // 2. Sign and Persist Snapshot
    final signature = await _hmac.signSnapshot('owner', profile.toFirestore());
    profile.hmacSignature = signature;
    await _box.put('owner', profile);
    state = profile;
  }
}











