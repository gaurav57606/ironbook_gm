import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockPinService extends Mock implements PinService {}
class MockHmacService extends Mock implements HmacService {}

MockFlutterSecureStorage createMockSecureStorage() {
  final storage = MockFlutterSecureStorage();
  when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
  when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenAnswer((_) async {});
  return storage;
}

MockPinService createMockPinService() {
  final service = MockPinService();
  when(() => service.verifyPin(any())).thenAnswer((_) async => true);
  return service;
}

MockHmacService createMockHmacService() {
  final service = MockHmacService();
  when(() => service.getInstallationId()).thenAnswer((_) async => 'test-device');
  return service;
}
