import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigService {
  Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: Failed to load .env file: $e');
      if (kIsWeb) {
        // Fallback for Flutter Web which sometimes struggles with root assets
        dotenv.testLoad(fileInput: '''
API_URL=https://api.ironbook.gym
ENV=development
HMAC_SECRET=ironbook_secret_key_2026
APP_NAME=IronBook GM
''');
      }
    }
  }

  String get apiUrl => dotenv.get('API_URL', fallback: 'https://api.ironbook.gym');
  String get env => dotenv.get('ENV', fallback: 'development');
  String get hmacSecret {
    final secret = dotenv.maybeGet('HMAC_SECRET');
    if (secret == null || secret.isEmpty || secret == 'default_secret' || secret == 'dev_secret_only') {
      throw StateError('CRITICAL: HMAC_SECRET is missing or insecure! Please set a strong secret in your .env file.');
    }
    return secret;
  }
  String get appName => dotenv.get('APP_NAME', fallback: 'IronBook GM');
}

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());
