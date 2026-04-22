import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/local/models/plan_model.dart';
import '../data/repositories/event_repository.dart';
import '../data/local/snapshot_builder.dart';
import '../core/utils/clock.dart';
import '../core/utils/date_utils.dart';
import '../core/services/hmac_service.dart';
import '../providers/base_providers.dart';
import '../constants/event_payload_keys.dart';

final membersProvider = StateNotifierProvider<MemberNotifier, List<MemberSnapshot>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return MemberNotifier(repo, clock, hmac);
});

final memberSearchQueryProvider = StateProvider<String>((ref) => '');
final memberTabProvider = StateProvider<int>((ref) => 0); // 0: All, 1: Active, 2: Expiring, 3: Expired

final filteredMembersProvider = Provider<List<MemberSnapshot>>((ref) {
  final members = ref.watch(membersProvider);
  final query = ref.watch(memberSearchQueryProvider).toLowerCase();
  final tabIndex = ref.watch(memberTabProvider);
  final now = ref.watch(clockProvider).now;

  return members.where((m) {
    final matchesSearch = m.name.toLowerCase().contains(query) ||
        (m.phone?.contains(query) ?? false);
    
    if (!matchesSearch) return false;

    if (tabIndex == 0) return true; // All
    final status = m.getStatus(now);
    if (tabIndex == 1) return status == MemberStatus.active;
    if (tabIndex == 2) return status == MemberStatus.expiring;
    if (tabIndex == 3) return status == MemberStatus.expired;
    return true;
  }).toList();
});

