import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/repositories/event_repository.dart';

class RecoveryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final IEventRepository _eventRepo;

  RecoveryService(this._firestore, this._auth, this._eventRepo);

  Future<void> recoverAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('RecoveryService: Starting event recovery for ${user.uid}');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .orderBy('deviceTimestamp')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('RecoveryService: No events found on cloud');
        return;
      }

      // 1. First pass: Identify all archived entities
      final Set<String> archivedEntityIds = {};
      final List<DomainEvent> allEvents = [];
      
      for (final doc in snapshot.docs) {
        final event = DomainEvent.fromFirestore(doc.data());
        allEvents.add(event);
        if (event.eventType == EventType.memberArchived.name) {
          archivedEntityIds.add(event.entityId);
        }
      }

      // 2. Second pass: Persist only non-archived entities
      int recoveredCount = 0;
      for (final event in allEvents) {
        if (archivedEntityIds.contains(event.entityId)) continue;

        // Check if event already exists locally
        final existing = _eventRepo.getById(event.id);
        if (existing == null) {
          event.synced = true; 
          await _eventRepo.persist(event);
          recoveredCount++;
        }
      }

      debugPrint('RecoveryService: Recovered $recoveredCount new events from cloud');
    } catch (e) {
      debugPrint('RecoveryService Error: $e');
    }
  }
}

final recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final eventRepo = ref.watch(eventRepositoryProvider);
  return RecoveryService(firestore, auth, eventRepo);
});
