import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/services/logger_service.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db_drift;
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/features/billing/data/billing_repository.dart';
import 'package:ironbook_gm/core/services/config_service.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as domain_plan;
import 'package:ironbook_gm/core/data/local/models/payment_model.dart' as domain_payment;

// Mocks
class MockAuthNotifier extends Mock implements AuthNotifier {}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  static FakeAuthNotifier? instance;

  FakeAuthNotifier(super.state) {
    instance = this;
  }
  
  @override
  Future<void> init() async {}
  
  @override
  Future<void> onFirebaseReady(fb.FirebaseAuth auth) async {}
  
  @override
  Future<void> completeOnboarding() async {
    state = state.copyWith(isFirstLaunch: false);
  }
  
  @override
  Future<bool> authenticate({String? pin}) async => true;
  
  @override
  Future<bool> login(String email, String password) async => true;
  
  @override
  void triggerBackgroundRecovery() {}
  
  @override
  void lock() {}
  
  @override
  Future<void> logout() async {}
  
  @override
  Future<void> setPin(String pin) async {}
  
  @override
  Future<void> clearPin() async {}
  
  @override
  Future<void> setBiometricOptIn(bool enabled) async {}
  
  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> signUp(String email, String password, {String? gymName, String? ownerName, String? phone}) async => true;
}

class MockConfigService extends Mock implements ConfigService {}
class MockStorage extends Mock implements FlutterSecureStorage {}
class MockLoggerService extends Mock implements LoggerService {}
class MockHmacService extends Mock implements HmacService {}
class MockOutboxRepository extends Mock implements OutboxRepository {}
class MockSyncWorker extends Mock implements SyncWorker {}
class MockPinService extends Mock implements PinService {}
class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}
class MockUser extends Mock implements fb.User {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockTransaction extends Mock implements Transaction {}
class MockMemberRepository extends Mock implements IMemberRepository {}
class MockPlanRepository extends Mock implements IPlanRepository {}
class MockPaymentRepository extends Mock implements IPaymentRepository {}
class MockPreferencesRepository extends Mock implements IPreferencesRepository {}
class MockSequenceRepository extends Mock implements ISequenceRepository {}
class MockBillingRepository extends Mock implements IBillingRepository {}

class MockFactory {
  static void registerFallbacks() {
    try {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(LogLevel.info);
      registerFallbackValue(DomainEvent(
        id: 'fallback',
        entityId: 'fallback',
        eventType: EventType.memberCreated,
        payload: {},
        deviceTimestamp: DateTime.now(),
        deviceId: 'fallback',
      ));
      registerFallbackValue(MemberSnapshot(
        memberId: 'fallback',
        name: 'fallback',
        joinDate: DateTime.now(),
      ));
      registerFallbackValue(domain_plan.Plan(
        id: 'fallback',
        name: 'fallback',
        durationMonths: 1,
        price: 0,
        components: [],
        active: true,
      ));
      registerFallbackValue(domain_payment.Payment(
        id: 'fallback',
        memberId: 'fallback',
        amount: 0,
        date: DateTime.now(),
        method: 'cash',
        invoiceNumber: 'fallback',
        subtotal: 0,
        gstAmount: 0,
        gstRate: 0.18,
        durationMonths: 1,
        planId: 'fallback',
        planName: 'fallback',
        components: [],
      ));
      // Drift Payment Fallback
      registerFallbackValue(db_drift.Payment(
        id: 'fallback',
        memberId: 'fallback',
        date: DateTime.now(),
        amount: 0,
        method: 'cash',
        invoiceNumber: 'fallback',
        subtotal: 0,
        gstAmount: 0,
        gstRate: 0.18,
        durationMonths: 1,
        planId: 'fallback',
        planName: 'fallback',
        hmacSignature: 'fallback',
        isSynced: true,
      ));
      registerFallbackValue(db_drift.Notification(
        id: 'fallback',
        title: 'fallback',
        body: 'fallback',
        timestamp: DateTime.now(),
        category: 'fallback',
        isRead: false,
        payload: null,
      ));
    } catch (_) {}
  }

