import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('HMAC & Tamper Protection (TC-UNIT-04)', () {
    const testSecret = 'dGhpcy1pcy1hLXRlc3Qtc2VjcmV0LWtleS0zMi1ieXRlcw=='; // base64 for "this-is-a-test-secret-key-32-bytes"
    late HmacService hmacService;

    setUp(() {
      final storage = MockFlutterSecureStorage();
      final auth = MockFirebaseAuth();
      final firestore = MockFirebaseFirestore();
      hmacService = HmacService(storage, auth, firestore);
      HmacService.setKeyForTest(testSecret);
    });

    test('Should generate a consistent signature for the same event', () async {
      final event = DomainEvent(
        entityId: 'm1',
        eventType: 'MEMBER_CREATED',
        payload: {'name': 'John Doe', 'plan': 'Gold'},
        deviceId: 'device-123',
        deviceTimestamp: DateTime(2026, 1, 1),
      );

      final sig1 = await hmacService.sign(event);
      final sig2 = await hmacService.sign(event);

      expect(sig1, sig2);
      expect(sig1.isNotEmpty, true);
    });

    test('Should verify a valid event', () async {
      final event = DomainEvent(
        entityId: 'm1',
        eventType: 'MEMBER_CREATED',
        payload: {'name': 'John Doe'},
        deviceId: 'device-123',
        deviceTimestamp: DateTime(2026, 1, 1),
      );

      event.hmacSignature = await hmacService.sign(event);
      
      final isValid = await hmacService.verify(event);
      expect(isValid, true);
    });

    test('Should fail verification if payload is tampered', () async {
      final event = DomainEvent(
        entityId: 'm1',
        eventType: 'MEMBER_CREATED',
        payload: {'name': 'John Doe', 'amount': 1000},
        deviceId: 'device-123',
        deviceTimestamp: DateTime(2026, 1, 1),
      );

      event.hmacSignature = await hmacService.sign(event);

      // Tamper: change amount from 1000 to 0
      event.payload['amount'] = 0;

      final isValid = await hmacService.verify(event);
      expect(isValid, false);
    });

    test('Should fail verification if metadata is tampered', () async {
      final event = DomainEvent(
        entityId: 'm1',
        eventType: 'MEMBER_CREATED',
        payload: {'name': 'John Doe'},
        deviceId: 'device-123',
        deviceTimestamp: DateTime(2026, 1, 1),
      );

      event.hmacSignature = await hmacService.sign(event);

      // Tamper: change entityId
      event.entityId = 'm2';

      final isValid = await hmacService.verify(event);
      expect(isValid, false);
    });

    test('Should fail verification if signature is tampered', () async {
      final event = DomainEvent(
        entityId: 'm1',
        eventType: 'MEMBER_CREATED',
        payload: {'name': 'John Doe'},
        deviceId: 'device-123',
        deviceTimestamp: DateTime(2026, 1, 1),
      );

      event.hmacSignature = await hmacService.sign(event);
      event.hmacSignature = 'dGFtcGVyZWQtc2lnbmF0dXJl'; // random base64

      final isValid = await hmacService.verify(event);
      expect(isValid, false);
    });

    test('Canonical JSON should ensure stability regardless of key insertion order', () async {
      final payload1 = {'a': 1, 'b': 2};
      final payload2 = {'b': 2, 'a': 1};

      final event1 = DomainEvent(
        id: 'stable-id',
        entityId: 'm1',
        eventType: 'TYPE',
        payload: payload1,
        deviceId: 'dev',
        deviceTimestamp: DateTime(2026, 1, 1),
      );
      
      final event2 = DomainEvent(
        id: 'stable-id',
        entityId: 'm1',
        eventType: 'TYPE',
        payload: payload2,
        deviceId: 'dev',
        deviceTimestamp: DateTime(2026, 1, 1),
      );

      final s1 = await hmacService.sign(event1);
      final s2 = await hmacService.sign(event2);

      expect(s1, s2, reason: 'HMAC should be identical despite map key order');
    });
  });
}
