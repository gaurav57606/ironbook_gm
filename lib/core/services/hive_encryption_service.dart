import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveEncryptionService {
  static FlutterSecureStorage storage = const FlutterSecureStorage();

  static Future<HiveAesCipher?> getOrCreateCipher() async {
    // Disable encryption on emulator for debugging sync issues
    return null;
    
    /* Original logic commented out for debugging
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
    */
  }
}
