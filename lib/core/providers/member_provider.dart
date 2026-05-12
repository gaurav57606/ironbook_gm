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
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:collection/collection.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/services/membership_service.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/services/notification_service.dart';
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
  final membership = ref.watch(membershipServiceProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);
  final logger = ref.watch(loggerProvider);
  return MemberNotifier(
      db, eventRepo, memberRepo, planRepo, prefRepo, clock, hmac, membership, coordinator, logger);
});

final memberSearchQueryProvider = StateProvider<String>((ref) => '');
final memberTabProvider = StateProvider<int>(
    (ref) => 0); // 0: All, 1: Active, 2: Expiring, 3: Expired

class MemberStats {
  final int totalCount;
  final int activeCount;
  final int expiringCount;
  final int expiredCount;

  MemberStats({
    required this.totalCount,
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberStats &&
          runtimeType == other.runtimeType &&
          totalCount == other.totalCount &&
          activeCount == other.activeCount &&
          expiringCount == other.expiringCount &&
          expiredCount == other.expiredCount;

  @override
  int get hashCode =>
      totalCount.hashCode ^
      activeCount.hashCode ^
      expiringCount.hashCode ^
      expiredCount.hashCode;
}

final memberStatsProvider = Provider<MemberStats>((ref) {
  final members = ref.watch(membersProvider);
  final now = ref.watch(clockProvider).now;

  int active = 0;
  int expiring = 0;
  int expired = 0;

  for (final m in members) {
    final status = m.getStatus(now);
    if (status == MemberStatus.active) {
      active++;
    } else if (status == MemberStatus.expiring) {
      expiring++;
    } else if (status == MemberStatus.expired) {
      expired++;
    }
  }

  return MemberStats(
    totalCount: members.length,
    activeCount: active,
    expiringCount: expiring,
    expiredCount: expired,
  );
});

final memberByIdProvider = Provider.family<MemberSnapshot?, String>((ref, id) {
  final members = ref.watch(membersProvider);
  return members.firstWhereOrNull((m) => m.memberId == id);
});

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


class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final db.OutboxDatabase _db;
  final IEventRepository _eventRepo;
  final IMemberRepository _memberRepo;
  final IPlanRepository _planRepo;
  final IPreferencesRepository _prefRepo;
  final IClock _clock;
  final HmacService _hmac;
  final MembershipService _membership;
  final SyncCoordinator _coordinator;
  final LoggerService _logger;
  String _deviceId = 'device-unknown';
  StreamSubscription? _eventSubscription;

  // Duplicate Prevention: Track recent creations to avoid rapid double-taps
  final Map<String, DateTime> _recentCreations = {};

  MemberNotifier(
    db.OutboxDatabase db,
    this._eventRepo,
    this._memberRepo,
    this._planRepo,
    this._prefRepo,
    this._clock,
    this._hmac,
    this._membership,
    this._coordinator,
    this._logger,
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

        _logger.debug(
          'Processing event ${event.eventType} for ${event.entityId}', 
          category: 'STATE'
        );
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
      _logger.info(
        'Loading initial members from repository', 
        category: 'DB'
      );
      final members = await _memberRepo.getAllMembers();
      if (mounted) {
        state = members;
        _logger.info(
          'Loaded ${state.length} members', 
          category: 'STATE'
        );
      }

      // 3. Reconcile
      if (mounted) {
        await _reconcileSnapshots();
      }
    } catch (e) {
      _logger.warn(
        'Init failed (likely due to disposal/teardown): $e', 
        category: 'STATE'
      );
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
        _logger.warn(
          'Lagging Drift state for $entityId. Rebuilding from event log...', 
          category: 'DB'
        );
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
    _logger.warn(
      'Manual full cache rebuild triggered.', 
      category: 'DB'
    );

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
    _logger.info(
      'Rebuild complete. ${state.length} members.', 
      category: 'DB'
    );
  }

  Future<String> addMember({
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
    String? gender,
    int? age,
  }) async {
    final now = _clock.now;
    
    // Audit Check 6.1: Simple throttle (5 seconds)
    final lastAction = _recentCreations[phone];
    if (lastAction != null && now.difference(lastAction).inSeconds < 5) {
      _logger.warn(
        'Ignoring rapid duplicate member creation for $phone', 
        category: 'STATE'
      );
      // Return existing memberId if possible, but here we just return a dummy or wait
      // For now, throwing an error is safer for "Production Hardening" to notify the user/system
      throw Exception('Request already in progress. Please wait.');
    }
    _recentCreations[phone] = now;

    // Audit Check 6.2: Logical Duplicate Check
    final existing = state.any((m) => 
      m.phone == phone && m.status != MemberStatus.archived
    );
    
    if (existing) {
      _logger.warn(
        'Member with phone $phone already exists and is active.', 
        category: 'STATE'
      );
      throw Exception('A member with this phone number already exists.');
    }

    final memberId = const Uuid().v4();

    final plan = await _planRepo.getPlan(planId);
    if (plan == null) throw Exception('Plan not found');

    // Calculate expiry using authoritative service
      // Safety Validation (Audit Check 1.6)
      _membership.validateMembership(
        joinDate: joinDate,
        durationMonths: plan.durationMonths,
      );

      final expiryDate = _membership.calculateExpiry(
      startDate: joinDate,
      durationMonths: plan.durationMonths,
    );

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
        _logger.info(
          'Starting addMember for $memberId', 
          category: 'TRANSACTION'
        );
        // 1. Sign and persist the event FIRST
        await _eventRepo.persist(memberEvent);

        // 2. THEN derive snapshot from event payload
        final snapshot = MemberSnapshot.fromPayload(memberId, memberEvent.payload);

        // 3. THEN store snapshot in Drift
        await _memberRepo.upsertMember(snapshot);
        _logger.info(
          'addMember transaction complete', 
          category: 'TRANSACTION'
        );
      });

