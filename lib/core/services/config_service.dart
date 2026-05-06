import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigService {
  Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  String get apiUrl => dotenv.get('API_URL', fallback: 'https://api.ironbook.gym');
  String get env => dotenv.get('ENV', fallback: 'development');
  String get hmacSecret {
    final secret = dotenv.maybeGet('HMAC_SECRET');
    if (secret == null || secret == 'default_secret') {
      if (env == 'production') {
        throw StateError('CRITICAL: HMAC_SECRET is missing or insecure in production environment!');
      }
      return 'dev_secret_only';
    }
    return secret;
  }
  String get appName => dotenv.get('APP_NAME', fallback: 'IronBook GM');
}

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());
