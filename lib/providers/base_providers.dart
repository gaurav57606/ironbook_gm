import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:ironbook_gm/core/services/hmac_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (kIsWeb) return null;
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final appSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final hmacServiceProvider = Provider<HmacService>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final auth = ref.watch(firebaseAuthProvider)!;
  final firestore = ref.watch(firestoreProvider);
  return HmacService(storage, auth, firestore);
});
