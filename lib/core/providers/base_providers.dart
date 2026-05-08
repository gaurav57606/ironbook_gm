import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/services/config_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in bootstrap and overridden in ProviderScope');
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final appSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final outboxDatabaseProvider = Provider<OutboxDatabase>((ref) {
  final db = OutboxDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return OutboxRepository(db);
});

final hmacServiceProvider = Provider<HmacService>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final config = ref.watch(configServiceProvider);
  
  return HmacService(storage, auth, firestore, config);
});









