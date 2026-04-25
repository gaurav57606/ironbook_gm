import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'dummy_api_key',
    appId: 'dummy_app_id',
    messagingSenderId: 'dummy_sender_id',
    projectId: 'dummy_project_id',
  );
}
