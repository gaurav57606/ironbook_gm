import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for recovering all domain events from Firestore
/// and rebuilding the local database cache.
class RecoveryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final IEventRepository _eventRepo;
  final HmacService _hmac;
  final SharedPreferences _prefs;
  final Ref _ref;

  RecoveryService(this._firestore, this._auth, this._eventRepo, this._hmac, this._prefs, this._ref);

  Future<void> recoverAll({
    void Function(int done, int total)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('RecoveryService: Starting event recovery for ${user.uid}');

    try {
      // 1. Mandatory: Restore all available HMAC keys to support multi-device recovery
      final keyMap = await _hmac.restoreAllUserKeys();
      if (keyMap.isEmpty) {
        debugPrint('RecoveryService: No security keys found on cloud. Attempting with local key only...');
      }

      // Ensure current device key is in storage (for signing future events)
      final installationId = await _hmac.getInstallationId();
      await _hmac.restoreKeyFromFirestore(installationId);

      // Checkpoint Optimization
      final lastRecoveryTs = _prefs.getInt('last_recovery_at');
      DateTime? lastRecovery;
      if (lastRecoveryTs != null) {
        lastRecovery = DateTime.fromMillisecondsSinceEpoch(lastRecoveryTs);
        debugPrint('RecoveryService: Resuming recovery from $lastRecovery');
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
            debugPrint('RecoveryService: REJECTED event ${event.id} - HMAC mismatch');
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

      debugPrint('RecoveryService: Event restoration complete. Recovered: $recoveredCount, Rejected: $tamperedCount');
      
      // 5. Rebuild Local Cache (Event Sourcing)
      debugPrint('RecoveryService: Triggering full cache rebuild...');
      await _ref.read(membersProvider.notifier).rebuildCache();
      
      debugPrint('RecoveryService: Recovery process successful.');
    } catch (e) {
      debugPrint('RecoveryService Error: $e');
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
