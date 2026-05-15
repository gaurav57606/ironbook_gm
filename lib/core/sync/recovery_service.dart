import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
import 'package:ironbook_gm/core/providers/plan_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/providers/sale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../data/local/snapshot_builder.dart';

/// Service responsible for recovering all domain events from Firestore
/// and rebuilding the local database cache.
class RecoveryService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final IEventRepository _eventRepo;
  final HmacService _hmac;
  final SharedPreferences _prefs;
  final Ref _ref;

  RecoveryService(this._firestore, this._auth, this._eventRepo, this._hmac, this._prefs, this._ref);

  Future<void> recoverAll({
    void Function(int done, int total)? onProgress,
  }) async {
    final logger = _ref.read(loggerProvider);
    if (_auth == null || _firestore == null) {
      logger.warn('Firebase not initialized, skipping recovery.', category: 'RECOVERY');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      logger.info('No authenticated user, skipping recovery.', category: 'RECOVERY');
      return;
    }

    logger.info('Starting full event recovery process for user: ${user.uid}', category: 'RECOVERY');

    try {
      // 0. Fast-Path: Restore current state snapshots for immediate UI availability
      final snapshotCount = await recoverSnapshots().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.warn('Snapshot restoration timed out, proceeding to event replay.', category: 'RECOVERY');
          return 0;
        },
      );

      // 1. Mandatory: Restore all available HMAC keys to support multi-device recovery
      final keyMap = await _hmac.restoreAllUserKeys().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          logger.error('HMAC key restoration timed out.', category: 'RECOVERY');
          return <String, String>{};
        },
      );

      if (keyMap.isEmpty) {
        logger.debug('No security keys found on cloud. Attempting with local key only...', category: 'RECOVERY');
      }

      // Ensure current device key is in storage (for signing future events)
      final installationId = await _hmac.getInstallationId().timeout(const Duration(seconds: 5));
      final restored = await _hmac.restoreKeyFromFirestore(installationId).timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      
      if (!restored) {
        await _hmac.syncCurrentKeyToCloud().timeout(
          const Duration(seconds: 10),
          onTimeout: () => logger.warn('Current key sync timed out.', category: 'RECOVERY'),
        );
      }

      // Checkpoint Optimization
      final lastRecoveryTs = _prefs.getInt('last_recovery_at');
      DateTime? lastRecovery;
      if (lastRecoveryTs != null) {
        lastRecovery = DateTime.fromMillisecondsSinceEpoch(lastRecoveryTs);
        logger.info('Resuming recovery from $lastRecovery', category: 'RECOVERY');
      }

      int recoveredCount = 0;
      int tamperedCount = 0;
      DocumentSnapshot? lastDocument;
      bool hasMore = true;
      const int pageSize = 100;
      
      int totalRecovered = 0;

      while (hasMore) {
        // 2. Fetch events ordered by time with pagination
        var query = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('events')
            .orderBy('deviceTimestamp')
            .limit(pageSize);

        if (lastRecovery != null && lastDocument == null) {
            query = query.where('deviceTimestamp', isGreaterThan: Timestamp.fromDate(lastRecovery));
        }

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get().timeout(const Duration(seconds: 30));

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final docs = snapshot.docs;
        lastDocument = docs.last;

        for (int i = 0; i < docs.length; i++) {
          final doc = docs[i];
          final event = DomainEvent.fromFirestore(doc.data());
          
          // 3. Security Verification (Multi-Device Aware)
          bool isValid = false;
          final deviceKey = keyMap[event.deviceId];
          if (deviceKey != null) {
            final expectedSignature = await HmacService.signStatic(event, deviceKey);
            isValid = expectedSignature == event.hmacSignature;
          } else {
            // Fallback to current device key
            isValid = await _hmac.verifyInstance(event);
          }

          if (!isValid) {
            final reason = deviceKey == null ? 'Missing key for device ${event.deviceId}' : 'Signature mismatch';
            logger.warn('REJECTED event ${event.id} (${event.eventType.name}) - $reason', category: 'RECOVERY');
            
            // Record mismatch to Crashlytics for production debugging
            _ref.read(loggerProvider).setHealthSignal('recovery_rejection', event.id);
            tamperedCount++;
            continue;
          }

          // 4. Idempotent Persistence
          final existing = await _eventRepo.getById(event.id);
          if (existing == null) {
            event.synced = true; 
            await _eventRepo.persistSynced(event); // Bypass Outbox
            recoveredCount++;
          }
        }
        
        totalRecovered += docs.length;
        onProgress?.call(totalRecovered, totalRecovered + 1); // Indeterminate progress for pagination
      }

      // Save checkpoint
      await _prefs.setInt('last_recovery_at', DateTime.now().millisecondsSinceEpoch);

      if (tamperedCount > 0) {
        logger.critical('RECOVERY FINISHED WITH ERRORS: $tamperedCount events rejected. This indicates cryptographic or versioning issues.', category: 'RECOVERY');
      } else {
        logger.info('Event restoration complete. Recovered: $recoveredCount, All signatures valid.', category: 'RECOVERY');
      }
      
      // 5. Rebuild All Local Caches (Event Sourcing)
      final rebuildStopwatch = Stopwatch()..start();
      logger.info('Triggering full state rebuild for $recoveredCount new events...', category: 'RECOVERY');
      
      const rebuildTimeout = Duration(seconds: 45);
      
      await _ref.read(membersProvider.notifier).rebuildCache().timeout(rebuildTimeout);
      await _ref.read(ownerProvider.notifier).rebuildCache().timeout(rebuildTimeout);
      await _ref.read(settingsProvider.notifier).rebuildCache().timeout(rebuildTimeout);
      await _ref.read(planProvider.notifier).rebuildCache().timeout(rebuildTimeout);
      await _ref.read(paymentsProvider.notifier).rebuildCache().timeout(rebuildTimeout);
      await _ref.read(saleProvider.notifier).rebuildCache().timeout(rebuildTimeout);
      
      logger.info('Rebuild complete. Duration: ${rebuildStopwatch.elapsedMilliseconds}ms', category: 'RECOVERY');

      // RECOVERY DIAGNOSTICS
      final finalMembers = _ref.read(membersProvider);
      logger.info(
        '''
        --- RECOVERY DIAGNOSTICS ---
        Cloud Snapshots: $snapshotCount
        Final Local Members: ${finalMembers.length}
        Status: ${snapshotCount == finalMembers.length ? 'VERIFIED' : 'DRIFT DETECTED'}
        ---------------------------
        ''',
        category: 'RECOVERY'
      );
      logger.info('Recovery process successful.', category: 'RECOVERY');
    } catch (e, stack) {
      logger.error('Recovery process failure', category: 'RECOVERY', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<int> recoverSnapshots() async {
    final logger = _ref.read(loggerProvider);
    if (_auth == null || _firestore == null) return 0;
    final user = _auth.currentUser;
    if (user == null) return 0;

    logger.info('Restoring cloud snapshots for immediate availability...', category: 'RECOVERY');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('snapshots')
          .doc('members')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 20));

      logger.info('Snapshot query returned ${snapshot.docs.length} items from cloud.', category: 'RECOVERY');

      if (snapshot.docs.isEmpty) {
        logger.info('No cloud snapshots found for members. Trying event-based reconstruction...', category: 'RECOVERY');
        
        // If no snapshots exist, try reading the events collection directly
        // and rebuild member state from the most recent MEMBER_CREATED /
        // PAYMENT_RECORDED events per memberId
        final eventsQuery = await _firestore
            .collection('users').doc(user.uid).collection('events')
            .orderBy('deviceTimestamp', descending: false)
            .get().timeout(const Duration(seconds: 20));
        
        if (eventsQuery.docs.isNotEmpty) {
          final memberRepo = _ref.read(memberRepositoryProvider);
          final Map<String, List<DomainEvent>> byEntity = {};
          for (final doc in eventsQuery.docs) {
            final event = DomainEvent.fromFirestore(doc.data());
            byEntity.putIfAbsent(event.entityId, () => []).add(event);
          }
          int count = 0;
          for (final entry in byEntity.entries) {
            final rebuilt = SnapshotBuilder.rebuild(entry.value);
            if (rebuilt != null && !rebuilt.archived) {
              await memberRepo.upsertMember(rebuilt);
              count++;
            }
          }
          await _ref.read(membersProvider.notifier).refreshFromDB();
          return count;
        }
        
        return 0;
      }

      final memberRepo = _ref.read(memberRepositoryProvider);
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final member = MemberSnapshot.fromPayload(doc.id, data);
        
        logger.debug(
          'RECOVERY: Processed snapshot for ${member.name} (Last Updated: ${member.lastUpdated.toIso8601String()})',
          category: 'RECOVERY'
        );
        
        // Security Check: Verify snapshot integrity before trusting it
        final isValid = await _hmac.verifySnapshot(member.memberId, data, member.hmacSignature ?? '');
        if (isValid) {
          await memberRepo.upsertMember(member);
          count++;
        } else {
          logger.error('Snapshot integrity failure for member: ${member.memberId}. REJECTED.', 
            category: 'RECOVERY',
            error: 'HMAC mismatch. Potential data tampering or key loss.'
          );
        }
      }
      
      // FIXED: Use refreshFromDB() instead of init() to avoid creating a
      // duplicate StreamSubscription and to prevent checkpoint corruption.
      // init() was causing: (1) double event stream listeners, (2) member_reconcile_ts
      // being stamped to NOW which made the subsequent rebuildCache() find 0 events,
      // which then archived all snapshots and returned an empty member list.
      await _ref.read(membersProvider.notifier).refreshFromDB();
      
      logger.info('Snapshot restoration complete. Restored $count members.', category: 'RECOVERY');
      return count;
    } catch (e) {
      logger.error('Snapshot restoration failed', category: 'RECOVERY', error: e);
      // We don't fail the whole recovery if snapshots fail; event replay will still run.
      return 0;
    }
  }
}

final recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final hmac = ref.watch(hmacServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecoveryService(firestore, auth, eventRepo, hmac, prefs, ref);
});
