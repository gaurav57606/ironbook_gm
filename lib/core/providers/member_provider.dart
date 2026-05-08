import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
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
import 'package:collection/collection.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'dart:async';

final membersProvider =
    StateNotifierProvider<MemberNotifier, List<MemberSnapshot>>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  final memberRepo = ref.watch(memberRepositoryProvider);
  final planRepo = ref.watch(planRepositoryProvider);
  final prefRepo = ref.watch(preferencesRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  final db = ref.watch(outboxDatabaseProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);
  return MemberNotifier(
      db, eventRepo, memberRepo, planRepo, prefRepo, clock, hmac, coordinator);
});

final memberSearchQueryProvider = StateProvider<String>((ref) => '');
final memberTabProvider = StateProvider<int>(
    (ref) => 0); // 0: All, 1: Active, 2: Expiring, 3: Expired

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
      return searched
          .where((m) => m.getStatus(now) == MemberStatus.active)
          .toList();
    case 2: // Expiring (next 7 days)
      return searched
          .where((m) => m.getStatus(now) == MemberStatus.expiring)
          .toList();
    case 3: // Expired
      return searched
          .where((m) => m.getStatus(now) == MemberStatus.expired)
          .toList();
    default:
      return searched;
  }
});

final memberProvider = Provider.family<MemberSnapshot?, String>((ref, id) {
  final members = ref.watch(membersProvider);
  return members.firstWhereOrNull((m) => m.memberId == id);
});

final memberByIdProvider =
    Provider.family<AsyncValue<MemberSnapshot>, String>((ref, id) {
  final members = ref.watch(membersProvider);
  final member = members
      .cast<MemberSnapshot?>()
      .firstWhere((m) => m?.memberId == id, orElse: () => null);
  if (member == null) return const AsyncValue.loading();
  return AsyncValue.data(member);
});

