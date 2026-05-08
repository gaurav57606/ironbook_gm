import '../test_helper.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as domain;

class MockMemberRepo extends Mock implements IMemberRepository {}
class MockPlanRepo extends Mock implements IPlanRepository {}
class MockPaymentRepo extends Mock implements IPaymentRepository {}
class MockSequenceRepo extends Mock implements ISequenceRepository {}
class MockPreferencesRepo extends Mock implements IPreferencesRepository {}
class MockSyncWorker extends Mock implements SyncWorker {}
class MockAuthNotifier extends Mock implements AuthNotifier {}
class MockBillingRepo extends Mock implements IBillingRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(MemberSnapshot(
      memberId: 'f',
      name: 'f',
      phone: 'f',
      joinDate: DateTime.now(),
      gender: 'f',
      age: 20,
    ));
    registerFallbackValue(domain.Plan(
      id: 'f',
      name: 'f',
      durationMonths: 1,
      components: [],
    ));
    registerFallbackValue(Payment(
      id: 'f',
      memberId: 'f',
      date: DateTime.now(),
      amount: 0,
      method: 'f',
      invoiceNumber: 'f',
      subtotal: 0,
      gstAmount: 0,
      gstRate: 0,
      planId: 'f',
      planName: 'f',
      durationMonths: 1,
      components: [],
    ));
    registerFallbackValue(db.Payment(
      id: 'f',
      memberId: 'f',
      date: DateTime.now(),
      amount: 0,
      method: 'f',
      invoiceNumber: 'f',
      subtotal: 0,
      gstAmount: 0,
      gstRate: 0,
      planName: 'f',
      durationMonths: 1,
      hmacSignature: 'f',
    ));
  });

  group('Registration Flow (Real Notifiers + Fake Repo)', () {
    testWidgets('QuickAddMemberScreen flow', (tester) async {
      final mockMemberRepo = MockMemberRepo();
      final mockPlanRepo = MockPlanRepo();
      final mockPaymentRepo = MockPaymentRepo();
      final mockSequenceRepo = MockSequenceRepo();
      final mockPreferencesRepo = MockPreferencesRepo();
      final mockSync = MockSyncWorker();
      final mockAuth = MockAuthNotifier();
      final mockBilling = MockBillingRepo();

      // Stubbing
      when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => []);
      when(() => mockMemberRepo.watchAllMembers()).thenAnswer((_) => Stream.value([]));
      when(() => mockMemberRepo.upsertMember(any())).thenAnswer((_) async => {});
      when(() => mockMemberRepo.getMember(any())).thenAnswer((_) async => null);

      const testDbPlan = db.Plan(
        id: '1', 
        name: 'Basic Plan', 
        durationMonths: 1, 
        active: true, 
        price: 1000, 
        componentsJson: '[]', 
        hmacSignature: ''
      );

      final testDomainPlan = domain.Plan(
        id: '1',
        name: 'Basic Plan',
        durationMonths: 1,
        components: [],
      );

      when(() => mockPlanRepo.getAllPlans()).thenAnswer((_) async => [testDomainPlan]);
      when(() => mockPlanRepo.getPlan(any())).thenAnswer((_) async => testDomainPlan);

      when(() => mockBilling.watchActivePlans()).thenAnswer((_) => Stream.value([testDbPlan]));
      when(() => mockBilling.recordPayment(any())).thenAnswer((_) async => {});

      when(() => mockPaymentRepo.upsertPayment(any())).thenAnswer((_) async => {});
      when(() => mockPaymentRepo.getAllPayments()).thenAnswer((_) async => []);
      when(() => mockSequenceRepo.getNextInvoiceNumber(any())).thenAnswer((_) async => 'INV-001');
      
      when(() => mockAuth.state).thenReturn(AuthState(
        isLoading: false,
        isAuthenticated: true,
      ));
      when(() => mockAuth.init()).thenAnswer((_) async => {});
      when(() => mockSync.performSync()).thenAnswer((_) async => {});
      when(() => mockSync.startPeriodicSync(any())).thenReturn(null);

      final router = GoRouter(
        initialLocation: '/add',
        routes: [
          GoRoute(
            path: '/add',
            builder: (context, state) => const QuickAddMemberScreen(),
          ),
          GoRoute(
            path: '/invoice',
            builder: (context, state) => const Scaffold(body: Text('Invoice Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memberRepositoryProvider.overrideWithValue(mockMemberRepo),
            planRepositoryProvider.overrideWithValue(mockPlanRepo),
            paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
            sequenceRepositoryProvider.overrideWithValue(mockSequenceRepo),
            preferencesRepositoryProvider.overrideWithValue(mockPreferencesRepo),
            syncWorkerProvider.overrideWithValue(mockSync),
            billingRepositoryProvider.overrideWithValue(mockBilling),
            authProvider.overrideWith((ref) => mockAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Fill form
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), '9876543210');
      await tester.pump();

      // Select Plan
      final planTile = find.text('Basic Plan');
      expect(planTile, findsOneWidget);
      await tester.tap(planTile);
      await tester.pumpAndSettle();

      // Tap Register
      final registerBtn = find.text('Register & Generate Invoice');
      // Scroll to ensure it's built in ListView
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      
      expect(registerBtn, findsOneWidget);
      await tester.tap(registerBtn);
      
      // Pump to allow async work and navigation
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify navigation to Invoice Page
      expect(find.text('Invoice Page'), findsOneWidget);
    });
  });
}
