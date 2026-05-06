import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigService {
  Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  String get apiUrl => dotenv.get('API_URL', fallback: 'https://api.ironbook.gym');
  String get env => dotenv.get('ENV', fallback: 'development');
  String get hmacSecret => dotenv.get('HMAC_SECRET', fallback: 'default_secret');
  String get appName => dotenv.get('APP_NAME', fallback: 'IronBook GM');
}

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());
