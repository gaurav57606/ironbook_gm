import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/shared/utils/canonical_json.dart';
import 'package:ironbook_gm/core/services/config_service.dart';

class HmacService {
  final FlutterSecureStorage _storage;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final ConfigService? _config;
  
  static const _keyStorageName = 'hmac_device_key';
  
  HmacService(this._storage, this._auth, this._firestore, [this._config]);

  bool get isCloudReady => _auth != null && _firestore != null;
  
  static String? _testKey;
  static void setKeyForTest(String key) => _testKey = key;

  Future<String> _getOrCreateKey() async {
    var key = await _storage.read(key: _keyStorageName);
    if (key == null) {
      final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyStorageName, value: key);
      
      // Only backup if we have auth and firestore
      if (_auth != null && _firestore != null) {
        await _backupKeyToFirestore(key);
      }
    }
    return key;
  }

  Future<void> syncCurrentKeyToCloud() async {
    if (!isCloudReady) {
      throw Exception('HmacService: Cannot sync key to cloud. Firebase not initialized.');
    }
    
    final key = await _storage.read(key: _keyStorageName);
    if (key == null) {
      // If key is missing, create it first which will trigger backup
      await _getOrCreateKey();
    } else {
      await _backupKeyToFirestore(key);
    }
  }

  Future<bool> verifyCloudKeyPresence() async {
    if (!isCloudReady) return false;
    
    final user = _auth!.currentUser;
    if (user == null) return false;
    
    final installationId = await getInstallationId();
    final doc = await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('device_keys')
        .doc(installationId)
        .get();
        
    return doc.exists;
  }

  Future<String> getInstallationId() async {
    const idKey = 'installation_id';
    var id = await _storage.read(key: idKey);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: idKey, value: id);
    }
    return id;
  }

  Future<void> _backupKeyToFirestore(String key) async {
    if (!isCloudReady) {
      throw Exception('HmacService: Backup failed. Firebase services unavailable.');
    }
    final auth = _auth!;
    final firestore = _firestore!;

    final user = auth.currentUser;
    if (user == null) return;
    
    final installationId = await getInstallationId(); 
    
    // Audit Hardening 2.6: Encrypt the key before backup
    final wrappedKey = _wrapKey(key, user.uid);
    
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('device_keys')
        .doc(installationId)
        .set({
          'hmac_key': wrappedKey, // Encrypted/Wrapped
          'installation_id': installationId,
          'created_at': FieldValue.serverTimestamp(),
          'version': 2, // Indicator for encrypted key
        });
  }

  String _wrapKey(String rawKey, String uid) {
    // Audit Hardening 2.7: KDF uses Identity + Environment Secret
    final hmacKey = _config!.hmacSecret;
    final kdf = crypto.Hmac(crypto.sha256, utf8.encode(uid + hmacKey));
    final wrapperKeyBytes = kdf.convert(utf8.encode(uid)).bytes;
    
    final key = enc.Key(Uint8List.fromList(wrapperKeyBytes));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final encrypted = encrypter.encrypt(rawKey, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String _unwrapKey(String combined, String uid) {
    final parts = combined.split(':');
    if (parts.length != 2) throw Exception('Invalid wrapped key format');
    
    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);
    
    final hmacKey = _config!.hmacSecret;
    final kdf = crypto.Hmac(crypto.sha256, utf8.encode(uid + hmacKey));
    final wrapperKeyBytes = kdf.convert(utf8.encode(uid)).bytes;
    
    final key = enc.Key(Uint8List.fromList(wrapperKeyBytes));
    final encrypter = enc.Encrypter(enc.AES(key));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }

  static Future<String> signStatic(DomainEvent event, String keyStr) async {
    final keyBytes = base64Decode(keyStr);
    final payloadJson = CanonicalJson.encode(event.payload);
    final canonical = '${event.id}|${event.entityId}|${event.eventType.name}|'
        '${event.deviceTimestamp.toUtc().toIso8601String()}|'
        '$payloadJson|${event.deviceId}';
    
    final hmacSha256 = crypto.Hmac(crypto.sha256, keyBytes);
    final digest = hmacSha256.convert(utf8.encode(canonical));
    return base64Encode(digest.bytes);
  }

  Future<String> signEvent(DomainEvent event) async {
    if (kDebugMode) debugPrint('HmacService: Generating signature for event ${event.id}...');
    final keyStr = _testKey ?? await _getOrCreateKey();
    if (kDebugMode) debugPrint('HmacService: Key retrieved.');
    return signStatic(event, keyStr);
  }

  Future<String> signSnapshot(String entityId, Map<String, dynamic> data) async {
    final keyStr = _testKey ?? await _getOrCreateKey();
    final keyBytes = base64Decode(keyStr);
    final payloadJson = CanonicalJson.encode(data);
    final canonical = '$entityId|$payloadJson';
    
    final hmacSha256 = crypto.Hmac(crypto.sha256, keyBytes);
    final digest = hmacSha256.convert(utf8.encode(canonical));
    return base64Encode(digest.bytes);
  }

  Future<bool> verifySnapshot(String entityId, Map<String, dynamic> data, String signature) async {
    final expected = await signSnapshot(entityId, data);
    return expected == signature;
  }

  static Future<String> sign(DomainEvent event) async {
    if (_testKey == null) throw Exception("Test key not set. Use HmacService.setKeyForTest()");
    return signStatic(event, _testKey!);
  }

  static Future<bool> verify(DomainEvent event) async {
    if (_testKey == null) throw Exception("Test key not set.");
    final expected = await sign(event);
    return expected == event.hmacSignature;
  }

  Future<bool> verifyInstance(DomainEvent event) async {
    if (event.hmacSignature.isEmpty) return false;
    final expected = await signEvent(event);
    return expected == event.hmacSignature;
  }


  Future<bool> restoreKeyFromFirestore(String deviceId) async {
    final auth = _auth;
    final firestore = _firestore;
    if (auth == null || firestore == null) return false;

    try {
      final user = auth.currentUser;
      if (user == null) return false;
      
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('device_keys')
          .doc(deviceId)
          .get();
          
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final rawBlob = data['hmac_key'] as String;
      final version = data['version'] as int? ?? 1;

      String finalKey;
      if (version == 2) {
        finalKey = _unwrapKey(rawBlob, user.uid);
      } else {
        finalKey = rawBlob;
      }
      
      await _storage.write(key: _keyStorageName, value: finalKey);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('HmacService: Key restoration failed: $e');
      return false;
    }
  }

  Future<Map<String, String>> restoreAllUserKeys() async {
    final auth = _auth;
    final firestore = _firestore;
    if (auth == null || firestore == null) return {};

    try {
      final user = auth.currentUser;
      if (user == null) return {};
      
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('device_keys')
          .get();
          
      final Map<String, String> keyMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deviceId = doc.id;
        final rawBlob = data['hmac_key'] as String;
        final version = data['version'] as int? ?? 1;

        try {
          String finalKey;
          if (version == 2) {
            finalKey = _unwrapKey(rawBlob, user.uid);
          } else {
            finalKey = rawBlob;
          }
          keyMap[deviceId] = finalKey;
        } catch (e) {
          if (kDebugMode) debugPrint('HmacService: Failed to unwrap key for device $deviceId: $e');
        }
      }
      return keyMap;
    } catch (e) {
      if (kDebugMode) debugPrint('HmacService: Failed to restore all keys: $e');
      return {};
    }
  }
}











