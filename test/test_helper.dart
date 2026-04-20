import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ironbook_gm/app.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/data/local/models/invoice_sequence.dart' hide InvoiceSequenceAdapter;
import 'package:ironbook_gm/data/local/models/product_model.dart';
import 'package:ironbook_gm/data/local/models/sale_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/providers/base_providers.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironbook_gm/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/security/pin_service.dart';
import 'package:ironbook_gm/security/entitlement_guard.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/utils/clock.dart';

// Re-exports for convenience in tests
export 'package:flutter/material.dart';
export 'package:flutter_test/flutter_test.dart';
export 'package:mocktail/mocktail.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:ironbook_gm/providers/base_providers.dart';
export 'package:ironbook_gm/providers/auth_provider.dart';
export 'package:ironbook_gm/providers/bootstrap_provider.dart';
export 'package:ironbook_gm/security/entitlement_guard.dart';
export 'package:go_router/go_router.dart';
export 'package:ironbook_gm/app.dart';
export 'package:ironbook_gm/features/auth/presentation/screens/pin_entry_screen.dart';
export 'package:ironbook_gm/core/services/hmac_service.dart';
export 'package:ironbook_gm/core/utils/clock.dart';
export 'package:ironbook_gm/providers/member_provider.dart';
export 'package:ironbook_gm/providers/payment_provider.dart';
export 'package:ironbook_gm/providers/plan_provider.dart';
export 'package:ironbook_gm/features/members/presentation/screens/members_list_screen.dart';
export 'package:ironbook_gm/features/home/presentation/widgets/member_row.dart';
export 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
export 'package:ironbook_gm/data/local/models/domain_event_model.dart';
export 'package:ironbook_gm/data/repositories/event_repository.dart';

// Import and re-export mocks from integration_test/mocks
import '../integration_test/mocks/mock_firebase.dart';
import '../integration_test/mocks/mock_services.dart';
import '../integration_test/mocks/mock_firestore.dart';
import '../integration_test/mocks/mock_secure_storage.dart';
import '../integration_test/mocks/mock_entitlement.dart';

export '../integration_test/mocks/mock_firebase.dart';
export '../integration_test/mocks/mock_services.dart';
export '../integration_test/mocks/mock_firestore.dart';
export '../integration_test/mocks/mock_secure_storage.dart';
export '../integration_test/mocks/mock_entitlement.dart';

class TestHelper {

  static Future<void> setupHive([String subDir = 'default']) async {
    final tempDir = Directory.systemTemp.createTempSync('ironbook_test_${subDir}_');
    Hive.init(tempDir.path);
    
    _registerAdapters();
    await _openBoxes();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(DomainEventAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(MemberSnapshotAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PaymentAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlanAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlanComponentAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(OwnerProfileAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(JoinDateChangeAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PlanComponentSnapshotAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(InvoiceSequenceAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(SaleAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(SaleItemAdapter());
  }

  static Future<void> _openBoxes() async {
    await Hive.close();
    await Hive.openLazyBox<DomainEvent>('events');
    await Hive.openLazyBox<MemberSnapshot>('snapshots');
    await Hive.openBox<Payment>('payments');
    await Hive.openBox<Plan>('plans');
    await Hive.openBox<OwnerProfile>('owner');
    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox<InvoiceSequence>('invoice_sequences');
    await Hive.openBox<Product>('products');
    await Hive.openBox<Sale>('sales');
  }

  static Future<void> cleanHive() async {
    await Hive.deleteFromDisk();
  }

  static Box<T> getBox<T>() {
    final boxName = _getBoxNameForType<T>();
    return Hive.box<T>(boxName);
  }

  static String _getBoxNameForType<T>() {
    switch (T) {
      case DomainEvent: return 'events';
      case MemberSnapshot: return 'snapshots';
      case Payment: return 'payments';
      case Plan: return 'plans';
      case OwnerProfile: return 'owner';
      case AppSettings: return 'settings';
      case InvoiceSequence: return 'invoice_sequences';
      case Product: return 'products';
      case Sale: return 'sales';
      default: throw Exception('Unknown Box Type: $T');
    }
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
    when(() => mockSync.startPeriodicSync(any())).thenReturn(null);
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async => null);

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

// --- Common Fakes & Mocks ---

class FakeRepo implements IEventRepository {
  @override
  Future<void> persist(DomainEvent event) async {}
  @override
  Future<List<DomainEvent>> getAllUnsynced() async => [];
  @override
  Future<DomainEvent?> getById(String id) async => null;
  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async => [];
  @override
  Future<List<DomainEvent>> getAll() async => [];
  @override
  Future<void> markAsSynced(String eventId) async {}
  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

class FakeAuth extends AuthNotifier {
  FakeAuth({
    bool isLoading = false,
    bool isAuthenticated = true,
    bool isFirstLaunch = false,
    bool isPinSetup = true,
  }) : super(
    const FlutterSecureStorage(),
    MockPinService(),
    MockFirebaseAuth(),
    FakeRepo(),
    MockSyncWorker(),
    ProviderContainer() as dynamic, // Ref mock is tricky, use container as proxy or just cast
  ) {
    state = AuthState(
      isAuthenticated: isAuthenticated,
      unlocked: true,
      isPinSetup: isPinSetup,
      isFirstLaunch: isFirstLaunch,
      isLoading: isLoading,
      settings: AppSettings(),
      owner: OwnerProfile(gymName: 'Test Gym', ownerName: 'Tester', phone: '12345', address: ''),
    );
  }
  
  @override
  Future<void> _init() async {} // Prevent actual init
  
  @override
  Future<bool> verifyPin(String pin) async => true;

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
}

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
