import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/bootstrap.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

void main() async {
  final container = ProviderContainer();
  
  // AppBootstrap handles Tier 1 (blocking) and Tier 2 (post-frame) init
  final result = await AppBootstrap.initialize(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: IronBookApp(hiveHealthy: result.hiveHealthy),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FcmService.processKillSignal(message);
}
