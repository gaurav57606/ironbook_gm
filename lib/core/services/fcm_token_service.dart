import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:drift/drift.dart';

class FCMTokenService {
  final OutboxDatabase _db;
  final _uuid = const Uuid();

  FCMTokenService(this._db);

  /// Call this on every app launch after the user is authenticated.
  /// It gets or refreshes the FCM token and upserts into local DeviceTokens table
  /// AND syncs the token to Firestore so the Cloud Function can fan-out.
  Future<void> registerOrRefreshToken({
    required String gymId,
    required String userId,
  }) async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS requires explicit request)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token == null) return;

    final deviceName = await _getDeviceName();

    // Check if this token already exists locally
    final existing = await (_db.select(_db.deviceTokens)
          ..where((t) => t.fcmToken.equals(token)))
        .getSingleOrNull();

    if (existing != null) {
      // Update lastSeenAt
      await (_db.update(_db.deviceTokens)
            ..where((t) => t.id.equals(existing.id)))
          .write(DeviceTokensCompanion(
            lastSeenAt: Value(DateTime.now()),
            isActive: const Value(true),
          ));
    } else {
      // Insert new token
      await _db.into(_db.deviceTokens).insert(DeviceTokensCompanion(
        id: Value(_uuid.v4()),
        gymId: Value(gymId),
        userId: Value(userId),
        fcmToken: Value(token),
        deviceName: Value(deviceName),
        platform: Value(Platform.isIOS ? 'ios' : 'android'),
        registeredAt: Value(DateTime.now()),
        lastSeenAt: Value(DateTime.now()),
        isActive: const Value(true),
      ));
    }

    // Sync this token to Firestore so the Cloud Function can access all gym tokens
    await _syncTokenToFirestore(gymId: gymId, userId: userId, token: token, deviceName: deviceName);

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await registerOrRefreshToken(gymId: gymId, userId: userId);
    });
  }

  Future<void> deactivateToken(String fcmToken) async {
    await (_db.update(_db.deviceTokens)
          ..where((t) => t.fcmToken.equals(fcmToken)))
        .write(const DeviceTokensCompanion(isActive: Value(false)));

    // Also remove from Firestore
    final existing = await (_db.select(_db.deviceTokens)
          ..where((t) => t.fcmToken.equals(fcmToken)))
        .getSingleOrNull();
    if (existing != null) {
      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(existing.gymId)
          .collection('device_tokens')
          .doc(fcmToken)
          .update({'isActive': false});
    }
  }

  Future<String> _getDeviceName() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return '${android.manufacturer} ${android.model}';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.name;
    }
    return 'Unknown Device';
  }

  Future<void> _syncTokenToFirestore({
    required String gymId,
    required String userId,
    required String token,
    required String? deviceName,
  }) async {
    await FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .collection('device_tokens')
      .doc(token)
      .set({
        'userId': userId,
        'fcmToken': token,
        'deviceName': deviceName,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
  }
}

final fcmTokenServiceProvider = Provider<FCMTokenService>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return FCMTokenService(db);
});
