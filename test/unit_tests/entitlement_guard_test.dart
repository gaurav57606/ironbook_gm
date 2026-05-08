import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late EntitlementGuard guard;
  late MockSecureStorage mockStorage;
  late MockAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late FrozenClock clock;
  late MockUser mockUser;

  final now = DateTime(2024, 1, 1);
  final userId = 'test-user-id';

  setUp(() {
    mockStorage = MockSecureStorage();
    mockAuth = MockAuth();
    mockFirestore = FakeFirebaseFirestore();
    clock = FrozenClock(now);
    mockUser = MockUser();

    guard = EntitlementGuard(mockStorage, mockAuth, mockFirestore, clock);

    // Default behaviors
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn(userId);

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
    });

    test('Expired cache but Firestore has fresh valid entitlement returns valid and updates cache', () async {
      final oldExpiry = now.subtract(const Duration(days: 1));
      final heartbeat = now.subtract(const Duration(days: 2));
      final freshExpiry = now.add(const Duration(days: 30));

      when(() => mockStorage.read(key: 'ent_expiry'))
          .thenAnswer((_) async => oldExpiry.toIso8601String());
      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => heartbeat.toIso8601String());

      await mockFirestore.collection('entitlements').doc(userId).set({
        'expiresAt': Timestamp.fromDate(freshExpiry),
      });

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
      final errorFirestore = MockFirestoreForErrors();
      final errorGuard = EntitlementGuard(mockStorage, mockAuth, errorFirestore, clock);

      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => recentHeartbeat.toIso8601String());

      final result = await errorGuard.checkEntitlement();

      expect(result, EntitlementStatus.grace);
    });

    test('Firestore fetch fails, stale heartbeat returns expired', () async {
      final staleHeartbeat = now.subtract(const Duration(days: 8));
      final errorFirestore = MockFirestoreForErrors();
      final errorGuard = EntitlementGuard(mockStorage, mockAuth, errorFirestore, clock);

      when(() => mockStorage.read(key: 'lease_heartbeat'))
          .thenAnswer((_) async => staleHeartbeat.toIso8601String());

      final result = await errorGuard.checkEntitlement();

      expect(result, EntitlementStatus.expired);
    });
  });
}

class MockFirestoreForErrors extends Mock implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw Exception('Network error');
  }
}
