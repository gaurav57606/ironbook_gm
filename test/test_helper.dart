import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ironbook_gm/app.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/data/local/models/product_model.dart';
import 'package:ironbook_gm/core/data/local/models/sale_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/config_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/google_fonts.dart';

// Re-exports for convenience in tests
export 'package:flutter/material.dart';
export 'package:flutter_test/flutter_test.dart';
export 'package:mocktail/mocktail.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:ironbook_gm/core/providers/base_providers.dart';
export 'package:ironbook_gm/core/providers/auth_provider.dart';
export 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
export 'package:ironbook_gm/core/security/entitlement_guard.dart';
export 'package:go_router/go_router.dart';
export 'package:ironbook_gm/app.dart';
export 'package:ironbook_gm/features/auth/presentation/screens/pin_entry_screen.dart';
export 'package:ironbook_gm/core/services/hmac_service.dart';
export 'package:ironbook_gm/shared/utils/clock.dart';
export 'package:ironbook_gm/core/providers/member_provider.dart';
export 'package:ironbook_gm/core/providers/payment_provider.dart';
export 'package:ironbook_gm/core/providers/plan_provider.dart';
export 'package:ironbook_gm/features/members/presentation/screens/members_list_screen.dart';
export 'package:ironbook_gm/features/home/presentation/widgets/member_row.dart';
export 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
export 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
export 'package:ironbook_gm/core/data/repositories/event_repository.dart';

// Import and re-export mocks from integration_test/mocks
import '../integration_test/mocks/mock_firebase.dart';
import '../integration_test/mocks/mock_services.dart';
import '../integration_test/mocks/mock_secure_storage.dart';

export '../integration_test/mocks/mock_firebase.dart';
export '../integration_test/mocks/mock_services.dart';
export '../integration_test/mocks/mock_firestore.dart';
export '../integration_test/mocks/mock_secure_storage.dart';
export '../integration_test/mocks/mock_entitlement.dart';

class TestHelper {

  static Future<void> setupHive([String subDir = 'default']) async {
    final tempDir = Directory.systemTemp.createTempSync('ironbook_test_${subDir}_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AppSettingsAdapter());
    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox('meta');
  }

  static Future<void> cleanHive() async {
    await Hive.deleteFromDisk();
  }

  static Future<void> pumpIronBookWidget(
    WidgetTester tester,
    Widget child, {
    List<Override> overrides = const [],
    RouterConfig<Object>? routerConfig,
  }) async {
    // Set a consistent viewport for stability
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    final mockAuth = MockFirebaseAuth();
    final mockPin = MockPinService();
    final mockSync = MockSyncWorker();
    final mockStorage = MockFlutterSecureStorage();
    
    // Register fallbacks for Mocktail
    try {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(BootstrapPhase.tier1Ready);
      registerFallbackValue(EntitlementStatus.valid);
    } catch (_) {
      // Already registered
    }
    
    // Default mocks
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.idTokenChanges()).thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.userChanges()).thenAnswer((_) => const Stream.empty());
    when(() => mockPin.verifyPin(any())).thenAnswer((_) async => true);
    when(() => mockPin.authenticate(pinFallback: any(named: 'pinFallback'))).thenAnswer((_) async => AuthResult.success);
    when(() => mockSync.startPeriodicSync(any())).thenReturn(null);
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});

    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(null),
          pinServiceProvider.overrideWithValue(mockPin),
          syncWorkerProvider.overrideWithValue(mockSync),
          appSecureStorageProvider.overrideWithValue(mockStorage),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
          tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
          clockProvider.overrideWith((ref) => FakeClock()),
          ...overrides,
        ],
        child: (routerConfig != null) 
          ? MaterialApp.router(
              theme: AppTheme.darkTheme(),
              debugShowCheckedModeBanner: false,
              routerConfig: routerConfig,
            )
          : (child is MaterialApp || child is IronBookApp) 
            ? child 
            : MaterialApp(
                theme: AppTheme.darkTheme(),
                debugShowCheckedModeBanner: false,
                home: child,
                builder: (context, child) {
                   // Ensure fonts and textures are ready
                   return child!;
                },
              ),
      ),
    );
    // Extra pumps for surface and state initialization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class MockAuth extends Mock implements AuthNotifier {}
