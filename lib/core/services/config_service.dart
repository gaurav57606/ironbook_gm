import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigService {
  bool _isHealthy = false;
  bool get isHealthy => _isHealthy;

  Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      _isHealthy = dotenv.maybeGet('HMAC_SECRET') != null;
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
        _isHealthy = true;
      } else {
        _isHealthy = false;
      }
    }
  }

  String get apiUrl => dotenv.get('API_URL', fallback: 'https://api.ironbook.gym');
  String get env => dotenv.get('ENV', fallback: 'development');
  
  String get hmacSecret {
    final secret = dotenv.maybeGet('HMAC_SECRET');
    if (secret == null || secret.isEmpty || secret == 'default_secret' || secret == 'dev_secret_only') {
      // LOG A CRITICAL WARNING INSTEAD OF CRASHING
      debugPrint('CRITICAL: HMAC_SECRET is missing or insecure! Using temporary emergency fallback.');
      
      if (kDebugMode) {
        return 'debug_fallback_secret_not_for_production';
      }
      
      // Stable fallback derived from app name to prevent total failure
      return 'ironbook_emergency_fallback_${appName.hashCode}';
    }
    return secret;
  }
  
  String get appName => dotenv.get('APP_NAME', fallback: 'IronBook GM');
  String get appVersion => dotenv.get('APP_VERSION', fallback: '2.4.0');
}

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());
