import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as domain_plan;
import '../test_helper.dart';
import '../helpers/mock_factory.dart';

class FakeBillingNotifier extends Fake implements BillingNotifier {
  Future<void> recordMemberPayment({
    required String memberId,
    required db.Plan plan,
    required String method,
  }) async {
    debugPrint('[TEST] FakeBillingNotifier: recordMemberPayment called');
    return;
  }
}

void main() {
  setUpAll(() async {
    await TestHelper.setupHive('registration_flow');
    MockFactory.registerFallbacks();
  });

  group('Registration Flow Integration', () {
    late IMemberRepository mockMemberRepo;
    late IPlanRepository mockPlanRepo;
    late IBillingRepository mockBilling;

    setUp(() {
      mockMemberRepo = MockFactory.createMemberRepository();
      mockPlanRepo = MockFactory.createPlanRepository();
      mockBilling = MockFactory.createBillingRepository();
    });

    testWidgets('Complete registration flow from QuickAdd to Invoice', (WidgetTester tester) async {
      debugPrint('[TEST] Starting registration flow test');
      final dbPlan = db.Plan(
        id: 'plan_1',
        name: 'Basic Plan',
        price: 1000.0,
        durationMonths: 1,
        active: true,
        hmacSignature: '',
        componentsJson: '[]',
        isSynced: true,
      );

      final domainPlan = domain_plan.Plan(
        id: 'plan_1',
        name: 'Basic Plan',
        durationMonths: 1,
        price: 1000,
        components: [],
        active: true,
      );

      // Stubbing
      when(() => mockPlanRepo.getAllPlans()).thenAnswer((_) async => [domainPlan]);
      when(() => mockPlanRepo.getPlan(any())).thenAnswer((_) async => domainPlan);
      when(() => mockBilling.watchActivePlans()).thenAnswer((_) => Stream.value([dbPlan]));

      // Setup Router for verification
      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (context, state) => const QuickAddMemberScreen(),
          ),
          GoRoute(
            path: '/invoice',
            builder: (context, state) => const Scaffold(body: Center(child: Text('invoice_screen_reached'))),
          ),
        ],
      );

      debugPrint('[TEST] Pumping widget');
      await TestHelper.pumpIronBookWidget(
        tester,
        const SizedBox(),
        routerConfig: router,
        overrides: [
          memberRepositoryProvider.overrideWithValue(mockMemberRepo),
          planRepositoryProvider.overrideWithValue(mockPlanRepo),
          billingRepositoryProvider.overrideWithValue(mockBilling),
          billingNotifierProvider.overrideWith((ref) => FakeBillingNotifier()),
        ],
      );

      await tester.pump();

      // 1. Verify screen loaded
      expect(find.text('Add Member'), findsOneWidget);
      debugPrint('[TEST] Screen loaded');

      // 2. Enter details
      await tester.enterText(find.byType(TextFormField).at(0), 'Jane Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '1234567890');
      await tester.enterText(find.byType(TextFormField).at(2), '30');
      await tester.pump();
      debugPrint('[TEST] Details entered');

      // 3. Select Plan
      expect(find.text('Basic Plan'), findsOneWidget);
      await tester.tap(find.text('Basic Plan').first);
      await tester.pump();
      debugPrint('[TEST] Plan selected');

      // 4. Submit
      final submitBtn = find.byKey(const ValueKey('register_button'), skipOffstage: false);
      await tester.ensureVisible(submitBtn);
      debugPrint('[TEST] Tapping submit');
      await tester.tap(submitBtn);
      
      debugPrint('[TEST] Waiting for navigation');
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      debugPrint('[TEST] Verifying invoice screen');
      // 5. Verify Navigation Success
      expect(find.text('invoice_screen_reached'), findsOneWidget);
      debugPrint('[TEST] Navigation verified');

      // 6. Cleanup to prevent pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      debugPrint('[TEST] Test finished');
    });
  });
}
