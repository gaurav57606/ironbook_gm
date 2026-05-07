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

    final snapshotsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('snapshots');

    int count = 0;
    WriteBatch batch = _firestore.batch();
    
    for (final snapshot in snapshots) {
      final data = snapshot.toFirestore();
      data['timestamp'] = FieldValue.serverTimestamp();
      batch.set(snapshotsRef.doc(snapshot.memberId), data);
      count++;

      // Firestore limits batches to 500 operations
      if (count == 500) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}









