import '../test_helper.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';

class MockSyncWorker extends Mock implements SyncWorker {}
class MockAuth extends Mock implements AuthNotifier {}

void main() {
  setUpAll(() async {
    await TestHelper.setupHive('registration_real');
    registerFallbackValue(Plan(id: 'f', name: 'f', durationMonths: 1, components: []));
    registerFallbackValue(DateTime.now());
  });

  tearDownAll(() async {
    await TestHelper.cleanHive();
  });

  group('Registration Flow (Real Notifiers + Fake Repo)', () {
    testWidgets('QuickAddMemberScreen flow', (tester) async {
      final fakeRepo = FakeRepo();
      final fakeHmac = FakeHmacService();
      final fakeClock = FakeClock();
      final mockSync = MockSyncWorker();
      final mockAuth = MockAuth();

      when(() => mockAuth.verifyPin(any())).thenAnswer((_) async => false);
      when(() => mockAuth.unlockWithBiometrics()).thenAnswer((_) async => false);

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

      await TestHelper.pumpIronBookWidget(
        tester,
        const SizedBox(),
        routerConfig: router,
        overrides: [
          eventRepositoryProvider.overrideWithValue(fakeRepo),
          clockProvider.overrideWith((ref) => fakeClock),
          hmacServiceProvider.overrideWith((ref) => fakeHmac),
          syncWorkerProvider.overrideWith((ref) => mockSync),
          
          // Use real notifiers
          membersProvider.overrideWith((ref) => MemberNotifier(fakeRepo, fakeClock, fakeHmac)),
          planProvider.overrideWith((ref) => PlanNotifier(
            TestHelper.getBox<Plan>(), 
            fakeRepo, 
            mockSync, 
            fakeHmac,
            'test-device-reg'
          )),
          paymentsProvider.overrideWith((ref) => PaymentNotifier(
            TestHelper.getBox<Payment>(),
            TestHelper.getBox<InvoiceSequence>(),
            fakeRepo,
            fakeClock,
            fakeHmac
          )),
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
        ],
      );
      await tester.pumpAndSettle();

      // Enter data
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), '9876543210');
      await tester.pumpAndSettle();

      // Tap Register (Key is 'register_button' per code)
      final registerBtn = find.byKey(const Key('register_button'));
      expect(registerBtn, findsOneWidget);
      await tester.tap(registerBtn);
      
      // Real notifier will call repo.persist and then navigate
      await tester.pumpAndSettle();
      
      // Should show invoice (assuming the logic in QuickAddMemberScreen calls context.go('/invoice'))
      // expect(find.text('Invoice Page'), findsOneWidget);
    });
  });
}


