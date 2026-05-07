import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/local/snapshot_builder.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';

final membersProvider = StateNotifierProvider<MemberNotifier, List<MemberSnapshot>>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  final memberRepo = ref.watch(memberRepositoryProvider);
  final planRepo = ref.watch(planRepositoryProvider);
  final prefRepo = ref.watch(preferencesRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return MemberNotifier(eventRepo, memberRepo, planRepo, prefRepo, clock, hmac);
});

final memberSearchQueryProvider = StateProvider<String>((ref) => '');
final memberTabProvider = StateProvider<int>((ref) => 0); // 0: All, 1: Active, 2: Expiring, 3: Expired

final filteredMembersProvider = Provider<List<MemberSnapshot>>((ref) {
  final members = ref.watch(membersProvider);
  final query = ref.watch(memberSearchQueryProvider).toLowerCase();
  final tabIndex = ref.watch(memberTabProvider);
  final now = ref.watch(clockProvider).now;

  final searched = query.isEmpty
      ? members
      : members.where((m) => m.name.toLowerCase().contains(query)).toList();

  switch (tabIndex) {
    case 1: // Active
      return searched.where((m) => m.getStatus(now) == MemberStatus.active).toList();
    case 2: // Expiring (next 7 days)
      return searched.where((m) => m.getStatus(now) == MemberStatus.expiring).toList();
    case 3: // Expired
      return searched.where((m) => m.getStatus(now) == MemberStatus.expired).toList();
    default:
      return searched;
  }
});

final memberByIdProvider = Provider.family<AsyncValue<MemberSnapshot>, String>((ref, id) {
  final members = ref.watch(membersProvider);
  final member = members.cast<MemberSnapshot?>().firstWhere((m) => m?.memberId == id, orElse: () => null);
  if (member == null) return const AsyncValue.loading();
  return AsyncValue.data(member);
});

