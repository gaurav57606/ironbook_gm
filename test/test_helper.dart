import 'package:flutter_test/flutter_test.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ironbook_gm/app.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart'
    hide AppSettingsAdapter, MemberSnapshotAdapter, OwnerProfileAdapter;
import 'package:drift/native.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart'
    hide OwnerProfile, Payment, Plan, Sale, Product, InvoiceSequence;
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';

import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/owner_repository.dart';
import 'package:ironbook_gm/core/data/repositories/settings_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/repositories/product_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sale_repository.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironbook_gm/features/billing/data/billing_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';

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
export 'package:ironbook_gm/core/data/sync_worker.dart';
export 'package:ironbook_gm/core/providers/plan_provider.dart';
export 'package:ironbook_gm/features/members/presentation/screens/members_list_screen.dart';
export 'package:ironbook_gm/features/home/presentation/widgets/member_row.dart';
export 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
export 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
export 'package:ironbook_gm/core/data/local/models/payment_model.dart';
export 'package:ironbook_gm/core/data/local/models/plan_model.dart';
export 'package:ironbook_gm/core/data/repositories/event_repository.dart';
export 'package:ironbook_gm/core/data/repositories/member_repository.dart';
export 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
export 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
export 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
export 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
export 'package:ironbook_gm/features/billing/data/billing_repository.dart';
export 'package:ironbook_gm/core/services/sync_coordinator.dart';
export 'package:ironbook_gm/core/services/logger_service.dart';
export 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' hide Payment, Plan, Sale, Product, InvoiceSequence, OwnerProfile, Notification;
export 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';

// Import and re-export mocks from integration_test/mocks
import '../integration_test/mocks/mock_secure_storage.dart';
import '../integration_test/mocks/mock_firestore.dart';

export '../integration_test/mocks/mock_firebase.dart';
export '../integration_test/mocks/mock_services.dart';
export '../integration_test/mocks/mock_firestore.dart';
export '../integration_test/mocks/mock_secure_storage.dart';
export '../integration_test/mocks/mock_entitlement.dart';

class TestHelper {
  static Future<void> setupHive([String subDir = 'default']) async {
    final tempDir =
        Directory.systemTemp.createTempSync('ironbook_test_${subDir}_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(DomainEventAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(MemberSnapshotAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(InvoiceSequenceAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(PlanComponentSnapshotAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PlanAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PlanComponentAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(OwnerProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(JoinDateChangeAdapter());
    }

    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox('meta');
    await Hive.openLazyBox<MemberSnapshot>('snapshots');
    await Hive.openLazyBox<DomainEvent>('events');
  }

  static OutboxDatabase setupDrift() {
    return OutboxDatabase(NativeDatabase.memory());
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
    final mockFirestore = MockFirebaseFirestore();
    final driftDb = setupDrift();

    addTearDown(() async => await driftDb.close());

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
    when(() => mockAuth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.idTokenChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.userChanges()).thenAnswer((_) => const Stream.empty());
    when(() => mockPin.verifyPin(any())).thenAnswer((_) async => true);
    when(() => mockPin.authenticate(pinFallback: any(named: 'pinFallback')))
        .thenAnswer((_) async => AuthResult.success);
    when(() => mockSync.startPeriodicSync(any())).thenReturn(null);
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'))).thenAnswer((_) async {});

    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(mockFirestore),
          pinServiceProvider.overrideWithValue(mockPin),
          syncWorkerProvider.overrideWithValue(mockSync),
          appSecureStorageProvider.overrideWithValue(mockStorage),
          outboxDatabaseProvider.overrideWithValue(driftDb),
          outboxRepositoryProvider
              .overrideWith((ref) => OutboxRepository(driftDb)),
          bootstrapStateProvider
              .overrideWith((ref) => BootstrapPhase.tier2Ready),
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
                  ),
      ),
    );
    // Extra pumps for surface and state initialization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class MockAuth extends Mock implements AuthNotifier {}

class MockPinService extends Mock implements PinService {}

class MockSyncWorker extends Mock implements SyncWorker {}

class MockBillingRepository extends Mock implements IBillingRepository {}

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

typedef FakeRepo = FakeDriftEventRepository;

class FakeDriftEventRepository implements IEventRepository {
  final List<DomainEvent> _events = [];

  @override
  Future<void> persist(DomainEvent event) async {
    _events.add(event);
  }

  @override
  Future<List<DomainEvent>> getAllUnsynced() async =>
      _events.where((e) => !e.synced).toList();
  @override
  Future<DomainEvent?> getById(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DomainEvent>> getByEntityId(String entityId) async =>
      _events.where((e) => e.entityId == entityId).toList();

  @override
  Future<Map<String, List<DomainEvent>>> getByEntityIds(List<String> entityIds) async {
    final result = <String, List<DomainEvent>>{};
    for (final id in entityIds) {
      result[id] = _events.where((e) => e.entityId == id).toList();
    }
    return result;
  }
  @override
  Future<List<DomainEvent>> getAll() async => List.unmodifiable(_events);
  @override
  Future<List<DomainEvent>> getEventsSince(DateTime since) async =>
      _events.where((e) => e.deviceTimestamp.isAfter(since)).toList();
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
          FakeHmacService(),
          MockPreferencesRepo(),
          MockRef(),
        ) {
    state = AuthState(
      isAuthenticated: isAuthenticated,
      unlocked: unlocked,
      isPinSetup: isPinSetup,
      isFirstLaunch: isFirstLaunch,
      isLoading: isLoading,
    );
  }

