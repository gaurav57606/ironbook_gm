import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveEncryptionService {
  @visibleForTesting
  static FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _encKeyName = 'hive_encryption_key';

  static Future<HiveAesCipher?> getOrCreateCipher() async {
    if (kIsWeb) {
      return null;
    }
    
    final encryptionKey = await storage.read(key: _encKeyName);
    if (encryptionKey == null) {
      final key = Hive.generateSecureKey();
      await storage.write(key: _encKeyName, value: base64UrlEncode(key));
    }

    final keyBase64 = await storage.read(key: _encKeyName);
    if (keyBase64 == null) return null;

    return HiveAesCipher(base64Url.decode(keyBase64));
  }
}
