import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/bootstrap.dart';
import 'core/services/fcm_service.dart';
import 'app.dart';

void main() async {
  // 1. Core Binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Provider Container
  final container = ProviderContainer();
  
  // 3. Tier 1 Initialization (Hive/Drift) - Fast & Blocking
  final result = await AppBootstrap.initialize(container);

  // 4. Run App (Spawns Router -> Splash)
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







