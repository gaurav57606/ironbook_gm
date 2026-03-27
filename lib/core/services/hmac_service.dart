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
  static const _keyStorageName = 'hmac_device_key';
  static const _storage = FlutterSecureStorage();
  
  static String? _testKey;

  static Future<void> init() async {
    await _getOrCreateKey();
  }
  
  /// For unit tests only.
  static void setKeyForTest(String key) {
    _testKey = key;
  }

  static Future<String> _getOrCreateKey() async {
    if (_testKey != null) return _testKey!;
    
    var key = await _storage.read(key: _keyStorageName);
    if (key == null) {
      final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyStorageName, value: key);
      await _backupKeyToFirestore(key);
    }
    return key;
  }

  static Future<String> _getInstallationId() async {
    const idKey = 'installation_id';
    var id = await _storage.read(key: idKey);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: idKey, value: id);
    }
    return id;
  }

  static Future<void> _backupKeyToFirestore(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final installationId = await _getInstallationId(); 
    
    await FirebaseFirestore.instance
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

  static Future<String> sign(DomainEvent event) async {
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

  static Future<bool> verify(DomainEvent event) async {
    if (event.hmacSignature.isEmpty) return false;
    final expected = await sign(event);
    return expected == event.hmacSignature;
  }

  static Future<bool> restoreKeyFromFirestore(String deviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final doc = await FirebaseFirestore.instance
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
