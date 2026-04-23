import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';

/// Service responsible for recovering all domain events from Firestore
/// and rebuilding the local database cache.
class RecoveryService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final IEventRepository _eventRepo;
  final HmacService _hmac;
  final Ref _ref;

  RecoveryService(this._firestore, this._auth, this._eventRepo, this._hmac, this._ref);

  Future<void> recoverAll({
    void Function(int done, int total)? onProgress,
  }) async {
    final auth = _auth;
    final firestore = _firestore;
    if (auth == null || firestore == null) {
      debugPrint('RecoveryService: Skipping recovery - Firebase not available');
      return;
    }

    final user = auth.currentUser;
    if (user == null) return;

    debugPrint('RecoveryService: Starting event recovery for ${user.uid}');

    try {
      // 1. Mandatory: Restore HMAC Key first or verification will fail
      final installationId = await _hmac.getInstallationId();
      final keyRestored = await _hmac.restoreKeyFromFirestore(installationId);
      if (!keyRestored) {
        debugPrint('RecoveryService: Could not restore security key for $installationId. Recovery aborted.');
        throw Exception('Security key restoration failed');
      }

      // 2. Fetch all events ordered by time
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .orderBy('deviceTimestamp')
          .get()
          .timeout(const Duration(seconds: 30));

      if (snapshot.docs.isEmpty) {
        debugPrint('RecoveryService: No events found on cloud');
        return;
      }

      final docs = snapshot.docs;
      final total = docs.length;
      int recoveredCount = 0;
      int tamperedCount = 0;

      for (int i = 0; i < total; i++) {
        final doc = docs[i];
        final event = DomainEvent.fromFirestore(doc.data());
        
        // 3. Security Verification
        final isValid = await _hmac.verifyInstance(event);
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

        onProgress?.call(i + 1, total);
      }

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
  return RecoveryService(firestore, auth, eventRepo, hmac, ref);
});
