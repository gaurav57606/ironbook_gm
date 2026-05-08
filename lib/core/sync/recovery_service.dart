import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';

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

    logger.info('Starting event recovery for ${user.uid}', category: 'RECOVERY');

    try {
      // 1. Mandatory: Restore all available HMAC keys to support multi-device recovery
      final keyMap = await _hmac.restoreAllUserKeys();
      if (keyMap.isEmpty) {
        logger.debug('No security keys found on cloud. Attempting with local key only...', category: 'RECOVERY');
      }

      // Ensure current device key is in storage (for signing future events)
      final installationId = await _hmac.getInstallationId();
      await _hmac.restoreKeyFromFirestore(installationId);

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
            logger.warn('REJECTED event ${event.id} - HMAC mismatch', category: 'RECOVERY');
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

      logger.info('Event restoration complete. Recovered: $recoveredCount, Rejected: $tamperedCount', category: 'RECOVERY');
      
      // 5. Rebuild Local Cache (Event Sourcing)
      logger.info('Triggering full cache rebuild...', category: 'RECOVERY');
      await _ref.read(membersProvider.notifier).rebuildCache();
      
      logger.info('Recovery process successful.', category: 'RECOVERY');
    } catch (e, stack) {
      logger.error('Recovery process failure', category: 'RECOVERY', error: e, stackTrace: stack);
      rethrow;
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
