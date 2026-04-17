import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ironbook_gm/security/pin_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockFirebaseAuth mockAuth;
  late PinService pinService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockFirebaseAuth();
    pinService = PinService(mockStorage, mockAuth);
  });

  group('PinService Hardening', () {
    test('savePin should use v2 prefix and high iterations', () async {
      final pin = '1234';
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

      expect(storageMap['pin_hash']!.startsWith('v2|'), isTrue);

      final isValid = await pinService.verifyPin(pin);
      expect(isValid, isTrue);
    });

    test('should support migration from v1 (legacy) to v2', () async {
      final pin = 'legacy_pin';
      final salt = 'legacy_salt';

      // Manually create a v1 hash (1000 iterations)
      var hash = sha256.convert(utf8.encode(pin + salt)).toString();
      for (int i = 0; i < 1000; i++) {
        hash = sha256.convert(utf8.encode(hash + salt)).toString();
      }

      Map<String, String> storageMap = {
        'pin_hash': hash,
        'pin_salt': salt,
      };

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async => storageMap[invocation.namedArguments[#key]]);

      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((invocation) async {
            storageMap[invocation.namedArguments[#key]] = invocation.namedArguments[#value];
          });

      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((invocation) async {
            storageMap.remove(invocation.namedArguments[#key]);
          });

      // Verify with legacy PIN
      final isValid = await pinService.verifyPin(pin);
      expect(isValid, isTrue);

      // Check if it migrated to v2
      expect(storageMap['pin_hash']!.startsWith('v2|'), isTrue);

      // Verify again with migrated hash
      final isValidV2 = await pinService.verifyPin(pin);
      expect(isValidV2, isTrue);
    });
  });
}
