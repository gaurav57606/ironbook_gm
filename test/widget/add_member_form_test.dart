import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/providers/payment_provider.dart';
import 'package:ironbook_gm/providers/plan_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../test_helper.dart';

// Mocks for Notifiers
class MockMemberNotifier extends Mock implements MemberNotifier {}
class MockPaymentNotifier extends Mock implements PaymentNotifier {}
class MockPlanNotifier extends Mock implements PlanNotifier {}

class PlanFake extends Fake implements Plan {}

void main() {
  late MockMemberNotifier mockMemberNotifier;
  late MockPaymentNotifier mockPaymentNotifier;
  late MockPlanNotifier mockPlanNotifier;

  setUpAll(() {
    registerFallbackValue(PlanFake());
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    mockMemberNotifier = MockMemberNotifier();
    mockPaymentNotifier = MockPaymentNotifier();
    mockPlanNotifier = MockPlanNotifier();
    
    // Default Plan
    final testPlan = Plan(
      id: 'plan-monthly',
      name: 'Monthly',
      durationMonths: 1,
      components: [
        PlanComponent(id: 'c1', name: 'Base', price: 1000),
      ],
    );
    
    // Stub state
    when(() => mockPlanNotifier.state).thenReturn([testPlan]);
    when(() => mockMemberNotifier.state).thenReturn([]);
    when(() => mockPaymentNotifier.state).thenReturn([]);

    // Success behaviors
    when(() => mockMemberNotifier.addMember(
      name: any(named: 'name'),
      phone: any(named: 'phone'),
      planId: any(named: 'planId'),
      joinDate: any(named: 'joinDate'),
    )).thenAnswer((_) async => 'test-member-id');

    when(() => mockPaymentNotifier.recordMemberPayment(
      memberId: any(named: 'memberId'),
      plan: any(named: 'plan'),
      method: any(named: 'method'),
    )).thenAnswer((_) async => Payment(
      id: 'p-1',
      memberId: 'test-member-id',
      date: DateTime.now(),
      amount: 1000,
      method: 'Cash',
      planId: 'plan-monthly',
      planName: 'Monthly',
      components: [],
      invoiceNumber: 'INV-1',
      subtotal: 847.45,
      gstAmount: 152.55,
      gstRate: 18,
      durationMonths: 1,
    ));

    await TestHelper.setupHive('add_member_mock');
  });

  tearDown(() async {
    await TestHelper.cleanHive();
  });

  group('Add Member Form Test (TC-WID-02)', () {
    testWidgets('Should add member and navigate to invoice on submit', (tester) async {
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
          membersProvider.overrideWith((ref) => mockMemberNotifier),
          paymentsProvider.overrideWith((ref) => mockPaymentNotifier),
          planProvider.overrideWith((ref) => mockPlanNotifier),
        ],
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Alice Smith');
      await tester.enterText(find.byType(TextField).at(1), '1234567890');

      final button = find.byKey(const Key('register_button'));
      await tester.tap(button);
      await tester.pumpAndSettle();

      verify(() => mockMemberNotifier.addMember(
        name: 'Alice Smith',
        phone: '1234567890',
        planId: any(named: 'planId'),
        joinDate: any(named: 'joinDate'),
      )).called(1);

      expect(find.text('Invoice Page'), findsOneWidget);
    });

    testWidgets('Should show validation error if name is empty', (tester) async {
       final router = GoRouter(
        initialLocation: '/add',
        routes: [
          GoRoute(
            path: '/add',
            builder: (context, state) => const QuickAddMemberScreen(),
          ),
        ],
      );

      await TestHelper.pumpIronBookWidget(
        tester,
        const SizedBox(),
        routerConfig: router,
        overrides: [
          membersProvider.overrideWith((ref) => mockMemberNotifier),
          paymentsProvider.overrideWith((ref) => mockPaymentNotifier),
          planProvider.overrideWith((ref) => mockPlanNotifier),
        ],
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('register_button'));
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Please enter name'), findsOneWidget);
    });
  });
}
