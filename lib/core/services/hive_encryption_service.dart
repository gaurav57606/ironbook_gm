import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveEncryptionService {
  static const _encKeyName = 'hive_aes_key';
  static const _storage = FlutterSecureStorage();

  static Future<HiveAesCipher> getOrCreateCipher() async {
    String? keyBase64 = await _storage.read(key: _encKeyName);

    if (keyBase64 == null) {
      final key = Hive.generateSecureKey();
      keyBase64 = base64Encode(key);
      await _storage.write(key: _encKeyName, value: keyBase64);
    }

    return HiveAesCipher(base64Decode(keyBase64));
  }
}
