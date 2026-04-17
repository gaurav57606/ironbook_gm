import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/repositories/event_repository.dart';
import '../providers/base_providers.dart';
import '../core/services/hmac_service.dart';

class RecoveryService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final IEventRepository _eventRepo;
  final HmacService _hmac;

  RecoveryService(this._firestore, this._auth, this._eventRepo, this._hmac);

  Future<void> recoverAll() async {
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
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .orderBy('deviceTimestamp')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('RecoveryService: No events found on cloud');
        return;
      }

      int recoveredCount = 0;
      int tamperedCount = 0;

      for (final doc in snapshot.docs) {
        final event = DomainEvent.fromFirestore(doc.data());
        
        final isValid = await _hmac.verifyInstance(event);
        if (!isValid) {
          debugPrint('RecoveryService: REJECTED event ${event.id} - HMAC mismatch');
          tamperedCount++;
          continue;
        }

        final existing = await _eventRepo.getById(event.id);
        if (existing == null) {
          event.synced = true; 
          await _eventRepo.persist(event);
          recoveredCount++;
        }
      }

      debugPrint('RecoveryService: Recovery complete.');
      debugPrint('  - Valid events recovered: $recoveredCount');
      if (tamperedCount > 0) {
        debugPrint('  - WARNING: $tamperedCount events rejected due to invalid signatures');
      }
    } catch (e) {
      debugPrint('RecoveryService Error: $e');
    }
  }
}

final recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return RecoveryService(firestore, auth, eventRepo, hmac);
});
