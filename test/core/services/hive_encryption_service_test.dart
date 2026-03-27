import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/services/hive_encryption_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('getOrCreateCipher generates and saves a new key if one does not exist', () async {
    const storage = FlutterSecureStorage();
    final initialKey = await storage.read(key: 'hive_encryption_key');
    expect(initialKey, isNull);

    final cipher = await HiveEncryptionService.getOrCreateCipher();
    expect(cipher, isA<HiveAesCipher>());

    final generatedKey = await storage.read(key: 'hive_encryption_key');
    expect(generatedKey, isNotNull);

    final decodedKey = base64Decode(generatedKey!);
    expect(decodedKey.length, 32); // 256-bit key
  });

  test('getOrCreateCipher reuses an existing key if one exists', () async {
    const storage = FlutterSecureStorage();
    final key = Hive.generateSecureKey();
    final keyBase64 = base64Encode(key);
    await storage.write(key: 'hive_encryption_key', value: keyBase64);

    final cipher = await HiveEncryptionService.getOrCreateCipher();
    expect(cipher, isA<HiveAesCipher>());

    final savedKey = await storage.read(key: 'hive_encryption_key');
    expect(savedKey, equals(keyBase64));
  });
}
