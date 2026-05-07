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

    // 2. Load all members with integrity checks
    state = await _loadAllSnapshots();

    // 3. Reconcile lagging state
    await _reconcileSnapshots();
  }

  Future<List<MemberSnapshot>> _loadAllSnapshots() async {
    final allMembers = await _memberRepo.getAllMembers();
    final List<MemberSnapshot> validSnapshots = [];
    final List<String> repairRequiredIds = [];

    // Batch process HMAC verification in chunks of 50
    for (int i = 0; i < allMembers.length; i += 50) {
      final chunk = allMembers.skip(i).take(50).toList();
      final results = await Future.wait(chunk.map((snap) async {
        if (snap.hmacSignature == null) return MapEntry(snap.memberId, false);
        final isValid = await _hmac.verifySnapshot(snap.memberId, snap.toFirestore(), snap.hmacSignature!);
        return MapEntry(snap.memberId, isValid);
      }));

      for (int j = 0; j < chunk.length; j++) {
        final snap = chunk[j];
        final isValid = results[j].value;
        if (isValid) {
          validSnapshots.add(snap);
        } else {
          debugPrint('MemberNotifier: TAMPER DETECTED for ${snap.memberId}. Repair required.');
          repairRequiredIds.add(snap.memberId);
        }
      }
    }

    if (repairRequiredIds.isNotEmpty) {
      final histories = await _eventRepo.getByEntityIds(repairRequiredIds);
      final List<MemberSnapshot> repairedSnapshots = [];

      for (final entityId in repairRequiredIds) {
        final history = histories[entityId] ?? [];
        final rebuilt = SnapshotBuilder.rebuild(history);
        if (rebuilt != null) {
          repairedSnapshots.add(rebuilt);
        }
      }

      if (repairedSnapshots.isNotEmpty) {
        await _memberRepo.upsertMembers(repairedSnapshots);
        validSnapshots.addAll(repairedSnapshots);
      }
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

    final List<String> entityIdsToCheck = eventsByEntity.keys.toList();
    final existingSnaps = await _memberRepo.getMembers(entityIdsToCheck);
    final snapMap = {for (final s in existingSnaps) s.memberId: s};

    final List<String> laggingIds = [];
    for (final entityId in entityIdsToCheck) {
      final snap = snapMap[entityId];
      final latestEventTime = eventsByEntity[entityId]!
          .map((e) => e.deviceTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      if (snap == null || snap.lastUpdated.isBefore(latestEventTime)) {
        laggingIds.add(entityId);
      }
    }

    if (laggingIds.isNotEmpty) {
      debugPrint('MemberNotifier: Found ${laggingIds.length} lagging members. Rebuilding in batch...');
      final histories = await _eventRepo.getByEntityIds(laggingIds);
      final List<MemberSnapshot> rebuiltSnapshots = [];

      for (final entityId in laggingIds) {
        final history = histories[entityId] ?? [];
        final rebuilt = SnapshotBuilder.rebuild(history);
        if (rebuilt != null) {
          rebuiltSnapshots.add(rebuilt);
        }
      }

      if (rebuiltSnapshots.isNotEmpty) {
        await _memberRepo.upsertMembers(rebuiltSnapshots);
        state = await _loadAllSnapshots();
      }
    }

    await _prefRepo.setInt(prefKey, DateTime.now().millisecondsSinceEpoch);
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
