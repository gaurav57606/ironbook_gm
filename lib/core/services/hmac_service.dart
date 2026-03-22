import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/local/models/domain_event_model.dart';

class HmacService {
  static const _keyStorageName = 'hmac_device_key';
  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    await _getOrCreateKey();
  }

  static Future<String> _getOrCreateKey() async {
    var key = await _storage.read(key: _keyStorageName);
    if (key == null) {
      final bytes = List.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyStorageName, value: key);
      await _backupKeyToFirestore(key);
    }
    return key;
  }

  static Future<void> _backupKeyToFirestore(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // In a real app, we would get a real device ID. Using UUID or similar for now.
    final deviceId = user.uid; // Simplified for this logic snippet
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('device_keys')
        .doc(deviceId)
        .set({
          'hmac_key': key,
          'created_at': FieldValue.serverTimestamp(),
        });
  }

  static Future<String> sign(DomainEvent event) async {
    final keyStr = await _getOrCreateKey();
    
    final keyBytes = base64Decode(keyStr);
    // V2 Canonical: id|entityId|eventType|deviceTimestamp|deviceId
    final canonical = '${event.id}|${event.entityId}|${event.eventType}|'
        '${event.deviceTimestamp.toIso8601String()}|${event.deviceId}';
    
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(utf8.encode(canonical));
    return base64Encode(digest.bytes);
  }

  static Future<bool> verify(DomainEvent event) async {
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
