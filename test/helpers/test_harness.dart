import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/router/app_router.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/config_service.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/features/billing/data/billing_repository.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'mock_factory.dart';
import 'fake_repositories.dart';

class TestHarness {
  static Future<void> pumpTestApp(
    WidgetTester tester, {
    List<Override> overrides = const [],
    Widget? child,
    bool isAuthenticated = true,
    bool isUnlocked = true,
    bool isFirstLaunch = false,
    Key? key,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Set a consistent viewport
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final mockConfig = MockFactory.createConfigService();
    final mockLogger = MockFactory.createLoggerService();
    final mockHmac = MockFactory.createHmac();
    final mockSync = MockFactory.createSyncWorker();
    final mockPin = MockFactory.createPinService();
    final mockAuthNotifier = FakeAuthNotifier(AuthState(
        isAuthenticated: isAuthenticated,
        unlocked: isUnlocked,
        isFirstLaunch: isFirstLaunch,
        isPinSetup: true,
        isLoading: false,
      ),
    );
    final mockStorage = MockFactory.createStorage();
    final mockMemberRepo = MockFactory.createMemberRepository();
    final mockPlanRepo = MockFactory.createPlanRepository();
    final mockBillingRepo = MockFactory.createBillingRepository();
    final mockPreferencesRepo = MockFactory.createPreferencesRepository();
    final mockOutboxRepo = MockFactory.createOutboxRepository();
    
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    final mockSequenceRepo = MockFactory.createSequenceRepository();
    final mockPaymentRepo = MockFactory.createPaymentRepository();
    final fakeEventRepo = FakeDriftEventRepository();
    final fakeSyncCoord = FakeSyncCoordinator();
    final fakeClock = FakeClock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configServiceProvider.overrideWithValue(mockConfig),
          loggerProvider.overrideWithValue(mockLogger),
          hmacServiceProvider.overrideWithValue(mockHmac),
          syncWorkerProvider.overrideWithValue(mockSync),
          pinServiceProvider.overrideWithValue(mockPin),
          authProvider.overrideWith((ref) => mockAuthNotifier),
          appSecureStorageProvider.overrideWithValue(mockStorage),
          unsyncedCountProvider.overrideWith((ref) => Stream.value(0)),
          outboxRepositoryProvider.overrideWithValue(mockOutboxRepo),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
          tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
          entitlementStatusProvider.overrideWith((ref) => EntitlementStatus.valid),
          memberRepositoryProvider.overrideWithValue(mockMemberRepo),
          planRepositoryProvider.overrideWithValue(mockPlanRepo),
          billingRepositoryProvider.overrideWithValue(mockBillingRepo),
          preferencesRepositoryProvider.overrideWithValue(mockPreferencesRepo),
          sequenceRepositoryProvider.overrideWithValue(mockSequenceRepo),
          paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
          eventRepositoryProvider.overrideWithValue(fakeEventRepo),
          syncCoordinatorProvider.overrideWithValue(fakeSyncCoord),
          clockProvider.overrideWithValue(fakeClock),
          ...overrides,
        ],
        child: child ?? IronBookApp(
          key: key,
          storageHealthy: true, 
          useGoogleFonts: false
        ),
      ),
    );

    // Initial stabilization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  static Future<void> pumpAuthenticatedApp(WidgetTester tester, {List<Override> overrides = const [], Key? key}) async {
    await pumpTestApp(tester, isAuthenticated: true, isUnlocked: true, overrides: overrides, key: key);
  }

  static Future<void> pumpOnboardingApp(WidgetTester tester, {List<Override> overrides = const [], Key? key}) async {
    await pumpTestApp(tester, isAuthenticated: false, isFirstLaunch: true, overrides: overrides, key: key);
  }

  static Future<void> pumpDashboardApp(WidgetTester tester, {List<Override> overrides = const [], Key? key}) async {
    await pumpAuthenticatedApp(tester, overrides: overrides, key: key);
    // Wait for router to settle on dashboard
    await tester.pump(const Duration(milliseconds: 100));
  }
}