  @override
  Future<void> init() async {} // Prevent actual init

  Future<bool> verifyPin(String pin) async => true;

  @override
  Future<bool> authenticate({String? pin}) async {
    if (pin != null) {
      state = state.copyWith(unlocked: true);
      return true;
    }
    return false;
  }

  @override
  Future<void> completeOnboarding() async {
    state = state.copyWith(isFirstLaunch: false);
  }

  @override
  Future<bool> signUp(String email, String password,
      {String? gymName, String? ownerName, String? phone}) async {
    state = state.copyWith(isAuthenticated: true, unlocked: true);
    return true;
  }

  @override
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isAuthenticated: true, unlocked: true);
    return true;
  }

  @override
  Future<void> signOut() async {
    state = state.copyWith(
      isAuthenticated: false,
      unlocked: false,
    );
  }

  @override
  Future<void> onFirebaseReady(fb.FirebaseAuth auth) async {} // Noop
}

class MockHmacService extends Mock implements HmacService {}

class FakeHmacService extends Fake implements HmacService {
  @override
  Future<String> getInstallationId() async => 'test-device';
  @override
  Future<String> signEvent(DomainEvent event) async => 'fake-sig';
  @override
  Future<String> signSnapshot(
          String entityId, Map<String, dynamic> data) async =>
      'fake-sig';
  @override
  Future<bool> verifySnapshot(
          String entityId, Map<String, dynamic> data, String signature) async =>
      true;
  @override
  Future<bool> verifyInstance(DomainEvent event) async => true;
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

class FakeSyncCoordinator extends Fake implements SyncCoordinator {
  @override
  void triggerSync() {}
  @override
  Stream<void> get onSyncRequested => const Stream.empty();
  @override
  Future<bool> acquireLock(String holderId) async => true;
  @override
  Future<void> releaseLock(String holderId) async {}
}

class FakePaymentNotifier extends StateNotifier<List<Payment>>
    implements PaymentNotifier {
  FakePaymentNotifier([List<Payment>? initial]) : super(initial ?? []);

  @override
  set debugState(List<Payment> payments) => state = payments;

  @override
  Future<Payment> recordMemberPayment({
    required String memberId,
    required Plan plan,
    required String method,
    String? reference,
    DateTime? date,
  }) async {
    final payment = Payment(
      id: 'p-${state.length + 1}',
      memberId: memberId,
      date: date ?? DateTime.now(),
      amount: plan.totalPrice,
      method: method,
      planId: plan.id,
      planName: plan.name,
      durationMonths: plan.durationMonths,
      invoiceNumber: 'INV-TEST-${state.length + 1}',
      components: plan.components.map((c) => PlanComponentSnapshot(name: c.name, price: c.price)).toList(),
      subtotal: plan.totalPrice / 1.18,
      gstAmount: plan.totalPrice - (plan.totalPrice / 1.18),
      gstRate: 0.18,
    );
    state = [payment, ...state];
    return payment;
  }

  Future<void> deletePayment(String paymentId) async {}

  @override
  Payment? getLatestForMember(String memberId) {
    return state.firstWhereOrNull((p) => p.memberId == memberId);
  }

  @override
  Future<void> rebuildCache() async {}
}

class FakeMemberNotifier extends StateNotifier<List<MemberSnapshot>>
    implements MemberNotifier {
  FakeMemberNotifier([List<MemberSnapshot>? initial]) : super(initial ?? []);

  @override
  set debugState(List<MemberSnapshot> members) => state = members;

  @override
  Future<void> init() async {}
  @override
  Future<void> rebuildCache() async {}
  @override
  Future<void> refreshFromDB() async {}
  @override
  Future<String> addMember({
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
    String? gender,
    int? age,
  }) async =>
      'new-member-id';
  @override
  Future<void> updateMember({
    required String memberId,
    required String name,
    required String phone,
  }) async {}
  @override
  Future<void> deleteMember(String memberId) async {}
  @override
  Future<void> recordAttendance(String memberId) async {}
}

class FakeLoggerService extends Fake implements LoggerService {
  @override
  void debug(String message, {String? category, Object? error, StackTrace? stackTrace}) {}
  @override
  void info(String message, {String? category, Object? error, StackTrace? stackTrace}) {}
  @override
  void warn(String message, {String? category, Object? error, StackTrace? stackTrace}) {}
  @override
  void error(String message, {String? category, Object? error, StackTrace? stackTrace}) {}
  @override
  void critical(String message, {String? category, Object? error, StackTrace? stackTrace}) {}
}
