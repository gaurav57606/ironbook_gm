import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:ironbook_gm/core/services/hive_encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    HiveEncryptionService.storage = mockStorage;
  });

  group('HiveEncryptionService', () {
    test('getOrCreateCipher should create and save a new key if one does not exist', () async {
      // Setup: key does not exist initially
      when(() => mockStorage.read(key: 'hive_encryption_key'))
          .thenAnswer((_) async => null);

      // Capture the write call to see what key was generated
      String? savedKey;
      when(() => mockStorage.write(key: 'hive_encryption_key', value: any(named: 'value')))
          .thenAnswer((invocation) async {
            savedKey = invocation.namedArguments[#value];
          });

      // Subsequent read should return the saved key
      when(() => mockStorage.read(key: 'hive_encryption_key'))
          .thenAnswer((_) async => savedKey);

      final cipher = await HiveEncryptionService.getOrCreateCipher();

      expect(cipher, isNotNull);
      expect(cipher, isA<HiveAesCipher>());

      verify(() => mockStorage.read(key: 'hive_encryption_key')).called(2);
      verify(() => mockStorage.write(key: 'hive_encryption_key', value: any(named: 'value'))).called(1);
      expect(savedKey, isNotNull);
    });

    test('getOrCreateCipher should return existing key if it exists', () async {
      final existingKey = base64UrlEncode(Hive.generateSecureKey());

      when(() => mockStorage.read(key: 'hive_encryption_key'))
          .thenAnswer((_) async => existingKey);

      final cipher = await HiveEncryptionService.getOrCreateCipher();

      expect(cipher, isNotNull);
      expect(cipher, isA<HiveAesCipher>());

      verify(() => mockStorage.read(key: 'hive_encryption_key')).called(greaterThanOrEqualTo(1));
      verifyNever(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('getOrCreateCipher should return null if storage.read returns null after write (edge case)', () async {
      when(() => mockStorage.read(key: 'hive_encryption_key'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final cipher = await HiveEncryptionService.getOrCreateCipher();

      expect(cipher, isNull);
    });

    test('getOrCreateCipher should fail if encryption key is corrupted (not base64)', () async {
      when(() => mockStorage.read(key: 'hive_encryption_key'))
          .thenAnswer((_) async => 'not-a-base64-string!!!');

      expect(() => HiveEncryptionService.getOrCreateCipher(), throwsA(isA<FormatException>()));
    });
  });
}
