import '../test_helper.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;

void main() {
  setUpAll(() async {
    debugPrint('TEST: setUpAll started');
    await TestHelper.setupHive('registration_real');
    registerFallbackValue(DateTime.now());
    registerFallbackValue(FakePayment());
    registerFallbackValue(const db.Plan(
      id: 'f', 
      name: 'f', 
      durationMonths: 1, 
      active: true, 
      price: 0, 
      componentsJson: '', 
      hmacSignature: ''
    ));
    debugPrint('TEST: setUpAll finished');
  });

  tearDownAll(() async {
    debugPrint('TEST: tearDownAll started');
    await TestHelper.cleanHive();
    debugPrint('TEST: tearDownAll finished');
  });

  group('Registration Flow (Real Notifiers + Fake Repo)', () {
    testWidgets('QuickAddMemberScreen flow', (tester) async {
      debugPrint('TEST: test started');
      
      final fakeRepo = FakeRepo();
      final fakeHmac = FakeHmacService();
      final fakeClock = FakeClock();
      final mockSync = MockSyncWorker();
      final mockBilling = MockBillingRepository();
      
      const testPlan = db.Plan(
        id: 'plan-1',
        name: 'Basic Plan',
        durationMonths: 1,
        active: true,
        price: 1000.0,
        componentsJson: '[]',
        hmacSignature: '',
      );
      
      when(() => mockBilling.watchActivePlans()).thenAnswer((_) => Stream.value([testPlan]));
      when(() => mockBilling.recordPayment(any())).thenAnswer((_) async => {});

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

      debugPrint('TEST: pumping widget');
      await TestHelper.pumpIronBookWidget(
        tester,
        const SizedBox(),
        routerConfig: router,
        overrides: [
          eventRepositoryProvider.overrideWithValue(fakeRepo),
          clockProvider.overrideWith((ref) => fakeClock),
          hmacServiceProvider.overrideWith((ref) => fakeHmac),
          syncWorkerProvider.overrideWith((ref) => mockSync),
          billingRepositoryProvider.overrideWithValue(mockBilling),
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
        ],
      );
      debugPrint('TEST: widget pumped');
      
      await tester.runAsync(() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        debugPrint('TEST: after initial pumps');

        // Enter data
        debugPrint('TEST: entering text');
        await tester.enterText(find.byType(TextField).at(0), 'John Doe');
        await tester.enterText(find.byType(TextField).at(1), '9876543210');
        await tester.pump();
        debugPrint('TEST: text entered');

        // Tap Register
        final registerBtn = find.byKey(const Key('register_button'));
        expect(registerBtn, findsOneWidget);
        debugPrint('TEST: tapping register');
        await tester.tap(registerBtn);
        
        debugPrint('TEST: pumping after tap');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      });
      
      debugPrint('TEST: test finished');
    });
  });
}

class FakePayment extends Fake implements db.Payment {}