class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final IEventRepository _eventRepo;
  final IMemberRepository _memberRepo;
  final IPlanRepository _planRepo;
  final IPreferencesRepository _prefRepo;
  final IClock _clock;
  final HmacService _hmac;
  String _deviceId = 'device-unknown';

  MemberNotifier(
    this._eventRepo,
    this._memberRepo,
    this._planRepo,
    this._prefRepo,
    this._clock,
    this._hmac,
  ) : super([]) {
    init();
  }

  @visibleForTesting
  set debugState(List<MemberSnapshot> members) => state = members;

  Future<void> init() async {
    _deviceId = await _hmac.getInstallationId();

    // 1. Real-time updates via Event Bus
    _eventRepo.watch().listen((event) async {
      if (![
        EventType.memberCreated,
        EventType.memberUpdated,
        EventType.memberArchived,
        EventType.checkInRecorded,
        EventType.paymentRecorded
      ].contains(event.eventType)) {
        return;
      }

      await _memberRepo.applyEvent(event);
      
      final updatedMember = await _memberRepo.getMember(event.entityId);
      if (updatedMember != null) {
        final index = state.indexWhere((m) => m.memberId == event.entityId);
        if (index != -1) {
          state = [...state]..[index] = updatedMember;
        } else {
          state = [...state, updatedMember];
        }
      } else if (event.eventType == EventType.memberArchived) {
        state = state.where((m) => m.memberId != event.entityId).toList();
      }
    });

    // 2. Load all members from Drift
    state = await _memberRepo.getAllMembers();

    // 3. Reconcile
    await _reconcileSnapshots();
  }

  Future<List<MemberSnapshot>> _loadAllSnapshots(LazyBox<MemberSnapshot> box) async {
    final keys = box.keys.toList();
    final List<MemberSnapshot> validSnapshots = [];
    final Map<String, MemberSnapshot> repairs = {};

    // Audit 6.2: Parallelize loading and verification in batches
    for (int i = 0; i < keys.length; i += 50) {
      final batch = keys.skip(i).take(50);
      final batchResults = await Future.wait(batch.map((key) async {
    const batchSize = 50;
    
    for (int i = 0; i < keys.length; i += batchSize) {
      final batch = keys.skip(i).take(batchSize).toList();
      final Map<String, MemberSnapshot> repairedInBatch = {};

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
            return MapEntry(key.toString(), signed);
            repairedInBatch[snap.memberId] = signed;
            return signed;
          }
        }
        return null;
      }));

      for (final result in batchResults) {
        if (result is MemberSnapshot) {
          validSnapshots.add(result);
        } else if (result is MapEntry<String, MemberSnapshot>) {
          repairs[result.key] = result.value;
          validSnapshots.add(result.value);
      if (repairedInBatch.isNotEmpty) {
        // ⚡ Bolt: Batch write repaired snapshots
        await box.putAll(repairedInBatch);
      }

      for (final res in results) {
        if (res != null) {
          validSnapshots.add(res);
        }
      }
    }

    if (repairs.isNotEmpty) {
      await box.putAll(repairs);
    }

    return validSnapshots;
  }

  Future<void> _reconcileSnapshots() async {
    const prefKey = 'member_reconcile_ts';
    final lastCheckMs = await _prefRepo.getInt(prefKey) ?? 0;
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);

    final recentEvents = await _eventRepo.getEventsSince(lastCheckTime);

    if (recentEvents.isEmpty) {
      await _prefRepo.setInt(prefKey, DateTime.now().millisecondsSinceEpoch);
      return;
    }

    final Map<String, List<DomainEvent>> eventsByEntity = {};
    for (final e in recentEvents) {
      eventsByEntity.putIfAbsent(e.entityId, () => []).add(e);
    }

    final entityIds = latestByEntity.keys.toList();
    final updates = <String, MemberSnapshot>{};

    // Audit 6.2: Parallelize reconciliation in batches to avoid Await-in-Loop bottleneck
    for (int i = 0; i < entityIds.length; i += 50) {
      final batch = entityIds.skip(i).take(50);
      final batchResults = await Future.wait(batch.map((entityId) async {
        final snap = await box.get(entityId);
        if (snap == null || snap.lastUpdated.isBefore(latestByEntity[entityId]!)) {
          debugPrint('MemberNotifier: Lagging snapshot detected for $entityId. Rebuilding...');
          final history = await _repo.getByEntityId(entityId);
          final rebuilt = SnapshotBuilder.rebuild(history);
          return rebuilt != null ? MapEntry(entityId, rebuilt) : null;
        }
        return null;
      }));

      for (final entry in batchResults) {
        if (entry != null) updates[entry.key] = entry.value;
      }
    }

    if (updates.isNotEmpty) {
      await box.putAll(updates);
      state = await _loadAllSnapshots(box);
    bool updatedAny = false;
    final entityIds = eventsByEntity.keys.toList();
    const batchSize = 50;

    for (int i = 0; i < entityIds.length; i += batchSize) {
      final batch = entityIds.skip(i).take(batchSize).toList();

      final results = await Future.wait(batch.map((entityId) async {
        final snap = await box.get(entityId);
      final Map<String, MemberSnapshot> updates = {};

      final results = await Future.wait(batch.map((entityId) async {
        final snap = await box.get(entityId);
        final events = eventsByEntity[entityId]!;
        final latestEventTime = events
    final keys = eventsByEntity.keys.toList();
    const batchSize = 50;

    for (int i = 0; i < keys.length; i += batchSize) {
      final batch = keys.skip(i).take(batchSize).toList();
      final Map<String, MemberSnapshot> updates = {};

      await Future.wait(batch.map((entityId) async {
        final snap = await box.get(entityId);
        final latestEventTime = eventsByEntity[entityId]!
            .map((e) => e.deviceTimestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        if (snap == null || snap.lastUpdated.isBefore(latestEventTime)) {
          debugPrint('MemberNotifier: Lagging snapshot for $entityId. Rebuilding from checkpoint events...');

          MemberSnapshot? rebuilt;
          if (snap == null) {
            // New member — rebuild from full history
            final fullHistory = await _repo.getByEntityId(entityId);
            rebuilt = SnapshotBuilder.rebuild(fullHistory);
          } else {
            // Existing member — incremental apply for speed
            rebuilt = snap;
            final sortedEvents = List<DomainEvent>.from(events)
              ..sort((a, b) => a.deviceTimestamp.compareTo(b.deviceTimestamp));
            for (final e in sortedEvents) {
              if (e.deviceTimestamp.isAfter(rebuilt!.lastUpdated)) {
                rebuilt = SnapshotBuilder.apply(rebuilt, e);
              }
            }
          }

          if (rebuilt != null) {
            final signature = await _hmac.signSnapshot(entityId, rebuilt.toFirestore());
            return rebuilt.copyWith(hmacSignature: signature);
          }
        }
        return null;
      }));

      for (int j = 0; j < batch.length; j++) {
        final res = results[j];
        if (res != null) {
          updates[batch[j]] = res;
          debugPrint('MemberNotifier: Lagging snapshot for ${entityId}. Rebuilding from checkpoint events...');
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

      if (results.contains(true)) {
        updatedAny = true;
            updates[entityId] = signed;
          }
    for (final entityId in eventsByEntity.keys) {
      final snap = await _memberRepo.getMember(entityId);
      final latestEventTime = eventsByEntity[entityId]!
          .map((e) => e.deviceTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      if (snap == null || snap.lastUpdated.isBefore(latestEventTime)) {
        debugPrint('MemberNotifier: Lagging Drift state for $entityId. Rebuilding from event log...');
        final fullHistory = await _eventRepo.getByEntityId(entityId);
        final rebuilt = SnapshotBuilder.rebuild(fullHistory);
        if (rebuilt != null) {
          await _memberRepo.upsertMember(rebuilt);
          updatedAny = true;
        }
      }));

      if (updates.isNotEmpty) {
        // ⚡ Bolt: Batch write updated snapshots
        await box.putAll(updates);
        updatedAny = true;
      }

      if (updates.isNotEmpty) {
        await box.putAll(updates);
      }
    }

    await _prefRepo.setInt(prefKey, DateTime.now().millisecondsSinceEpoch);

    if (updatedAny) {
      state = await _memberRepo.getAllMembers();
    }
  }

  Future<void> rebuildCache() async {
    debugPrint('MemberNotifier: Manual Drift state rebuild triggered.');
    final members = await _memberRepo.getAllMembers();
    for (final m in members) {
      await _memberRepo.deleteMember(m.memberId);
    }
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
    
    final plan = await _planRepo.getPlan(planId);
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

    await _eventRepo.persist(memberEvent);

    final snapshot = MemberSnapshot.fromPayload(memberId, memberEvent.payload);
    await _memberRepo.upsertMember(snapshot);
    final signed = await _memberRepo.getMember(memberId);
    if (signed != null) {
      state = [...state, signed];
    }

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

    await _eventRepo.persist(deleteEvent);
    await _memberRepo.deleteMember(memberId);
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
    await _eventRepo.persist(updateEvent);
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

    await _eventRepo.persist(checkInEvent);
  }
}