class MockPinService extends Mock implements PinService {}
class MockSyncWorker extends Mock implements SyncWorker {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}
class MockConfigService extends Mock implements ConfigService {}

class FakeDriftEventRepository implements IEventRepository {
  final List<DomainEvent> _events = [];

  @override
  Future<void> persist(DomainEvent event) async {
    _events.add(event);
  }
  @override
  Future<List<DomainEvent>> getAllUnsynced() async => _events.where((e) => !e.synced).toList();
  @override
  Future<DomainEvent?> getById(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async => _events.where((e) => e.entityId == entityId).toList();
  @override
  Future<List<DomainEvent>> getAll() async => List.unmodifiable(_events);
  @override
  Future<List<DomainEvent>> getEventsSince(DateTime since) async => _events.where((e) => e.deviceTimestamp.isAfter(since)).toList();
  @override
  Future<void> markAsSynced(String eventId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      _events[idx] = _events[idx].copyWith(synced: true);
    }
  }
  @override
  Future<void> persistSynced(DomainEvent event) async {
    _events.add(event.copyWith(synced: true));
  }
  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

class MockRef extends Mock implements Ref {}

class FakeAuth extends AuthNotifier {
  FakeAuth({
    bool isLoading = false,
    bool isAuthenticated = true,
    bool isFirstLaunch = false,
    bool isPinSetup = true,
    bool unlocked = false,
  }) : super(
    const FlutterSecureStorage(),
    MockPinService(),
    MockFirebaseAuth(),
    FakeDriftEventRepository(),
    MockOwnerRepo(),
    MockSettingsRepo(),
    MockSyncWorker(),
    FakeHmacService(),
    MockConfigService(),
    MockRef(),
  ) {
    state = AuthState(
      isAuthenticated: isAuthenticated,
      unlocked: unlocked,
      isPinSetup: isPinSetup,
      isFirstLaunch: isFirstLaunch,
      isLoading: isLoading,
      settings: AppSettings(),
      owner: OwnerProfile(gymName: 'Test Gym', ownerName: 'Tester', phone: '12345', address: ''),
    );
  }
  
  Future<void> _init() async {} // Prevent actual init
  
  @override
  Future<bool> verifyPin(String pin) async => true;

  @override
  Future<bool> authenticate({String? pin}) async => pin != null;

  @override
  Future<void> completeOnboarding() async {
    state = state.copyWith(isFirstLaunch: false);
  }

  @override
  void onFirebaseReady(dynamic auth) {} // Noop
}

class MockHmacService extends Mock implements HmacService {}
class FakeHmacService extends Fake implements HmacService {
  @override
  Future<String> getInstallationId() async => 'test-device';
  @override
  Future<String> signEvent(DomainEvent event) async => 'fake-sig';
  @override
  Future<String> signSnapshot(String entityId, Map<String, dynamic> data) async => 'fake-sig';
  @override
  Future<bool> verifySnapshot(String entityId, Map<String, dynamic> data, String signature) async => true;
}

class MockOwnerRepo extends Mock implements IOwnerRepository {}
class MockSettingsRepo extends Mock implements ISettingsRepository {}
class MockMemberRepo extends Mock implements IMemberRepository {}
class MockPlanRepo extends Mock implements IPlanRepository {}
class MockPaymentRepo extends Mock implements IPaymentRepository {}
class MockPreferencesRepo extends Mock implements IPreferencesRepository {}
class MockProductRepo extends Mock implements IProductRepository {}
class MockSequenceRepo extends Mock implements ISequenceRepository {}
class MockSaleRepo extends Mock implements ISaleRepository {}

class FakeClock extends IClock {
  DateTime _now = DateTime(2025, 1, 1, 12, 0, 0);
  
  @override
  DateTime get now => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  void setNow(DateTime dateTime) {
    _now = dateTime;
  }
}