      // 4. Trigger immediate sync
      _coordinator.triggerSync();

      // 5. Trigger live notification
      NotificationService.sendNewMemberAlert(
        memberId: memberId,
        name: name,
        planName: plan.name,
      );

      return memberId;
    } catch (e) {
      // Event or snapshot write failed — clean up any partial state
      await _memberRepo.deleteMember(memberId); // safe: member was never valid
      _logger.error(
        'addMember failed for $memberId', 
        category: 'STATE', 
        error: e
      );
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

    _logger.info(
      'Archiving member $memberId', 
      category: 'DB'
    );
    await _db.transaction(() async {
      _logger.info(
        'Starting deleteMember for $memberId', 
        category: 'TRANSACTION'
      );
      await _eventRepo.persist(archiveEvent);

      // Archive in Drift — keep the row, mark as archived
      await _memberRepo.archiveMember(memberId);
      _logger.info(
        'deleteMember transaction complete', 
        category: 'TRANSACTION'
      );
    });

    _logger.debug(
      'Triggering sync after archive', 
      category: 'SYNC'
    );
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

    _logger.info(
      'Updating member $memberId', 
      category: 'DB'
    );
    
    await _db.transaction(() async {
      _logger.info(
        'Starting updateMember for $memberId', 
        category: 'TRANSACTION'
      );
      await _eventRepo.persist(updateEvent);

      // Apply directly to Drift without waiting for watch stream
      await _memberRepo.applyEvent(updateEvent);
      _logger.info(
        'updateMember transaction complete', 
        category: 'TRANSACTION'
      );
    });

    _logger.debug(
      'Triggering sync after update', 
      category: 'SYNC'
    );
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
      _logger.info(
        'Starting recordAttendance for $memberId', 
        category: 'TRANSACTION'
      );
      await _eventRepo.persist(checkInEvent);
      await _memberRepo.applyEvent(checkInEvent);
      _logger.info(
        'recordAttendance transaction complete', 
        category: 'TRANSACTION'
      );
    });

    _coordinator.triggerSync();
  }
}
