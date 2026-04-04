import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/models/domain_event_model.dart';
import '../utils/canonical_json.dart';

class HmacService {
  final FlutterSecureStorage _storage;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  static const _keyStorageName = 'hmac_device_key';
  
  HmacService(this._storage, this._auth, this._firestore);
  
  static String? _testKey;

  static Future<void> init() async {
    // We only need to ensure the key is generated if it doesn't exist
    // However since the instance methods use `_getOrCreateKey()`,
    // it will lazily be created anyway.
    // For legacy compat with `main.dart` calling `HmacService.init()`,
    // we can provide a static method that just initializes the key using
    // default instances if necessary, but actually in this codebase
    // it seems `main.dart` doesn't need to do anything since the
    // DI injects it. But wait, `main.dart` is calling `HmacService.init()`.
    // Let's implement a static init that just checks/creates the key.
    final storage = const FlutterSecureStorage();
    var key = await storage.read(key: _keyStorageName);
    if (key == null) {
      final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Encode(bytes);
      await storage.write(key: _keyStorageName, value: key);
      // Backup to firestore will happen lazily when needed
    }
  }

  Future<String> _getOrCreateKey() async {
    var key = await _storage.read(key: _keyStorageName);
    if (key == null) {
      final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyStorageName, value: key);
      await _backupKeyToFirestore(key);
    }
    return key;
  }

  Future<String> _getInstallationId() async {
    const idKey = 'installation_id';
    var id = await _storage.read(key: idKey);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: idKey, value: id);
    }
    return id;
  }

  Future<void> _backupKeyToFirestore(String key) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final installationId = await _getInstallationId(); 
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('device_keys')
        .doc(installationId)
        .set({
          'hmac_key': key,
          'installation_id': installationId,
          'created_at': FieldValue.serverTimestamp(),
        });
  }

  Future<String> sign(DomainEvent event) async {
    debugPrint('HmacService: Generating signature for event ${event.id}...');
    final keyStr = await _getOrCreateKey();
    debugPrint('HmacService: Key retrieved.');
    final keyBytes = base64Decode(keyStr);

    // Canonical structure: version|id|entityId|eventType|timestamp|payload_json|deviceId
    final payloadJson = CanonicalJson.encode(event.payload);
    final canonical = '${event.id}|${event.entityId}|${event.eventType}|'
        '${event.deviceTimestamp.toIso8601String()}|'
        '$payloadJson|${event.deviceId}';
    
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(utf8.encode(canonical));
    final sig = base64Encode(digest.bytes);
    debugPrint('HmacService: Signature generated.');
    return sig;
  }

  Future<bool> verify(DomainEvent event) async {
    if (event.hmacSignature.isEmpty) return false;
    final expected = await sign(event);
    return expected == event.hmacSignature;
  }

  Future<bool> restoreKeyFromFirestore(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('device_keys')
          .doc(deviceId)
          .get();
          
      if (!doc.exists) return false;
      
      final key = doc.data()!['hmac_key'] as String;
      await _storage.write(key: _keyStorageName, value: key);
      return true;
    } catch (_) {
      return false;
    }
  }
}
