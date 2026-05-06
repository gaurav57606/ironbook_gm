import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../test_helper.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late EntitlementGuard guard;
  late MockSecureStorage mockStorage;
  late MockAuth mockAuth;
  late MockFirestore mockFirestore;
  late FakeClock clock;
  late MockUser mockUser;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;

  final now = DateTime(2024, 1, 1);
  final userId = 'test-user-id';

  setUp(() {
    mockStorage = MockSecureStorage();
    mockAuth = MockAuth();
    mockFirestore = MockFirestore();
    clock = FakeClock();
    clock.setNow(now);
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    guard = EntitlementGuard(mockStorage, mockAuth, mockFirestore, clock);

    // Default behaviors
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn(userId);
    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
    when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);

    // Default storage reads return null
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
  });

  group('EntitlementGuard - checkEntitlement', () {
    test('Valid cache (heartbeat fresh and expiry in future) returns valid', () async {
      final expiry = now.add(const Duration(days: 30));
      final heartbeat = now.subtract(const Duration(days: 2));

      when(() => mockStorage.read(key: 'ent_expiry'))
          .thenAnswer((_) async => expiry.toIso8601String());
      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => heartbeat.toIso8601String());

      final result = await guard.checkEntitlement();

      expect(result, EntitlementStatus.valid);
      verifyNever(() => mockFirestore.collection(any()));
    });

    test('Expired cache but Firestore has fresh valid entitlement returns valid and updates cache', () async {
      final oldExpiry = now.subtract(const Duration(days: 1));
      final heartbeat = now.subtract(const Duration(days: 2));
      final freshExpiry = now.add(const Duration(days: 30));

      when(() => mockStorage.read(key: 'ent_expiry'))
          .thenAnswer((_) async => oldExpiry.toIso8601String());
      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => heartbeat.toIso8601String());

      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({'expiresAt': Timestamp.fromDate(freshExpiry)});

      final result = await guard.checkEntitlement();

      expect(result, EntitlementStatus.valid);
      verify(() => mockStorage.write(key: 'ent_expiry', value: freshExpiry.toIso8601String())).called(1);
      verify(() => mockStorage.write(key: 'lease_heartbeat', value: now.toIso8601String())).called(1);
    });

    test('Stale heartbeat (>= 7 days) returns expired regardless of cloud', () async {
      final expiry = now.add(const Duration(days: 30));
      final heartbeat = now.subtract(const Duration(days: 7));

      when(() => mockStorage.read(key: 'ent_expiry'))
          .thenAnswer((_) async => expiry.toIso8601String());
      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => heartbeat.toIso8601String());

      final result = await guard.checkEntitlement();

      expect(result, EntitlementStatus.expired);
    });

    test('No user logged in returns expired', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await guard.checkEntitlement();

      expect(result, EntitlementStatus.expired);
    });

    test('Firestore fetch fails, recently updated heartbeat returns grace', () async {
      final recentHeartbeat = now.subtract(const Duration(days: 2));

      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => recentHeartbeat.toIso8601String());

      when(() => mockDocument.get()).thenThrow(Exception('Network error'));

      final result = await guard.checkEntitlement();

      expect(result, EntitlementStatus.grace);
    });

    test('Firestore fetch fails, stale heartbeat returns expired', () async {
      final staleHeartbeat = now.subtract(const Duration(days: 8));

      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => staleHeartbeat.toIso8601String());
      when(() => mockDocument.get()).thenThrow(Exception('Network error'));

      final result = await guard.checkEntitlement();

      expect(result, EntitlementStatus.expired);
    });
  });
}
