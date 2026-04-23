import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../local/models/member_snapshot_model.dart';

/// Service responsible for backing up the latest computed state 
/// to Firestore as a safety snapshot.
class FirestoreBackupService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreBackupService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<void> backupLatestSnapshots(List<MemberSnapshot> snapshots) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final latestRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('snapshots')
        .doc('latest');

    final data = {
      'timestamp': FieldValue.serverTimestamp(),
      'memberCount': snapshots.length,
      'data': snapshots.map((s) => s.toFirestore()).toList(),
    };

    batch.set(latestRef, data);
    await batch.commit();
  }
}









