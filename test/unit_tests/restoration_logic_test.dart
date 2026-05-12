import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
import 'package:ironbook_gm/core/sync/recovery_service.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/repositories/owner_repository.dart';
import 'package:ironbook_gm/core/data/repositories/settings_repository.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/local/models/app_settings_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:drift/native.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockFirebaseAuth mockAuth;
  late MockRecoveryService mockRecovery;
  late MockHmacService mockHmac;
  late MockFlutterSecureStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(MockUser());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockRecovery = MockRecoveryService();
    mockHmac = MockHmacService();
    mockStorage = MockFlutterSecureStorage();
    
    final mockOwnerRepo = MockOwnerRepo();
    final mockSettingsRepo = MockSettingsRepo();
    final mockEventRepo = MockEventRepository();
    final driftDb = OutboxDatabase(NativeDatabase.memory());

    // Setup default responses
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.fromIterable([null]));
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');
    when(() => mockHmac.syncCurrentKeyToCloud()).thenAnswer((_) async {});
    when(() => mockRecovery.recoverAll()).thenAnswer((_) async {});
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockOwnerRepo.getOwner()).thenAnswer((_) async => null);
    when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => AppSettings());

    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        recoveryServiceProvider.overrideWithValue(mockRecovery),
        hmacServiceProvider.overrideWithValue(mockHmac),
        appSecureStorageProvider.overrideWithValue(mockStorage),
        outboxDatabaseProvider.overrideWithValue(driftDb),
        outboxRepositoryProvider.overrideWith((ref) => OutboxRepository(driftDb)),
        ownerRepositoryProvider.overrideWithValue(mockOwnerRepo),
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
      ],
    );
  });

  test('AuthNotifier triggers HMAC sync and Recovery on new login', () async {
    final authNotifier = container.read(authProvider.notifier);
    
    // Create a stream controller to simulate state changes
    final authController = StreamController<fb.User?>();
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => authController.stream);

    // Simulate Firebase Ready
    authNotifier.onFirebaseReady(mockAuth);

    // Simulate Login (null -> user)
    final mockUser = MockUser();
    when(() => mockUser.uid).thenReturn('test-uid');
    when(() => mockUser.email).thenReturn('test@example.com');
    
    authController.add(mockUser);
    
    // Wait for the async listener to fire (it has two awaits)
    await Future.delayed(const Duration(milliseconds: 200));

    // Verify HMAC sync was triggered
    verify(() => mockHmac.syncCurrentKeyToCloud()).called(1);
    
    // Verify Recovery was triggered
    verify(() => mockRecovery.recoverAll()).called(1);
    
    await authController.close();
  });
}

class MockRecoveryService extends Mock implements RecoveryService {}
class MockHmacService extends Mock implements HmacService {}
class MockUser extends Mock implements fb.User {}
class MockOwnerRepo extends Mock implements IOwnerRepository {}
class MockSettingsRepo extends Mock implements ISettingsRepository {}
class MockEventRepository extends Mock implements IEventRepository {}
