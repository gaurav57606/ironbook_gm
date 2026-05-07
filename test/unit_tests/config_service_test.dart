import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/services/config_service.dart';

void main() {
  late ConfigService configService;

  setUp(() {
    configService = ConfigService();
  });

  group('ConfigService', () {
    test('apiUrl returns value from dotenv', () {
      dotenv.testLoad(fileInput: 'API_URL=https://custom.api');
      expect(configService.apiUrl, 'https://custom.api');
    });

    test('apiUrl returns fallback when missing', () {
      dotenv.testLoad(fileInput: '');
      expect(configService.apiUrl, 'https://api.ironbook.gym');
    });

    test('env returns value from dotenv', () {
      dotenv.testLoad(fileInput: 'ENV=production');
      expect(configService.env, 'production');
    });

    test('env returns fallback when missing', () {
      dotenv.testLoad(fileInput: '');
      expect(configService.env, 'development');
    });

    test('appName returns value from dotenv', () {
      dotenv.testLoad(fileInput: 'APP_NAME=Custom App');
      expect(configService.appName, 'Custom App');
    });

    test('appName returns fallback when missing', () {
      dotenv.testLoad(fileInput: '');
      expect(configService.appName, 'IronBook GM');
    });

    test('hmacSecret returns value from dotenv', () {
      dotenv.testLoad(fileInput: 'HMAC_SECRET=super_secret');
      expect(configService.hmacSecret, 'super_secret');
    });

    test('hmacSecret returns dev_secret_only in development when missing', () {
      dotenv.testLoad(fileInput: 'ENV=development');
      expect(configService.hmacSecret, 'dev_secret_only');
    });

    test('hmacSecret returns dev_secret_only in development when insecure', () {
      dotenv.testLoad(fileInput: 'ENV=development\nHMAC_SECRET=default_secret');
      expect(configService.hmacSecret, 'dev_secret_only');
    });

    test('hmacSecret throws StateError in production when missing', () {
      dotenv.testLoad(fileInput: 'ENV=production');
      expect(() => configService.hmacSecret, throwsStateError);
    });

    test('hmacSecret throws StateError in production when insecure', () {
      dotenv.testLoad(fileInput: 'ENV=production\nHMAC_SECRET=default_secret');
      expect(() => configService.hmacSecret, throwsStateError);
    });
  });
}
