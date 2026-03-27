import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveEncryptionService {
  static const FlutterSecureStorage storage = FlutterSecureStorage();
  static const String _encKeyName = 'hive_encryption_key';

  static Future<HiveAesCipher?> getOrCreateCipher() async {
    if (kIsWeb) {
      return null; 
    }
    
    String? keyBase64 = await storage.read(key: _encKeyName);

    if (keyBase64 == null) {
      final key = Hive.generateSecureKey();
      keyBase64 = base64Encode(key);
      await storage.write(key: _encKeyName, value: keyBase64);
    }

    return HiveAesCipher(base64Decode(keyBase64));
  }
}
