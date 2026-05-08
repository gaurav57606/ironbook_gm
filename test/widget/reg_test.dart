import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../test_helper.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/features/billing/data/billing_repository.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    print('TEST: setUpAll started');
    await TestHelper.setupHive('registration_real');
    registerFallbackValue(DateTime.now());
    registerFallbackValue(FakePayment());
    registerFallbackValue(db.Plan(
      id: 'f', 
      name: 'f', 
      durationMonths: 1, 
      active: true, 
      price: 0, 
      componentsJson: '', 
      hmacSignature: ''
    ));
    print('TEST: setUpAll finished');
  });

  tearDownAll(() async {
    print('TEST: tearDownAll started');
    await TestHelper.cleanHive();
    print('TEST: tearDownAll finished');
  });

  group('Registration Flow (Real Notifiers + Fake Repo)', () {
    testWidgets('QuickAddMemberScreen flow', (tester) async {
      print('TEST: test started');
      
      final fakeRepo = FakeRepo();
      final fakeHmac = FakeHmacService();
      final fakeClock = FakeClock();
      final mockSync = MockSyncWorker();
      final mockBilling = MockBillingRepository();
      
      final testPlan = db.Plan(
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

      print('TEST: pumping widget');
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
      print('TEST: widget pumped');
      
      await tester.runAsync(() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        print('TEST: after initial pumps');

        // Enter data
        print('TEST: entering text');
        await tester.enterText(find.byType(TextField).at(0), 'John Doe');
        await tester.enterText(find.byType(TextField).at(1), '9876543210');
        await tester.pump();
        print('TEST: text entered');

        // Tap Register
        final registerBtn = find.byKey(const Key('register_button'));
        expect(registerBtn, findsOneWidget);
        print('TEST: tapping register');
        await tester.tap(registerBtn);
        
        print('TEST: pumping after tap');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      });
      
      print('TEST: test finished');
    });
  });
}

class FakePayment extends Fake implements db.Payment {}
