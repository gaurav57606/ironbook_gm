import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';

enum EntitlementStatus { valid, grace, expired }

class EntitlementGuard {
  final FlutterSecureStorage _storage;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final IClock _clock;

  EntitlementGuard(this._storage, this._auth, this._firestore, this._clock);

  Future<EntitlementStatus> checkEntitlement() async {
    final expiryRaw = await _storage.read(key: 'ent_expiry');
    final heartbeatRaw = await _storage.read(key: 'lease_heartbeat');
    
    final expiry = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
    final lastHeartbeat = heartbeatRaw != null ? DateTime.tryParse(heartbeatRaw) : null;

    final now = _clock.now;

    // 1. Check local "Rental Persistence" (Heartbeat)
    if (lastHeartbeat != null) {
      final heartbeatAge = now.difference(lastHeartbeat).inDays;
      if (heartbeatAge >= 7) {
        debugPrint('EntitlementGuard: Lease heartbeat stale ($heartbeatAge days). Lock required.');
        return EntitlementStatus.expired;
      }
    }

    // 2. Check Expiry from last successful check
    if (expiry != null && lastHeartbeat != null) {
      if (expiry.isAfter(now)) {
        return EntitlementStatus.valid;
      }
    }

    // 3. Web/Audit Bypass
    if (kIsWeb) return EntitlementStatus.valid;

    // 4. Fresh Cloud Check
    try {
      final user = _auth?.currentUser;
      if (user == null) return EntitlementStatus.expired;

      final doc = await _firestore
          ?.collection('entitlements')
          .doc(user.uid)
          .get();

      if (doc != null && doc.exists) {
        final freshExpiry = (doc.data()!['expiresAt'] as Timestamp).toDate();
        
        // Update both Expiry and Heartbeat
        await _storage.write(key: 'ent_expiry', value: freshExpiry.toIso8601String());
        await _storage.write(key: 'lease_heartbeat', value: now.toIso8601String());

        return freshExpiry.isAfter(now)
            ? EntitlementStatus.valid
            : EntitlementStatus.expired;
      }
    } catch (e) {
      debugPrint('EntitlementGuard Cloud Check Error: $e');
      // If offline, allow grace if heartbeat is still fresh (<7 days)
      if (lastHeartbeat != null) {
        final graceDays = now.difference(lastHeartbeat).inDays;
        if (graceDays < 7) return EntitlementStatus.grace;
      }
    }

    return EntitlementStatus.expired;
  }
}

// entitlementGuardProvider removed in favor of entitlementProvider in auth_provider.dart











