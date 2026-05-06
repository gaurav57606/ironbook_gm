import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ironbook_gm/data/remote/firestore_backup.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockWriteBatch extends Mock implements WriteBatch {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockWriteBatch mockBatch;
  late FirestoreBackupService service;

  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockBatch = MockWriteBatch();

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
      when(() => mockFirestore.batch()).thenReturn(mockBatch);

      final mockUsersColl = MockCollectionReference();
      final mockUserDoc = MockDocumentReference();
      final mockSnapshotsColl = MockCollectionReference();
      final mockLatestDoc = MockDocumentReference();

      when(() => mockFirestore.collection(any())).thenReturn(mockUsersColl);
      when(() => mockUsersColl.doc(any())).thenReturn(mockUserDoc);
      when(() => mockUserDoc.collection(any())).thenReturn(mockSnapshotsColl);
      when(() => mockSnapshotsColl.doc(any())).thenReturn(mockLatestDoc);

      when(() => mockBatch.set<Map<String, dynamic>>(any(), any()))
          .thenReturn(null);
      when(() => mockBatch.commit()).thenAnswer((_) async {});

      final snapshots = [
        MemberSnapshot(
          memberId: 'm1',
          name: 'John Doe',
          joinDate: DateTime(2024, 1, 1),
        ),
      ];

      await service.backupLatestSnapshots(snapshots);

      final captured = verify(() => mockBatch.set<Map<String, dynamic>>(
            any(),
            captureAny(),
          )).captured;

      final data = captured.first as Map<String, dynamic>;
      expect(data['memberCount'], 1);
      expect(data['data'], isA<List>());
      expect((data['data'] as List).length, 1);
      expect(data['timestamp'], isA<FieldValue>());

      verify(() => mockBatch.commit()).called(1);
    });

    test('backupLatestSnapshots should propagate Firestore errors', () async {
      const uid = 'test-uid';
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(uid);
      when(() => mockFirestore.batch()).thenReturn(mockBatch);

      final mockUsersColl = MockCollectionReference();
      final mockUserDoc = MockDocumentReference();
      final mockSnapshotsColl = MockCollectionReference();
      final mockLatestDoc = MockDocumentReference();

      when(() => mockFirestore.collection(any())).thenReturn(mockUsersColl);
      when(() => mockUsersColl.doc(any())).thenReturn(mockUserDoc);
      when(() => mockUserDoc.collection(any())).thenReturn(mockSnapshotsColl);
      when(() => mockSnapshotsColl.doc(any())).thenReturn(mockLatestDoc);

      when(() => mockBatch.set<Map<String, dynamic>>(any(), any()))
          .thenReturn(null);
      when(() => mockBatch.commit()).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'));

      expect(
        () => service.backupLatestSnapshots([]),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
