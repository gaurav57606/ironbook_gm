import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _storage;

  PaymentService(this._auth, this._firestore, this._storage);

  Future<bool> processSubscription({required String planId, required int months}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // 1. Simulate Payment Gateway (Razorpay/Stripe)
    await Future.delayed(const Duration(seconds: 2));
    
    // 2. Update Cloud Entitlement
    final newExpiry = DateTime.now().add(Duration(days: 30 * months));
    
    await _firestore.collection('entitlements').doc(user.uid).set({
      'planId': planId,
      'expiresAt': Timestamp.fromDate(newExpiry),
      'lastPaymentDate': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));

    // 3. Update Local Persistence (Heartbeat)
    await _storage.write(key: 'ent_expiry', value: newExpiry.toIso8601String());
    await _storage.write(key: 'lease_heartbeat', value: DateTime.now().toIso8601String());

    return true;
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    const FlutterSecureStorage(),
  );
});