  static MockConfigService createConfigService() {
    final mock = MockConfigService();
    when(() => mock.apiUrl).thenReturn('https://api.ironbook.gym');
    when(() => mock.hmacSecret).thenReturn('test_secret_key_2026');
    when(() => mock.env).thenReturn('development');
    when(() => mock.appName).thenReturn('IronBook GM');
    return mock;
  }

  static MockLoggerService createLoggerService() {
    final mock = MockLoggerService();
    when(() => mock.log(any(), 
        level: any(named: 'level'), 
        category: any(named: 'category'), 
        error: any(named: 'error'), 
        stackTrace: any(named: 'stackTrace')))
      .thenReturn(null);
    when(() => mock.debug(any(), category: any(named: 'category'))).thenReturn(null);
    when(() => mock.info(any(), category: any(named: 'category'), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).thenReturn(null);
    when(() => mock.warn(any(), category: any(named: 'category'), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).thenReturn(null);
    when(() => mock.error(any(), category: any(named: 'category'), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).thenReturn(null);
    when(() => mock.critical(any(), category: any(named: 'category'), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).thenReturn(null);
    when(() => mock.setUserId(any())).thenAnswer((_) async {});
    return mock;
  }

  static MockHmacService createHmac() {
    final mock = MockHmacService();
    when(() => mock.getInstallationId()).thenAnswer((_) async => 'test-device-id');
    when(() => mock.signEvent(any())).thenAnswer((_) async => 'fake-signature');
    when(() => mock.signSnapshot(any(), any())).thenAnswer((_) async => 'fake-snapshot-signature');
    when(() => mock.verifySnapshot(any(), any(), any())).thenAnswer((_) async => true);
    when(() => mock.verifyInstance(any())).thenAnswer((_) async => true);
    return mock;
  }

  static MockOutboxRepository createOutboxRepository() {
    final mock = MockOutboxRepository();
    when(() => mock.insertEvent(any())).thenAnswer((_) async {});
    when(() => mock.getUnsyncedEvents()).thenAnswer((_) async => []);
    when(() => mock.markSynced(any())).thenAnswer((_) async {});
    when(() => mock.countUnsynced()).thenAnswer((_) async => 0);
    when(() => mock.watchUnsyncedCount()).thenAnswer((_) => Stream.value(0));
    when(() => mock.seedFromHive(any())).thenAnswer((_) async {});
    when(() => mock.purgeSyncedBefore(any())).thenAnswer((_) async {});
    when(() => mock.getPinAttempts()).thenAnswer((_) async => null);
    when(() => mock.updatePinAttempts(count: any(named: 'count'), lockoutUntil: any(named: 'lockoutUntil'))).thenAnswer((_) async {});
    when(() => mock.resetPinAttempts()).thenAnswer((_) async {});
    when(() => mock.clearAll()).thenAnswer((_) async {});
    when(() => mock.watchNotifications()).thenAnswer((_) => Stream<List<db_drift.Notification>>.value(<db_drift.Notification>[]));
    when(() => mock.insertNotification(any())).thenAnswer((_) async {});
    when(() => mock.markNotificationAsRead(any())).thenAnswer((_) async {});
    when(() => mock.markAllNotificationsAsRead()).thenAnswer((_) async {});
    when(() => mock.deleteNotification(any())).thenAnswer((_) async {});
    return mock;
  }

  static MockSyncWorker createSyncWorker() {
    final mock = MockSyncWorker();
    when(() => mock.startPeriodicSync(any())).thenReturn(null);
    when(() => mock.performSync()).thenAnswer((_) async => {});
    return mock;
  }

  static MockPinService createPinService() {
    final mock = MockPinService();
    when(() => mock.verifyPin(any())).thenAnswer((_) async => true);
    when(() => mock.authenticate(pinFallback: any(named: 'pinFallback'))).thenAnswer((_) async => AuthResult.success);
    when(() => mock.setPin(any())).thenAnswer((_) async {});
    when(() => mock.savePin(any())).thenAnswer((_) async {});
    when(() => mock.getFailCount()).thenAnswer((_) async => 0);
    when(() => mock.getLockoutUntil()).thenAnswer((_) async => null);
    return mock;
  }

  static MockFirebaseFirestore createFirestore() {
    final mock = MockFirebaseFirestore();
    // Complex firestore mocking might need more setup, but here are basic voids
    when(() => mock.runTransaction<dynamic>(any(), timeout: any(named: 'timeout'), maxAttempts: any(named: 'maxAttempts')))
        .thenAnswer((_) async => null);
    return mock;
  }

  static MockAuthNotifier createAuthNotifier({AuthState? initialState}) {
    final mock = MockAuthNotifier();
    final state = initialState ?? AuthState(isAuthenticated: true, unlocked: true);
    // Since AuthNotifier is a StateNotifier, we need to mock the state property if used directly, 
    // but usually we mock methods.
    when(() => mock.state).thenReturn(state);
    when(() => mock.init()).thenAnswer((_) async {});
    when(() => mock.login(any(), any())).thenAnswer((_) async => true);
    when(() => mock.signUp(any(), any(), gymName: any(named: 'gymName'), ownerName: any(named: 'ownerName'), phone: any(named: 'phone')))
        .thenAnswer((_) async => true);
    when(() => mock.logout()).thenAnswer((_) async {});
    when(() => mock.completeOnboarding()).thenAnswer((_) async {});
    when(() => mock.authenticate(pin: any(named: 'pin'))).thenAnswer((_) async => true);
    return mock;
  }

  static MockFlutterSecureStorage createStorage() {
    final mock = MockFlutterSecureStorage();
    when(() => mock.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mock.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
    when(() => mock.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => mock.deleteAll()).thenAnswer((_) async {});
    return mock;
  }

  static MockMemberRepository createMemberRepository() {
    final mock = MockMemberRepository();
    when(() => mock.getAllMembers()).thenAnswer((_) async => []);
    when(() => mock.watchAllMembers()).thenAnswer((_) => Stream.value([]));
    when(() => mock.upsertMember(any())).thenAnswer((_) async => {});
    when(() => mock.applyEvent(any())).thenAnswer((_) async => {});
    when(() => mock.getMember(any())).thenAnswer((_) async => null);
    return mock;
  }

  static MockPlanRepository createPlanRepository() {
    final mock = MockPlanRepository();
    when(() => mock.getAllPlans()).thenAnswer((_) async => []);
    when(() => mock.getPlan(any())).thenAnswer((_) async => null);
    return mock;
  }

  static MockBillingRepository createBillingRepository() {
    final mock = MockBillingRepository();
    when(() => mock.watchActivePlans()).thenAnswer((_) => Stream.value([]));
    when(() => mock.recordPayment(any())).thenAnswer((_) async => {});
    return mock;
  }

  static MockPreferencesRepository createPreferencesRepository() {
    final mock = MockPreferencesRepository();
    when(() => mock.getInt(any())).thenAnswer((_) async => null);
    when(() => mock.setInt(any(), any())).thenAnswer((_) async => {});
    when(() => mock.getString(any())).thenAnswer((_) async => null);
    when(() => mock.setString(any(), any())).thenAnswer((_) async => {});
    return mock;
  }

  static MockSequenceRepository createSequenceRepository() {
    final mock = MockSequenceRepository();
    when(() => mock.getNextInvoiceNumber(any())).thenAnswer((_) async => 'INV-001');
    return mock;
  }

  static MockPaymentRepository createPaymentRepository() {
    final mock = MockPaymentRepository();
    when(() => mock.getAllPayments()).thenAnswer((_) async => []);
    when(() => mock.upsertPayment(any())).thenAnswer((_) async => {});
    return mock;
  }
}
