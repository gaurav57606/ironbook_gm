import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/providers/plan_provider.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/shared/widgets/app_button.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart' as model;
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:go_router/go_router.dart';
import '../test_helper.dart';

// Mocks for Notifiers
class MockMemberNotifier extends StateNotifier<List<MemberSnapshot>> with Mock implements MemberNotifier {
  MockMemberNotifier([super.state = const []]);
}
class MockPaymentNotifier extends StateNotifier<List<Payment>> with Mock implements PaymentNotifier {
  MockPaymentNotifier([super.state = const []]);
}
class MockPlanNotifier extends StateNotifier<List<model.Plan>> with Mock implements PlanNotifier {
  MockPlanNotifier([super.state = const []]);
}
// class MockBillingNotifier extends Mock implements BillingNotifier {}

class PlanFake extends Fake implements model.Plan {}
class dbPlanFake extends Fake implements db.Plan {}

void main() {
  late MockMemberNotifier mockMemberNotifier;
  late MockPaymentNotifier mockPaymentNotifier;
  late MockPlanNotifier mockPlanNotifier;
  // late MockBillingNotifier mockBillingNotifier;

  setUpAll(() {
    registerFallbackValue(PlanFake());
    registerFallbackValue(dbPlanFake());
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    mockMemberNotifier = MockMemberNotifier();
    mockPaymentNotifier = MockPaymentNotifier();
    mockPlanNotifier = MockPlanNotifier();
    // mockBillingNotifier = MockBillingNotifier();
    
    // Default Plan
    final testPlan = model.Plan(
      id: 'plan-monthly',
      name: 'Monthly',
      durationMonths: 1,
      price: 1000,
      components: [
        PlanComponent(id: 'c1', name: 'Base', price: 1000),
      ],
    );
    mockPlanNotifier.state = [testPlan];

    when(() => mockPaymentNotifier.recordMemberPayment(
      memberId: any(named: 'memberId'),
      plan: any(named: 'plan'),
      method: any(named: 'method'),
      date: any(named: 'date'),
    )).thenAnswer((_) async => Payment(
      id: 'p1', 
      memberId: 'm1', 
      date: DateTime.now(), 
      amount: 1000, 
      method: 'Cash', 
      planId: 'p1', 
      planName: 'Monthly', 
      durationMonths: 1, 
      invoiceNumber: 'INV1',
      subtotal: 847.46,
      gstAmount: 152.54,
      gstRate: 0.18,
      components: [],
    ));
  });

  group('QuickAddMemberScreen Form Validation', () {
    testWidgets('Register button is enabled even if fields are empty (app design)', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
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
          activePlansProvider.overrideWith((ref) => Stream.value([
            db.Plan(
              id: 'plan-monthly',
              name: 'Monthly',
              durationMonths: 1,
              price: 1000,
              active: true,
              hmacSignature: '',
              componentsJson: '[]',
            )
          ])),
        ],
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final buttonFinder = find.byKey(const ValueKey('register_button'), skipOffstage: false);
      expect(buttonFinder, findsOneWidget);

      final AppButton buttonWidget = tester.widget(buttonFinder);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('Shows error snackbar when submitting empty fields', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
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
          activePlansProvider.overrideWith((ref) => Stream.value([
            db.Plan(
              id: 'plan-monthly',
              name: 'Monthly',
              durationMonths: 1,
              price: 1000,
              active: true,
              hmacSignature: '',
              componentsJson: '[]',
            )
          ])),
        ],
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('register_button')));
      await tester.pump();

      expect(find.textContaining('Please enter name'), findsOneWidget);
    });

    testWidgets('Calls addMember on valid submission', (tester) async {
      when(() => mockMemberNotifier.addMember(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        planId: any(named: 'planId'),
        joinDate: any(named: 'joinDate'),
        gender: any(named: 'gender'),
        age: any(named: 'age'),
      )).thenAnswer((_) async => 'new-member-id');

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
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
          activePlansProvider.overrideWith((ref) => Stream.value([
            db.Plan(
              id: 'plan-monthly',
              name: 'Monthly',
              durationMonths: 1,
              price: 1000,
              active: true,
              hmacSignature: '',
              componentsJson: '[]',
            )
          ])),
        ],
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Alice Smith');
      await tester.enterText(find.byType(TextField).at(1), '9876543210');
      await tester.enterText(find.byType(TextField).at(2), '25');
      await tester.pump();

      final buttonFinder = find.byKey(const ValueKey('register_button'), skipOffstage: false);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => mockMemberNotifier.addMember(
        name: 'Alice Smith',
        phone: '9876543210',
        planId: 'plan-monthly',
        joinDate: any(named: 'joinDate'),
        gender: any(named: 'gender'),
        age: 25,
      )).called(1);

      verify(() => mockPaymentNotifier.recordMemberPayment(
        memberId: 'new-member-id',
        plan: any(named: 'plan'),
        method: any(named: 'method'),
        date: any(named: 'date'),
      )).called(1);
    });
  });
}
