import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum EntitlementStatus { valid, grace, expired }

class EntitlementGuard {
  static final EntitlementGuard _instance = EntitlementGuard.internal();
  factory EntitlementGuard() => _instance;
  EntitlementGuard.internal();

  static EntitlementGuard instance = _instance; // Allow overriding for tests

  static const _storage = FlutterSecureStorage();

  Future<EntitlementStatus> checkEntitlement() async {
    final expiryRaw = await _storage.read(key: 'ent_expiry');
    final cachedAtRaw = await _storage.read(key: 'ent_cached_at');
    
    final expiry = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
    final cachedAt = cachedAtRaw != null ? DateTime.tryParse(cachedAtRaw) : null;

    if (expiry != null && cachedAt != null) {
      final cacheAge = DateTime.now().difference(cachedAt).inDays;
      if (cacheAge < 7 && expiry.isAfter(DateTime.now())) {
        return EntitlementStatus.valid;
      }
    }

    if (const bool.fromEnvironment('dart.library.js_util')) {
      // Bypassing Firebase check on Web for visual audit
      return EntitlementStatus.valid;
    }

    if (kIsWeb) return EntitlementStatus.valid;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return EntitlementStatus.expired;

      final doc = await FirebaseFirestore.instance
          .collection('entitlements')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final freshExpiry = (doc.data()!['expiresAt'] as Timestamp).toDate();
        await _storage.write(key: 'ent_expiry', value: freshExpiry.toIso8601String());
        await _storage.write(key: 'ent_cached_at', value: DateTime.now().toIso8601String());

        return freshExpiry.isAfter(DateTime.now())
            ? EntitlementStatus.valid
            : EntitlementStatus.expired;
      }
    } catch (_) {
      if (cachedAt != null) {
        final graceDays = DateTime.now().difference(cachedAt).inDays;
        if (graceDays < 7) return EntitlementStatus.grace;
      }
    }

    return EntitlementStatus.expired;
  }
}
