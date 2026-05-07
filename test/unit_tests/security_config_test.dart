import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/services/config_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('ConfigService Security Tests', () {
    late ConfigService configService;

    setUp(() {
      configService = ConfigService();
      dotenv.clean();
    });

    test('hmacSecret throws when HMAC_SECRET is missing', () {
      // dotenv throws NotInitializedError if accessed before any load,
      // but maybeGet should handle it if initialized with empty.
      dotenv.testLoad(fileInput: '');
      expect(() => configService.hmacSecret, throwsStateError);
    });

    test('hmacSecret throws StateError when HMAC_SECRET is empty', () {
      dotenv.testLoad(fileInput: 'HMAC_SECRET=');
      expect(() => configService.hmacSecret, throwsStateError);
    });

    test('hmacSecret throws StateError when HMAC_SECRET is default_secret', () {
      dotenv.testLoad(fileInput: 'HMAC_SECRET=default_secret');
      expect(() => configService.hmacSecret, throwsStateError);
    });

    test('hmacSecret throws StateError when HMAC_SECRET is dev_secret_only', () {
      dotenv.testLoad(fileInput: 'HMAC_SECRET=dev_secret_only');
      expect(() => configService.hmacSecret, throwsStateError);
    });

    test('hmacSecret returns the secret when valid', () {
      dotenv.testLoad(fileInput: 'HMAC_SECRET=super_secret_key_123');
      expect(configService.hmacSecret, 'super_secret_key_123');
    });
  });
}
