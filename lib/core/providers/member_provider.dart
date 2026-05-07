import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/local/snapshot_builder.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';

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

final memberProvider = Provider.family<AsyncValue<MemberSnapshot?>, String>((ref, id) {
  final members = ref.watch(membersProvider);
  final member = members.where((m) => m.memberId == id).firstOrNull;
  return AsyncValue.data(member);
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

    // 1. Real-time updates via Event Bus (Register before loading to avoid app-kill gaps)
    _repo.watch().listen((event) async {
      // ⚡ Bolt: Fast-path skip for non-member events to avoid unnecessary Disk I/O
      if (![
        EventType.memberCreated,
        EventType.memberUpdated,
        EventType.memberArchived,
        EventType.checkInRecorded,
        EventType.paymentRecorded
      ].contains(event.eventType)) {
        return;
      }

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
        
        // ⚡ Bolt: Incremental state update instead of full O(N) reload from disk
        final index = state.indexWhere((m) => m.memberId == event.entityId);
        if (index != -1) {
          state = [...state]..[index] = signed;
        } else {
          state = [...state, signed];
        }
      } else if (event.eventType == EventType.memberArchived) {
        await snapshotBox.delete(event.entityId);
        // ⚡ Bolt: Incremental state update
        state = state.where((m) => m.memberId != event.entityId).toList();
      }
    });

    final box = Hive.lazyBox<MemberSnapshot>('snapshots');
    state = await _loadAllSnapshots(box);

    // 2. Recovery & Integrity: Reconcile lagging snapshots with event log
    await _reconcileSnapshots();
  }

  Future<List<MemberSnapshot>> _loadAllSnapshots(LazyBox<MemberSnapshot> box) async {
    final keys = box.keys.toList();
    final List<MemberSnapshot> validSnapshots = [];
    const batchSize = 50;
    
    for (int i = 0; i < keys.length; i += batchSize) {
      final batch = keys.skip(i).take(batchSize).toList();

      final results = await Future.wait(batch.map((key) async {
        final snap = await box.get(key);
        if (snap == null) return null;

        // Integrity Check
        final isValid = snap.hmacSignature != null &&
            await _hmac.verifySnapshot(snap.memberId, snap.toFirestore(), snap.hmacSignature!);

        if (isValid) {
          return snap;
        } else {
          debugPrint('MemberNotifier: TAMPER DETECTED for ${snap.memberId}. Triggering automatic repair...');
          // Repair from Event Log (Write-Ahead Log)
          final history = await _repo.getByEntityId(snap.memberId);
          final repaired = SnapshotBuilder.rebuild(history);
          if (repaired != null) {
            final signature = await _hmac.signSnapshot(snap.memberId, repaired.toFirestore());
            final signed = repaired.copyWith(hmacSignature: signature);
            await box.put(snap.memberId, signed);
            return signed;
          }
        }
        return null;
      }));

      for (final res in results) {
        if (res != null) {
          validSnapshots.add(res as MemberSnapshot);
        }
      }
    }
    return validSnapshots;
  }

  Future<void> _reconcileSnapshots() async {
    // Checkpoint-based reconciliation: only process events newer than last checkpoint.
    // This is O(new events) not O(all events), keeping startup fast as gym grows.
    final metaBox = Hive.box('meta');
    final lastCheckMs = metaBox.get('member_reconcile_ts') as int? ?? 0;
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);

    final recentEvents = await _repo.getEventsSince(lastCheckTime);

    if (recentEvents.isEmpty) {
      // Nothing new since last check — update checkpoint and return fast
      await metaBox.put('member_reconcile_ts', DateTime.now().millisecondsSinceEpoch);
      return;
    }

    final box = Hive.lazyBox<MemberSnapshot>('snapshots');

    // Group recent events by entityId
    final Map<String, List<DomainEvent>> eventsByEntity = {};
    for (final e in recentEvents) {
      eventsByEntity.putIfAbsent(e.entityId, () => []).add(e);
    }

    bool updatedAny = false;
    final entityIds = eventsByEntity.keys.toList();
    const batchSize = 50;

    for (int i = 0; i < entityIds.length; i += batchSize) {
      final batch = entityIds.skip(i).take(batchSize);

      final results = await Future.wait(batch.map((entityId) async {
        final snap = await box.get(entityId);
        final latestEventTime = eventsByEntity[entityId]!
            .map((e) => e.deviceTimestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        if (snap == null || snap.lastUpdated.isBefore(latestEventTime)) {
          debugPrint('MemberNotifier: Lagging snapshot for $entityId. Rebuilding from checkpoint events...');
          // Rebuild from ALL entity events for correctness (only triggered when needed)
          final fullHistory = await _repo.getByEntityId(entityId);
          final rebuilt = SnapshotBuilder.rebuild(fullHistory);
          if (rebuilt != null) {
            final signature = await _hmac.signSnapshot(entityId, rebuilt.toFirestore());
            final signed = rebuilt.copyWith(hmacSignature: signature);
            await box.put(entityId, signed);
            return true;
          }
        }
        return false;
      }));

      if (results.any((updated) => updated)) {
        updatedAny = true;
      }
    }

    // Save checkpoint — next startup skips all events processed today
    await metaBox.put('member_reconcile_ts', DateTime.now().millisecondsSinceEpoch);

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
    String? gender,
    int? age,
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
        if (gender != null) EventPayloadKeys.gender: gender,
        if (age != null) EventPayloadKeys.age: age,
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
      
      // ⚡ Bolt: Incremental state update instead of full O(N) reload from disk
      final index = state.indexWhere((m) => m.memberId == memberId);
      if (index != -1) {
        state = [...state]..[index] = signed;
      }
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
      
      // ⚡ Bolt: Incremental state update instead of full O(N) reload from disk
      final index = state.indexWhere((m) => m.memberId == memberId);
      if (index != -1) {
        state = [...state]..[index] = signed;
      }
    }
  }
}











