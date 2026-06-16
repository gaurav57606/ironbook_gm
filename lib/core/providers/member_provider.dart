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
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/services/membership_service.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/services/notification_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';

enum MemberSortOption { expiryAsc, expiryDesc, nameAz, nameZa, joinNewest }

final memberSortProvider =
    StateProvider<MemberSortOption>((ref) => MemberSortOption.expiryAsc);

final dailyClockTickProvider = StreamProvider<DateTime>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return Stream.value(DateTime.now());
  }
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now())
      .asBroadcastStream();
});

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
  return MemberNotifier(db, eventRepo, memberRepo, planRepo, prefRepo, clock,
      hmac, membership, coordinator, logger);
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
  ref.watch(dailyClockTickProvider); // subscribe — causes re-eval every minute
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
  ref.watch(dailyClockTickProvider); // subscribe — causes re-eval every minute
  final members = ref.watch(membersProvider);
  final query = ref.watch(memberSearchQueryProvider).toLowerCase();
  final tabIndex = ref.watch(memberTabProvider);
  final now = ref.watch(clockProvider).now;
  final sort = ref.watch(memberSortProvider);

  final List<MemberSnapshot> filtered = [];

  for (final m in members) {
    // 1. Search Filter
    if (query.isNotEmpty) {
      if (!m.name.toLowerCase().contains(query) &&
          !(m.phone?.toLowerCase().contains(query) ?? false)) {
        continue;
      }
    }

    // 2. Tab Filter
    if (tabIndex > 0) {
      final status = m.getStatus(now);
      if (tabIndex == 1 && status != MemberStatus.active) continue;
      if (tabIndex == 2 && status != MemberStatus.expiring) continue;
      if (tabIndex == 3 && status != MemberStatus.expired) continue;
    }

    filtered.add(m);
  }

  // Apply sorting
  switch (sort) {
    case MemberSortOption.expiryAsc:
      filtered.sort((a, b) => (a.expiryDate ?? DateTime(2099))
          .compareTo(b.expiryDate ?? DateTime(2099)));
      break;
    case MemberSortOption.expiryDesc:
      filtered.sort((a, b) => (b.expiryDate ?? DateTime(2000))
          .compareTo(a.expiryDate ?? DateTime(2000)));
      break;
    case MemberSortOption.nameAz:
      filtered
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case MemberSortOption.nameZa:
      filtered
          .sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      break;
    case MemberSortOption.joinNewest:
      filtered.sort((a, b) => (b.joinDate ?? DateTime(2000))
          .compareTo(a.joinDate ?? DateTime(2000)));
      break;
  }

  return filtered;
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
  bool _isRebuilding = false;
  StreamSubscription? _eventSubscription;

  // Duplicate Prevention: Track recent creations to avoid rapid double-taps
  final Map<String, DateTime> _recentCreations = {};

  Completer<void>? _initCompleter;

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
  )   : _db = db,
        super([]) {
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
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    final stopwatch = Stopwatch()..start();
    try {
      unawaited(Future.microtask(() async {
        try {
          _deviceId = await _hmac.getInstallationId().timeout(
                const Duration(seconds: 5),
                onTimeout: () => 'device-fallback',
              );
        } catch (_) {
          _deviceId = 'device-fallback';
        }
      }));

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
            category: 'STATE');

        // Critical: Apply event to repository
        await _memberRepo.applyEvent(event);

        if (!mounted) return;

        // Archive Branch: If member archived, remove from repository physically
        // This ensures Hive/Drift snapshots don't diverge from Event Log
        if (event.eventType == EventType.memberArchived) {
          await _memberRepo.deleteMember(event.entityId);
          if (mounted) {
            state = state.where((m) => m.memberId != event.entityId).toList();
          }
          return;
        }

        final updatedMember = await _memberRepo.getMember(event.entityId);
        if (mounted && updatedMember != null) {
          final index = state.indexWhere((m) => m.memberId == event.entityId);
          if (index != -1) {
            state = [...state]..[index] = updatedMember;
          } else {
            state = [...state, updatedMember];
          }
        }
      });

      // 2. Load all members from storage
      await _loadAllSnapshots();

      // 3. Reconcile with event log
      if (mounted) {
        await _reconcileSnapshots();
      }

      _initCompleter!.complete();
      _logger.info('Init complete in ${stopwatch.elapsedMilliseconds}ms',
          category: 'STATE');
    } catch (e, stack) {
      _initCompleter?.completeError(e, stack);
      _initCompleter = null; // Allow retry
      _logger.error(
        'Init failed: $e',
        category: 'STATE',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Trigger deep reconciliation manually. Useful for testing and recovery.
  Future<void> reconcile() => _reconcileSnapshots();

  Future<void> _loadAllSnapshots() async {
    _logger.info('Loading initial members from repository', category: 'DB');
    final members = await _memberRepo.getAllMembers();
    if (mounted) {
      state = members;
    }
  }

  Future<void> _reconcileSnapshots({bool updateCheckpoint = true}) async {
    const prefKey = 'member_reconcile_ts';
    final lastCheckMs = await _prefRepo.getInt(prefKey) ?? 0;
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);

    final recentEvents = await _eventRepo.getEventsSince(lastCheckTime);

    final Map<String, List<DomainEvent>> eventsByEntity = {};
    for (final e in recentEvents) {
      eventsByEntity.putIfAbsent(e.entityId, () => []).add(e);
    }

    final Map<String, MemberSnapshot> updates = {};
    final List<String> deletes = [];

    // 1. Identify lagging or tampered snapshots
    if (eventsByEntity.isNotEmpty) {
      await Future.wait(eventsByEntity.keys.map((entityId) async {
        final snap = await _memberRepo.getMember(entityId);
        final events = eventsByEntity[entityId]!;
        final latestEventTime = events
            .map((e) => e.deviceTimestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        bool needsRebuild =
            snap == null || snap.lastUpdated.isBefore(latestEventTime);

        // Tampered Repair: Verify HMAC integrity seal
        if (!needsRebuild && snap != null) {
          final isValid = await _hmac.verifySnapshot(
              snap.memberId, snap.toFirestore(), snap.hmacSignature ?? '');
          if (!isValid) {
            _logger.error(
                'Tampered snapshot detected for $entityId! Repairing...',
                category: 'SECURITY');
            needsRebuild = true;
          }
        }

        if (needsRebuild) {
          final fullHistory = await _eventRepo.getByEntityId(entityId);
          final rebuilt = SnapshotBuilder.rebuild(fullHistory);

          if (rebuilt != null) {
            if (rebuilt.archived) {
              deletes.add(entityId);
            } else {
              updates[entityId] = rebuilt;
            }
          } else if (snap != null) {
            // Dummy User Cleanup: Snapshot exists but no events found
            _logger.warn('Dummy user detected for $entityId. Cleaning up...',
                category: 'DB');
            deletes.add(entityId);
          }
        }
      }));
    }

    // 2. Efficient Dummy Cleanup: Detect members in storage with NO event history
    // Only run if we found no events recently or periodically
    if (recentEvents.isEmpty || lastCheckMs % 5 == 0) {
      // Simple heuristic or just always for safety in this task
      try {
        final allStorageMembers = await _memberRepo.getAllMembers();
        final allEventEvents = await _eventRepo.getAllEvents();
        final allEventIds = allEventEvents.map((e) => e.entityId).toSet();

        for (final m in allStorageMembers) {
          if (!allEventIds.contains(m.memberId)) {
            if (!deletes.contains(m.memberId)) {
              _logger.warn('Orphan snapshot found: ${m.memberId}. Purging...',
                  category: 'DB');
              deletes.add(m.memberId);
            }
          }
        }
      } catch (e, stack) {
        _logger.error('Error checking for orphan snapshots: $e',
            category: 'DB', error: e, stackTrace: stack);
      }
    }

    // 3. Batch apply changes
    if (updates.isNotEmpty) {
      await _memberRepo.upsertMembers(updates.values.toList());
    }

    if (deletes.isNotEmpty) {
      await Future.wait(deletes.map((id) => _memberRepo.deleteMember(id)));
    }

    if (updateCheckpoint) {
      try {
        await _prefRepo.setInt(prefKey, DateTime.now().millisecondsSinceEpoch);
      } catch (e, stack) {
        _logger.error('Error saving reconcile checkpoint: $e',
            category: 'DB', error: e, stackTrace: stack);
      }
    }

    if (updates.isNotEmpty || deletes.isNotEmpty) {
      state = await _memberRepo.getAllMembers();
    }
  }

  /// Rebuilds the member cache from the full event history.
  /// SAFE: Saves backup before any writes. Only replaces state if event replay
  /// produces results. Falls back to backup if event replay returns empty,
  /// preventing snapshot data loss when events haven't synced yet.
  Future<void> rebuildCache() async {
    if (_isRebuilding) {
      _logger.warn('rebuildCache: Already in progress, skipping.',
          category: 'DB');
      return;
    }
    _isRebuilding = true;

    final stopwatch = Stopwatch()..start();
    _logger.warn('Manual full cache rebuild triggered.', category: 'DB');

    final backup = List<MemberSnapshot>.from(state);

    try {
      await Future.delayed(Duration.zero);

      final allEvents = await _eventRepo.getAllEvents();
      final Map<String, List<DomainEvent>> byEntity = {};

      for (final e in allEvents) {
        byEntity.putIfAbsent(e.entityId, () => []).add(e);
      }

      final List<MemberSnapshot> updates = [];
      final List<String> deletes = [];

      for (final entry in byEntity.entries) {
        final rebuilt = SnapshotBuilder.rebuild(entry.value);
        if (rebuilt != null) {
          if (rebuilt.archived) {
            deletes.add(entry.key);
          } else {
            updates.add(rebuilt);
          }
        }
      }

      // Dummy Cleanup: Remove entries in DB that have no events
      final existingIds =
          (await _memberRepo.getAllMembers()).map((m) => m.memberId).toSet();
      final eventIds = byEntity.keys.toSet();
      final dummyIds = existingIds.difference(eventIds);
      deletes.addAll(dummyIds);

      // Batch updates
      if (updates.isNotEmpty) {
        await _memberRepo.upsertMembers(updates);
      }

      // Batch deletes (parallelized)
      if (deletes.isNotEmpty) {
        await Future.wait(deletes.map((id) => _memberRepo.deleteMember(id)));
      }

      final rebuiltResult = await _memberRepo.getAllMembers();

      if (rebuiltResult.isNotEmpty) {
        state = rebuiltResult;
        _logger.info(
          'rebuildCache: Rebuilt ${state.length} members from events in '
          '${stopwatch.elapsedMilliseconds}ms.',
          category: 'DB',
        );
      } else if (backup.isNotEmpty) {
        _logger.warn(
          'rebuildCache: Event replay produced 0 members. Fallback to backup.',
          category: 'DB',
        );
        await _memberRepo.upsertMembers(backup);
        state = backup;
      } else {
        state = [];
      }
    } catch (e, stack) {
      // On any unhandled exception, immediately restore backup
      _logger.error(
        'rebuildCache: FAILED. Restoring ${backup.length} backup members.',
        category: 'DB',
        error: e,
        stackTrace: stack,
      );
      if (backup.isNotEmpty) {
        for (final m in backup) {
          await _memberRepo.upsertMember(m);
        }
        state = backup;
      }
      rethrow;
    } finally {
      _isRebuilding = false;
    }
  }

  /// Safe UI refresh — reloads state from Drift without re-initializing streams.
  /// Called by RecoveryService after snapshot restoration instead of init().
  /// This avoids creating duplicate StreamSubscriptions on the event table
  /// and prevents member_reconcile_ts from being stamped prematurely.
  Future<void> refreshFromDB() async {
    final members = await _memberRepo.getAllMembers();
    if (mounted) {
      state = members;
      _logger.info(
        'refreshFromDB: Loaded ${members.length} members from Drift.',
        category: 'STATE',
      );
    }
  }

  Future<String> addMember({
    String? passedMemberId,
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
    String? gender,
    int? age,
    String? photoUrl,
  }) async {
    final now = _clock.now;

    // Audit Check 6.1: Simple throttle (5 seconds)
    final lastAction = _recentCreations[phone];
    if (lastAction != null && now.difference(lastAction).inSeconds < 5) {
      _logger.warn('Ignoring rapid duplicate member creation for $phone',
          category: 'STATE');
      throw Exception('Request already in progress. Please wait.');
    }
    _recentCreations[phone] = now;

    // Audit Check 6.2: Logical Duplicate Check
    final existing =
        state.any((m) => m.phone == phone && m.status != MemberStatus.archived);

    if (existing) {
      _logger.warn('Member with phone $phone already exists and is active.',
          category: 'STATE');
      throw Exception('A member with this phone number already exists.');
    }

    final memberId = passedMemberId ?? const Uuid().v4();

    final plan = await _planRepo.getPlan(planId);
    if (plan == null) throw Exception('Plan not found');

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
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );

    try {
      await _db.transaction(() async {
        _logger.info('Starting addMember for $memberId',
            category: 'TRANSACTION');
        // 1. Sign and persist the event FIRST
        await _eventRepo.persist(memberEvent);

        // 2. THEN derive snapshot from event payload
        final snapshot =
            MemberSnapshot.fromPayload(memberId, memberEvent.payload);

        // 3. THEN store snapshot in Drift
        await _memberRepo.upsertMember(snapshot);
      });

      // Immediate state update for UI responsiveness
      if (mounted) {
        final snap = await _memberRepo.getMember(memberId);
        if (snap != null) {
          state = [...state, snap];
        }
      }

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
      await _memberRepo.deleteMember(memberId);
      _logger.error('addMember failed for $memberId',
          category: 'STATE', error: e);
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

    _logger.info('Archiving member $memberId', category: 'DB');
    await _db.transaction(() async {
      _logger.info('Starting deleteMember for $memberId',
          category: 'TRANSACTION');
      await _eventRepo.persist(archiveEvent);
      // Critical: Use applyEvent to ensure physical deletion for Drift
      await _memberRepo.applyEvent(archiveEvent);
      _logger.info('deleteMember transaction complete',
          category: 'TRANSACTION');
    });

    // Immediate state update for UI responsiveness
    if (mounted) {
      state = state.where((m) => m.memberId != memberId).toList();
    }

    _logger.debug('Triggering sync after archive', category: 'SYNC');
    _coordinator.triggerSync();
  }

  Future<void> updateMember({
    required String memberId,
    required String name,
    required String phone,
    String? photoUrl,
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
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );

    _logger.info('Updating member $memberId', category: 'DB');

    await _db.transaction(() async {
      _logger.info('Starting updateMember for $memberId',
          category: 'TRANSACTION');
      await _eventRepo.persist(updateEvent);
      await _memberRepo.applyEvent(updateEvent);
    });

    // Immediate state update for UI responsiveness
    final updated = await _memberRepo.getMember(memberId);
    if (mounted && updated != null) {
      final index = state.indexWhere((m) => m.memberId == memberId);
      if (index != -1) {
        state = [...state]..[index] = updated;
      }
    }

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
      _logger.info('Starting recordAttendance for $memberId',
          category: 'TRANSACTION');
      await _eventRepo.persist(checkInEvent);
      await _memberRepo.applyEvent(checkInEvent);
    });

    // Immediate state update for UI responsiveness
    final updated = await _memberRepo.getMember(memberId);
    if (mounted && updated != null) {
      final index = state.indexWhere((m) => m.memberId == memberId);
      if (index != -1) {
        state = [...state]..[index] = updated;
      }
    }

    _coordinator.triggerSync();
  }

  Future<void> updateMemberPhoto(String memberId, String photoPath) async {
    final member = state.firstWhereOrNull((m) => m.memberId == memberId);
    if (member == null) return;

    final updated = member.copyWith(photoPath: photoPath);

    final updateEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberUpdated,
      deviceId: _deviceId,
      deviceTimestamp: _clock.now,
      payload: {
        EventPayloadKeys.memberId: memberId,
        'photoPath': photoPath,
      },
    );

    await _db.transaction(() async {
      await _eventRepo.persist(updateEvent);
      await _memberRepo.applyEvent(updateEvent);
    });

    final dbMember = await _memberRepo.getMember(memberId);
    if (mounted && dbMember != null) {
      final index = state.indexWhere((m) => m.memberId == memberId);
      if (index != -1) {
        state = [...state]..[index] = dbMember;
      }
    }

    _coordinator.triggerSync();
  }
}