class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final db.OutboxDatabase _db;
  final IEventRepository _eventRepo;
  final IMemberRepository _memberRepo;
  final IPlanRepository _planRepo;
  final IPreferencesRepository _prefRepo;
  final IClock _clock;
  final HmacService _hmac;
  final SyncCoordinator _coordinator;
  String _deviceId = 'device-unknown';
  StreamSubscription? _eventSubscription;

  MemberNotifier(
    db.OutboxDatabase db,
    this._eventRepo,
    this._memberRepo,
    this._planRepo,
    this._prefRepo,
    this._clock,
    this._hmac,
    this._coordinator,
  ) : _db = db, super([]) {
    init();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @visibleForTesting
  set debugState(List<MemberSnapshot> members) => state = members;

  Future<void> init() async {
    try {
      _deviceId = await _hmac.getInstallationId();

      // 1. Real-time updates via Event Bus (Single Source of Truth)
      _eventSubscription = _eventRepo.watch().listen((event) async {
        if (![
          EventType.memberCreated,
          EventType.memberUpdated,
          EventType.memberArchived,
          EventType.checkInRecorded,
          EventType.paymentRecorded
        ].contains(event.eventType)) {
          return;
        }

        if (!mounted) return;

        debugPrint('[STATE] MemberNotifier: Processing event ${event.eventType} for ${event.entityId}');
        await _memberRepo.applyEvent(event);

        if (!mounted) return;

        final updatedMember = await _memberRepo.getMember(event.entityId);
        if (mounted) {
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
        }
      });

      // 2. Load all members from Drift
      debugPrint('[DB] MemberNotifier: Loading initial members from repository');
      final members = await _memberRepo.getAllMembers();
      if (mounted) {
        state = members;
        debugPrint('[STATE] MemberNotifier: Loaded ${state.length} members');
      }

      // 3. Reconcile
      if (mounted) {
        await _reconcileSnapshots();
      }
    } catch (e) {
      debugPrint('[WARN] MemberNotifier: Init failed (likely due to disposal/teardown): $e');
    }
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

    bool updatedAny = false;
    for (final entityId in eventsByEntity.keys) {
      final snap = await _memberRepo.getMember(entityId);
      final latestEventTime = eventsByEntity[entityId]!
          .map((e) => e.deviceTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      if (snap == null || snap.lastUpdated.isBefore(latestEventTime)) {
        debugPrint(
            'MemberNotifier: Lagging Drift state for $entityId. Rebuilding from event log...');
        final fullHistory = await _eventRepo.getByEntityId(entityId);
        final rebuilt = SnapshotBuilder.rebuild(fullHistory);
        if (rebuilt != null) {
          await _memberRepo.upsertMember(rebuilt);
          if (!rebuilt.archived) updatedAny = true;
        }
      }
    }

    await _prefRepo.setInt(prefKey, DateTime.now().millisecondsSinceEpoch);

    if (updatedAny) {
      state = await _memberRepo.getAllMembers();
    }
  }

  Future<void> rebuildCache() async {
    debugPrint('MemberNotifier: Manual full cache rebuild triggered.');

    // Reset checkpoint so _reconcileSnapshots processes ALL events
    await _prefRepo.setInt('member_reconcile_ts', 0);

    // Clear all existing Drift rows so we start from scratch
    final members = await _memberRepo.getAllMembers();
    for (final m in members) {
      await _memberRepo.archiveMember(m.memberId); // archive, not hard-delete
    }

    // Rebuild from full event history
    await _reconcileSnapshots();

    // Reload state
    state = await _memberRepo.getAllMembers();
    debugPrint('MemberNotifier: Rebuild complete. ${state.length} members.');
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

    try {
      await _db.transaction(() async {
        debugPrint('[TRANSACTION] MemberNotifier: Starting addMember for $memberId');
        // 1. Sign and persist the event FIRST
        await _eventRepo.persist(memberEvent);

        // 2. THEN derive snapshot from event payload
        final snapshot = MemberSnapshot.fromPayload(memberId, memberEvent.payload);

        // 3. THEN store snapshot in Drift
        await _memberRepo.upsertMember(snapshot);
        debugPrint('[TRANSACTION] MemberNotifier: addMember transaction complete');
      });

      // 4. Trigger immediate sync
      _coordinator.triggerSync();
      return memberId;
    } catch (e) {
      // Event or snapshot write failed — clean up any partial state
      await _memberRepo.deleteMember(memberId); // safe: member was never valid
      debugPrint('[STATE] MemberNotifier: addMember failed for $memberId: $e');
      rethrow;
    }
  }

  Future<void> deleteMember(String memberId) async {
    final archiveEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberArchived,
      deviceId: _deviceId,
      deviceTimestamp: _clock.now,
      payload: {'memberId': memberId},
    );

    debugPrint('[DB] MemberNotifier: Archiving member $memberId');
    await _db.transaction(() async {
      debugPrint('[TRANSACTION] MemberNotifier: Starting deleteMember for $memberId');
      await _eventRepo.persist(archiveEvent);

      // Archive in Drift — keep the row, mark as archived
      await _memberRepo.archiveMember(memberId);
      debugPrint('[TRANSACTION] MemberNotifier: deleteMember transaction complete');
    });

    debugPrint('[SYNC] MemberNotifier: Triggering sync after archive');
    _coordinator.triggerSync();
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

    debugPrint('[DB] MemberNotifier: Updating member $memberId');
    
    await _db.transaction(() async {
      debugPrint('[TRANSACTION] MemberNotifier: Starting updateMember for $memberId');
      await _eventRepo.persist(updateEvent);

      // Apply directly to Drift without waiting for watch stream
      await _memberRepo.applyEvent(updateEvent);
      debugPrint('[TRANSACTION] MemberNotifier: updateMember transaction complete');
    });

    debugPrint('[SYNC] MemberNotifier: Triggering sync after update');
    _coordinator.triggerSync();
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

    await _db.transaction(() async {
      debugPrint('[TRANSACTION] MemberNotifier: Starting recordAttendance for $memberId');
      await _eventRepo.persist(checkInEvent);
      await _memberRepo.applyEvent(checkInEvent);
      debugPrint('[TRANSACTION] MemberNotifier: recordAttendance transaction complete');
    });

    _coordinator.triggerSync();
  }
}