class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final IEventRepository _repo;
  final IClock _clock;
  final HmacService _hmac;
  String _deviceId = 'device-unknown';

  MemberNotifier(this._repo, this._clock, this._hmac) : super([]) {
    init();
  }

  @visibleForTesting
  set debugState(List<MemberSnapshot> members) => state = members;

  Future<void> init() async {
    _deviceId = await _hmac.getInstallationId();
    if (!Hive.isBoxOpen('snapshots')) return;
    final box = Hive.lazyBox<MemberSnapshot>('snapshots');
    state = await _loadAllSnapshots(box);

    // 1. Recovery & Integrity: Reconcile lagging snapshots with event log
    await _reconcileSnapshots();
    
    // 2. Real-time updates via Event Bus
    _repo.watch().listen((event) async {
      final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');
      final current = await snapshotBox.get(event.entityId);
      
      // Audit 1.4: Skip if snapshot is already up-to-date (Near-atomic write handled it)
      if (current != null && current.lastUpdated.isAtSameMomentAs(event.deviceTimestamp)) {
        return;
      }

      final updated = SnapshotBuilder.apply(current, event);
      if (updated != null) {
        // Sign before saving
        final signature = await _hmac.signSnapshot(event.entityId, updated.toFirestore());
        final signed = updated.copyWith(hmacSignature: signature);
        await snapshotBox.put(event.entityId, signed);
        state = await _loadAllSnapshots(snapshotBox);
      } else if (event.eventType == EventType.memberArchived) {
        await snapshotBox.delete(event.entityId);
        state = await _loadAllSnapshots(snapshotBox);
      }
    });
  }

  Future<List<MemberSnapshot>> _loadAllSnapshots(LazyBox<MemberSnapshot> box) async {
    final keys = box.keys.toList();
    final List<MemberSnapshot> validSnapshots = [];
    
    for (final key in keys) {
      final snap = await box.get(key);
      if (snap == null) continue;

      // Integrity Check
      final isValid = snap.hmacSignature != null && 
          await _hmac.verifySnapshot(snap.memberId, snap.toFirestore(), snap.hmacSignature!);
      
      if (isValid) {
        validSnapshots.add(snap);
      } else {
        debugPrint('MemberNotifier: TAMPER DETECTED for ${snap.memberId}. Triggering automatic repair...');
        // Repair from Event Log (Write-Ahead Log)
        final history = await _repo.getByEntityId(snap.memberId);
        final repaired = SnapshotBuilder.rebuild(history);
        if (repaired != null) {
          final signature = await _hmac.signSnapshot(snap.memberId, repaired.toFirestore());
          final signed = repaired.copyWith(hmacSignature: signature);
          await box.put(snap.memberId, signed);
          validSnapshots.add(signed);
        }
      }
    }
    return validSnapshots;
  }

  Future<void> _reconcileSnapshots() async {
    final box = Hive.lazyBox<MemberSnapshot>('snapshots');
    final allEvents = await _repo.getAll(); 
    
    if (allEvents.isEmpty) return;

    // Audit 1.5 Fix: Reconcile from ALL local events to catch app-kill gaps
    final latestByEntity = <String, DateTime>{};
    for (final e in allEvents) {
      if (latestByEntity[e.entityId] == null || e.deviceTimestamp.isAfter(latestByEntity[e.entityId]!)) {
        latestByEntity[e.entityId] = e.deviceTimestamp;
      }
    }

    bool updatedAny = false;
    for (final entityId in latestByEntity.keys) {
      final snap = await box.get(entityId);
      if (snap == null || snap.lastUpdated.isBefore(latestByEntity[entityId]!)) {
        debugPrint('MemberNotifier: Lagging snapshot detected for $entityId. Rebuilding...');
        final history = await _repo.getByEntityId(entityId);
        final rebuilt = SnapshotBuilder.rebuild(history);
        if (rebuilt != null) {
          await box.put(entityId, rebuilt);
          updatedAny = true;
        }
      }
    }

    if (updatedAny) {
      state = await _loadAllSnapshots(box);
    }
  }

  Future<void> rebuildCache() async {
    debugPrint('MemberNotifier: Manual cache rebuild triggered.');
    final box = Hive.lazyBox<MemberSnapshot>('snapshots');
    await box.clear();
    await _reconcileSnapshots();
  }



  Future<String> addMember({
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
  }) async {
    final memberId = const Uuid().v4();
    final now = _clock.now;
    
    final plansBox = Hive.box<Plan>('plans');
    final plan = plansBox.get(planId);
    
    if (plan == null) throw Exception('Plan not found');

    final expiryDate = AppDateUtils.addMonths(joinDate, plan.durationMonths);

    final memberEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberCreated,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        EventPayloadKeys.memberId: memberId,
        EventPayloadKeys.name: name,
        EventPayloadKeys.phone: phone,
        EventPayloadKeys.planId: planId,
        EventPayloadKeys.planName: plan.name,
        EventPayloadKeys.joinDate: joinDate.toUtc().toIso8601String(),
        EventPayloadKeys.newExpiry: expiryDate.toUtc().toIso8601String(),
      },
    );

    await _repo.persist(memberEvent);

    // Audit 1.4: Near-atomic snapshot update
    final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    final snapshot = MemberSnapshot.fromPayload(memberId, memberEvent.payload);
    
    // Sign before saving
    final signature = await _hmac.signSnapshot(memberId, snapshot.toFirestore());
    final signed = snapshot.copyWith(hmacSignature: signature);
    
    await snapshotBox.put(memberId, signed);
    state = [...state, signed];

    return memberId;
  }


  Future<void> deleteMember(String memberId) async {
    final deleteEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberArchived,
      deviceId: _deviceId,
      deviceTimestamp: _clock.now,
      payload: {'memberId': memberId},
    );

    await _repo.persist(deleteEvent);

    // Audit 1.4: Near-atomic snapshot update
    final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    await snapshotBox.delete(memberId);
    state = state.where((m) => m.memberId != memberId).toList();
  }

  Future<void> updateMember({
    required String memberId,
    required String name,
    required String phone,
  }) async {
    final updateEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberUpdated,
      deviceId: _deviceId,
      deviceTimestamp: _clock.now,
      payload: {
        EventPayloadKeys.memberId: memberId,
        EventPayloadKeys.name: name,
        EventPayloadKeys.phone: phone,
      },
    );
    await _repo.persist(updateEvent);

    // Audit 1.4: Near-atomic snapshot update
    final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    final current = await snapshotBox.get(memberId);
    final updated = SnapshotBuilder.apply(current, updateEvent);
    if (updated != null) {
      final signature = await _hmac.signSnapshot(memberId, updated.toFirestore());
      final signed = updated.copyWith(hmacSignature: signature);
      await snapshotBox.put(memberId, signed);
      state = await _loadAllSnapshots(snapshotBox);
    }
  }

  Future<void> recordAttendance(String memberId) async {
    final now = _clock.now;
    final checkInEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.checkInRecorded,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        EventPayloadKeys.memberId: memberId,
        EventPayloadKeys.updatedAt: now.toUtc().toIso8601String(),
      },
    );

    await _repo.persist(checkInEvent);

    // Audit 1.4: Near-atomic snapshot update
    final snapshotBox = Hive.lazyBox<MemberSnapshot>('snapshots');
    final current = await snapshotBox.get(memberId);
    final updated = SnapshotBuilder.apply(current, checkInEvent);
    if (updated != null) {
      final signature = await _hmac.signSnapshot(memberId, updated.toFirestore());
      final signed = updated.copyWith(hmacSignature: signature);
      await snapshotBox.put(memberId, signed);
      state = await _loadAllSnapshots(snapshotBox);
    }
  }
}
