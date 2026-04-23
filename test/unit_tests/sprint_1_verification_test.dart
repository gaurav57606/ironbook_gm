import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late HmacService hmacService;
  late PinService pinService;

  setUpAll(() {
    registerFallbackValue(DomainEvent(
      entityId: 'test',
      eventType: EventType.memberCreated,
      payload: {},
      deviceId: 'dev1',
      deviceTimestamp: DateTime.now(),
    ));
  });

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    hmacService = HmacService(mockStorage, mockAuth, mockFirestore);
    pinService = PinService(mockStorage, mockAuth);
  });

  group('HmacService Verification', () {
    test('verifyInstance should return true for validly signed events', () async {
      final key = base64Encode(List.generate(32, (_) => 1)); // 32 bytes of 1s
      when(() => mockStorage.read(key: 'hmac_device_key')).thenAnswer((_) async => key);

      final event = DomainEvent(
        entityId: 'member1',
        eventType: EventType.memberCreated,
        payload: {EventPayloadKeys.name: 'John Doe'},
        deviceId: 'device1',
        deviceTimestamp: DateTime.now(),
      );

      final signature = await hmacService.signEvent(event);
      event.hmacSignature = signature;

      final isValid = await hmacService.verifyInstance(event);
      expect(isValid, isTrue);
    });

    test('verifyInstance should return false for modified payload', () async {
      final key = base64Encode(List.generate(32, (_) => 1));
      when(() => mockStorage.read(key: 'hmac_device_key')).thenAnswer((_) async => key);

      final event = DomainEvent(
        entityId: 'member1',
        eventType: EventType.memberCreated,
        payload: {EventPayloadKeys.name: 'John Doe'},
        deviceId: 'device1',
        deviceTimestamp: DateTime.now(),
      );

      final signature = await hmacService.signEvent(event);
      event.hmacSignature = signature;

      // Tamper with payload
      event.payload[EventPayloadKeys.name] = 'Jane Doe';

      final isValid = await hmacService.verifyInstance(event);
      expect(isValid, isFalse);
    });
  });

  group('PinService Verification', () {
    test('savePin and verifyPin should work with salt', () async {
      const pin = '1234';
      Map<String, String> storageMap = {};
      
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((invocation) async {
            storageMap[invocation.namedArguments[#key]] = invocation.namedArguments[#value];
          });
      
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async => storageMap[invocation.namedArguments[#key]]);
      
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
            storageMap.remove(invocation.namedArguments[#key]);
          });

      await pinService.savePin(pin);
      
      expect(storageMap.containsKey('pin_hash'), isTrue);
      expect(storageMap.containsKey('pin_salt'), isTrue);

      final isValid = await pinService.verifyPin(pin);
      expect(isValid, isTrue);
      
      final isInvalid = await pinService.verifyPin('0000');
      expect(isInvalid, isFalse);
    });
  });
}


