import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/data/remote/firestore_backup.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';

// Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockWriteBatch extends Mock implements WriteBatch {}
// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late FirestoreBackupService service;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockWriteBatch mockBatch;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;

  setUpAll(() {
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockBatch = MockWriteBatch();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    service = FirestoreBackupService(
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  group('FirestoreBackupService', () {
    test('backupLatestSnapshots does nothing if user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await service.backupLatestSnapshots([]);

      verifyNever(() => mockFirestore.batch());
    });

    test('backupLatestSnapshots sets data in a batch and commits', () async {
      const uid = 'test-uid';
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(uid);
      when(() => mockFirestore.batch()).thenReturn(mockBatch);

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.collection(any())).thenReturn(mockCollection);

      when(() => mockBatch.set<Map<String, dynamic>>(any(), any())).thenReturn(null);
      when(() => mockBatch.commit()).thenAnswer((_) async {});

      final snapshots = [
        MemberSnapshot(
          memberId: 'm1',
          name: 'John Doe',
          joinDate: DateTime(2024, 1, 1),
        ),
      ];

      await service.backupLatestSnapshots(snapshots);

      // Verify the path: users/{uid}/snapshots/latest
      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockCollection.doc(uid)).called(1);
      verify(() => mockDoc.collection('snapshots')).called(1);
      verify(() => mockCollection.doc('latest')).called(1);

      // Verify batch operations
      final captured = verify(() => mockBatch.set<Map<String, dynamic>>(any(), captureAny())).captured;
      expect(captured.length, 1);

      final capturedData = captured.first as Map<String, dynamic>;

      expect(capturedData['memberCount'], 1);
      expect(capturedData['data'], isA<List>());
      expect((capturedData['data'] as List).length, 1);
      expect((capturedData['data'] as List)[0]['memberId'], 'm1');
      expect(capturedData['timestamp'], isA<FieldValue>());

      verify(() => mockBatch.commit()).called(1);
    });

    test('backupLatestSnapshots handles empty snapshots list', () async {
      const uid = 'test-uid';
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(uid);
      when(() => mockFirestore.batch()).thenReturn(mockBatch);

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.collection(any())).thenReturn(mockCollection);

      when(() => mockBatch.set<Map<String, dynamic>>(any(), any())).thenReturn(null);
      when(() => mockBatch.commit()).thenAnswer((_) async {});

      await service.backupLatestSnapshots([]);

      final captured = verify(() => mockBatch.set<Map<String, dynamic>>(any(), captureAny())).captured;
      final capturedData = captured.first as Map<String, dynamic>;

      expect(capturedData['memberCount'], 0);
      expect(capturedData['data'], []);
      verify(() => mockBatch.commit()).called(1);
    });

    group('Error Handling', () {
      test('backupLatestSnapshots rethrows firestore errors', () async {
        const uid = 'test-uid';
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        when(() => mockFirestore.batch()).thenReturn(mockBatch);

        when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDoc);
        when(() => mockDoc.collection(any())).thenReturn(mockCollection);

        when(() => mockBatch.set<Map<String, dynamic>>(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenThrow(FirebaseException(plugin: 'firestore', message: 'test error'));

        expect(() => service.backupLatestSnapshots([]), throwsA(isA<FirebaseException>()));
      });
    });
  });
}
