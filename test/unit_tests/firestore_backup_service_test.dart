import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ironbook_gm/core/data/remote/firestore_backup.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FirestoreBackupService service;

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    service = FirestoreBackupService(
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  group('FirestoreBackupService', () {
    test('backupLatestSnapshots should do nothing if user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await service.backupLatestSnapshots([]);

      verifyNever(() => mockFirestore.batch());
    });

    test(
        'backupLatestSnapshots should commit batch with correct data when user is authenticated',
        () async {
      const uid = 'test-uid';
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(uid);

      final snapshots = [
        MemberSnapshot(
          memberId: 'm1',
          name: 'John Doe',
          joinDate: DateTime(2024, 1, 1),
        ),
      ];

      await service.backupLatestSnapshots(snapshots);

      final doc = await mockFirestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc('latest')
          .get();

      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['memberCount'], 1);
      expect(data['data'], isA<List>());
      expect((data['data'] as List).length, 1);
      expect(data['timestamp'], isA<Timestamp>());
    });

    test('backupLatestSnapshots should propagate Firestore errors', () async {
      final errorFirestore = MockFirestoreForErrors();
      final errorService = FirestoreBackupService(
        firestore: errorFirestore,
        auth: mockAuth,
      );

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('test-uid');

      expect(
        () => errorService.backupLatestSnapshots([]),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}

class MockFirestoreForErrors extends Mock implements FirebaseFirestore {
  @override
  WriteBatch batch() {
    final mockBatch = MockWriteBatch();
    when(() => mockBatch.set<Map<String, dynamic>>(any(), any())).thenReturn(null);
    when(() => mockBatch.commit()).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'));
    return mockBatch;
  }
}

class MockWriteBatch extends Mock implements WriteBatch {}
