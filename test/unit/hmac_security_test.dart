import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/utils/canonical_json.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('HMAC Security & Canonicalization', () {
    const testKey = 'dGhpcy1pcy1hLXZlcnktc2VjdXJlLTMyLWJ5dGUta2V5'; // base64 encoded test key
    late HmacService hmacService;

    setUp(() {
      final storage = MockFlutterSecureStorage();
      final auth = MockFirebaseAuth();
      final firestore = MockFirebaseFirestore();
      hmacService = HmacService(storage, auth, firestore);
      HmacService.setKeyForTest(testKey);
    });

    test('CanonicalJson should sort keys alphabetically', () {
      final input = {
        'z': 1,
        'a': 2,
        'm': {'y': 3, 'x': 4}
      };
      // Expected result has sorted keys: {"a":2,"m":{"x":4,"y":3},"z":1}
      final result = CanonicalJson.encode(input);
      expect(result, '{"a":2,"m":{"x":4,"y":3},"z":1}');
    });

    test('HmacService should sign and verify an event correctly', () async {
      final event = DomainEvent(
        id: 'evt-1',
        entityId: 'mem-1',
        eventType: 'TEST_EVENT',
        deviceId: 'dev-1',
        deviceTimestamp: DateTime(2024, 3, 25, 10),
        payload: {'amount': 500, 'note': 'test'},
      );

      final signature = await hmacService.sign(event);
      event.hmacSignature = signature;

      final isValid = await hmacService.verify(event);
      expect(isValid, isTrue);
    });

    test('HmacService should reject tampered payload', () async {
      final event = DomainEvent(
        id: 'evt-1',
        entityId: 'mem-1',
        eventType: 'TEST_EVENT',
        deviceId: 'dev-1',
        deviceTimestamp: DateTime(2024, 3, 25, 10),
        payload: {'amount': 500},
      );

      final signature = await hmacService.sign(event);
      event.hmacSignature = signature;

      // Tamper with the payload
      event.payload['amount'] = 501;

      final isValid = await hmacService.verify(event);
      expect(isValid, isFalse);
    });

    test('HmacService should reject tampered timestamp', () async {
      final event = DomainEvent(
        id: 'evt-1',
        entityId: 'mem-1',
        eventType: 'TEST_EVENT',
        deviceId: 'dev-1',
        deviceTimestamp: DateTime(2024, 3, 25, 10),
        payload: {'amount': 500},
      );

      final signature = await hmacService.sign(event);
      event.hmacSignature = signature;

      // Tamper with timestamp
      event.deviceTimestamp = event.deviceTimestamp.add(const Duration(seconds: 1));

      final isValid = await hmacService.verify(event);
      expect(isValid, isFalse);
    });
  });
}
