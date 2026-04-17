import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/core/services/fcm_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockNavigatorState extends Mock implements NavigatorState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => super.toString();
}
class MockNotificationSettings extends Mock implements NotificationSettings {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;
  late MockFlutterSecureStorage mockStorage;
  late MockNavigatorState mockNavigator;
  late MockNotificationSettings mockSettings;

  setUpAll(() {
    registerFallbackValue(const RemoteMessage());
  });

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockStorage = MockFlutterSecureStorage();
    mockNavigator = MockNavigatorState();
    mockSettings = MockNotificationSettings();

    // Default setup for requestPermission
    when(() => mockMessaging.requestPermission(
      alert: any(named: 'alert'),
      badge: any(named: 'badge'),
      sound: any(named: 'sound'),
    )).thenAnswer((_) async => mockSettings);

    when(() => mockSettings.authorizationStatus).thenReturn(AuthorizationStatus.authorized);
    when(() => mockMessaging.getToken()).thenAnswer((_) async => 'fake-token');
    when(() => mockMessaging.getInitialMessage()).thenAnswer((_) async => null);

    // Default setup for storage
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    // Default setup for navigator
    when(() => mockNavigator.pushNamedAndRemoveUntil(any(), any(), arguments: any(named: 'arguments')))
        .thenAnswer((_) async => null);
  });

  group('FcmService.init', () {
    test('requests permissions and gets token when authorized', () async {
      // Use a channel stub to avoid MissingPluginException on FirebaseMessaging.onBackgroundMessage
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_messaging'),
        (methodCall) async {
          if (methodCall.method == 'Messaging#startBackgroundIsolate') {
            return null;
          }
          return null;
        },
      );

      await FcmService.init(messaging: mockMessaging);

      verify(() => mockMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      )).called(1);
      verify(() => mockMessaging.getToken()).called(1);
    });

    test('does not get token when unauthorized', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_messaging'),
        (methodCall) async => null,
      );

      when(() => mockSettings.authorizationStatus).thenReturn(AuthorizationStatus.denied);

      await FcmService.init(messaging: mockMessaging);

      verify(() => mockMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      )).called(1);
      verifyNever(() => mockMessaging.getToken());
    });
  });

  group('FcmService.processKillSignal', () {
    test('deletes storage keys and navigates when action is block_access', () async {
      const message = RemoteMessage(data: {'action': 'block_access'});

      await FcmService.processKillSignal(
        message,
        navigator: mockNavigator,
        storage: mockStorage,
      );

      verify(() => mockStorage.delete(key: 'ent_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'ent_cached_at')).called(1);
      verify(() => mockNavigator.pushNamedAndRemoveUntil('/paywall', any())).called(1);
    });

    test('does nothing when action is not block_access', () async {
      const message = RemoteMessage(data: {'action': 'other'});

      await FcmService.processKillSignal(
        message,
        navigator: mockNavigator,
        storage: mockStorage,
      );

      verifyNever(() => mockStorage.delete(key: any(named: 'key')));
      verifyNever(() => mockNavigator.pushNamedAndRemoveUntil(any(), any()));
    });
  });
}
