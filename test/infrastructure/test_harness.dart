import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../mocks/mock_auth.dart';
import '../mocks/mock_security.dart';
import '../mocks/mock_sync.dart';
import '../mocks/mock_notifications.dart';
import '../mocks/mock_repositories.dart';
import 'test_database.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/notification_gateway.dart';

class TestHarness {
  final List<Override> overrides = [];
  
  late MockFirebaseAuth mockAuth;
  late MockPinService mockPin;
  late MockSyncWorker mockSync;
  late MockFlutterSecureStorage mockStorage;
  late MockNotificationGateway mockNotifications;
  
  ProviderContainer? _container;
  ProviderContainer get container => _container ??= ProviderContainer(overrides: overrides);
  
  Future<void> setup() async {
    _registerFallbacks();
    mockAuth = createMockFirebaseAuth();
    mockPin = createMockPinService();
    mockSync = createMockSyncWorker();
    mockStorage = createMockSecureStorage();
    mockNotifications = createMockNotificationGateway();
    
    final db = await TestDatabaseFactory.create();
    
    overrides.addAll([
      firebaseAuthProvider.overrideWithValue(mockAuth),
      pinServiceProvider.overrideWithValue(mockPin),
      syncWorkerProvider.overrideWithValue(mockSync),
      appSecureStorageProvider.overrideWithValue(mockStorage),
      notificationGatewayProvider.overrideWithValue(mockNotifications),
      outboxDatabaseProvider.overrideWithValue(db),
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
      tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
      entitlementStatusProvider.overrideWith((ref) => EntitlementStatus.valid),
    ]);
    
    // Register fallbacks
    _registerFallbacks();
  }

  void _registerFallbacks() {
    try {
      registerFallbackValue(BootstrapPhase.tier1Ready);
      registerFallbackValue(EntitlementStatus.valid);
      registerFallbackValue(Duration.zero);
      registerFallbackValue(const NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification));
      registerFallbackValue(const AndroidNotificationDetails('f', 'f'));
      registerFallbackValue(const DarwinNotificationDetails());
    } catch (_) {}
  }
}
