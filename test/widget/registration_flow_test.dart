import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/main.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart' as domain_pay;
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as domain_plan;
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/shared/widgets/app_button.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';
import '../test_helper.dart';

class FakeDomainEvent extends Fake implements DomainEvent {}
class FakeMemberSnapshot extends Fake implements MemberSnapshot {}
class FakeDbPlan extends Fake implements db.Plan {}
class FakeDbPayment extends Fake implements db.Payment {}
class FakeMember extends Fake implements db.Member {}
class FakeDomainPlan extends Fake implements domain_plan.Plan {}
class FakeDomainPayment extends Fake implements domain_pay.Payment {}

class FakeBillingNotifier extends Fake implements BillingNotifier {
  @override
  Future<void> recordMemberPayment({
    required String memberId,
    required db.Plan plan,
    required String method,
  }) async {
    return;
  }
}

void main() {
  group('Registration Flow', () {
    late MockMemberRepo mockMemberRepo;
    late MockPlanRepo mockPlanRepo;
    late MockPaymentRepo mockPaymentRepo;
    late MockSequenceRepo mockSequenceRepo;
    late MockBillingRepository mockBilling;
    late FakeDriftEventRepository mockEventRepo;
    late MockHmacService mockHmac;
    late FakeSyncCoordinator mockSyncCoord;

    setUpAll(() async {
      await TestHelper.setupHive('registration');
      registerFallbackValue(FakeDomainEvent());
      registerFallbackValue(FakeMemberSnapshot());
      registerFallbackValue(FakeDbPlan());
      registerFallbackValue(FakeDbPayment());
      registerFallbackValue(FakeMember());
      registerFallbackValue(FakeDomainPlan());
      registerFallbackValue(FakeDomainPayment());
    });

    tearDownAll(() async {
      await TestHelper.cleanHive();
    });

    setUp(() {
      mockMemberRepo = MockMemberRepo();
      mockPlanRepo = MockPlanRepo();
      mockPaymentRepo = MockPaymentRepo();
      mockSequenceRepo = MockSequenceRepo();
      mockBilling = MockBillingRepository();
      mockEventRepo = FakeDriftEventRepository();
      mockHmac = MockHmacService();
      mockSyncCoord = FakeSyncCoordinator();
      
      when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-id');
      when(() => mockHmac.signEvent(any())).thenAnswer((_) async => 'sig');
    });

    testWidgets('QuickAddMemberScreen registration flow', (WidgetTester tester) async {
      final mockPreferencesRepo = MockPreferencesRepo();
      final mockSync = MockSyncWorker();
      final mockAuth = FakeAuth();
      final driftDb = TestHelper.setupDrift();
      addTearDown(() => driftDb.close());

      // Stubbing
      when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => []);
      when(() => mockMemberRepo.watchAllMembers()).thenAnswer((_) => Stream.value([]));
      when(() => mockMemberRepo.upsertMember(any())).thenAnswer((_) async => {});
      when(() => mockMemberRepo.getMember(any())).thenAnswer((_) async => null);

      final dbPlan = db.Plan(
        id: 'plan_1',
        name: 'Basic Plan',
        price: 1000.0,
        durationMonths: 1,
        active: true,
        hmacSignature: '',
      );

      final domainPlan = domain_plan.Plan(
        id: 'plan_1',
        name: 'Basic Plan',
        durationMonths: 1,
        components: [],
        active: true,
      );

      when(() => mockPlanRepo.getAllPlans()).thenAnswer((_) async => [domainPlan]);
      when(() => mockPlanRepo.getPlan(any())).thenAnswer((_) async => domainPlan);

      when(() => mockBilling.watchActivePlans()).thenAnswer((_) => Stream.value([dbPlan]));
      when(() => mockBilling.recordPayment(any())).thenAnswer((_) async => {});
      
      when(() => mockPaymentRepo.upsertPayment(any())).thenAnswer((_) async => {});
      when(() => mockPaymentRepo.getAllPayments()).thenAnswer((_) async => []);
      when(() => mockPreferencesRepo.getInt(any())).thenAnswer((_) async => 0);
      when(() => mockPreferencesRepo.setInt(any(), any())).thenAnswer((_) async => {});
      when(() => mockSequenceRepo.getNextInvoiceNumber(any())).thenAnswer((_) async => 'INV001');

      // Setup Screen Size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      // 1. Setup Router
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const QuickAddMemberScreen(),
          ),
          GoRoute(
            path: '/invoice',
            builder: (context, state) => const Scaffold(body: Text('invoice_screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            outboxDatabaseProvider.overrideWithValue(driftDb),
            clockProvider.overrideWith((ref) => FakeClock()),
            memberRepositoryProvider.overrideWithValue(mockMemberRepo),
            membersProvider.overrideWith((ref) => MemberNotifier(
              ref.watch(outboxDatabaseProvider),
              mockEventRepo,
              mockMemberRepo,
              mockPlanRepo,
              mockPreferencesRepo,
              ref.watch(clockProvider),
              mockHmac,
              mockSyncCoord,
            )),
            planRepositoryProvider.overrideWithValue(mockPlanRepo),
            activePlansProvider.overrideWith((ref) => Stream.value([dbPlan])),
            paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
            sequenceRepositoryProvider.overrideWithValue(mockSequenceRepo),
            preferencesRepositoryProvider.overrideWithValue(mockPreferencesRepo),
            syncWorkerProvider.overrideWithValue(mockSync),
            authProvider.overrideWith((ref) => mockAuth),
            billingRepositoryProvider.overrideWithValue(mockBilling),
            billingNotifierProvider.overrideWith((ref) => FakeBillingNotifier()),
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            hmacServiceProvider.overrideWithValue(mockHmac),
            syncCoordinatorProvider.overrideWithValue(mockSyncCoord),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.darkTheme(),
          ),
        ),
      );

      await tester.runAsync(() async {
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.text('Add Member'), findsOneWidget);

        // 1. Enter details
        await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
        await tester.enterText(find.byType(TextFormField).at(1), '1234567890');
        await tester.enterText(find.byType(TextFormField).at(2), '30');
        await tester.pump();

        // 2. Select Plan
        expect(find.text('Basic Plan'), findsOneWidget);
        await tester.tap(find.text('Basic Plan').first);
        await tester.pump();

        // 3. Submit
        final submitBtn = find.byKey(const Key('register_button'));
        await tester.ensureVisible(submitBtn);
        
        // Verify button enabled
        final AppButton buttonWidget = tester.widget(submitBtn);
        expect(buttonWidget.onPressed, isNotNull, reason: 'Register button should be enabled');

        await tester.tap(submitBtn);
        
        // Allow for navigation
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      });

      // 4. Verify Navigation
      expect(find.text('INVOICE SCREEN'), findsOneWidget);
    });
  });
}
