import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/core/widgets/app_text_field.dart';
import 'package:ironbook_gm/core/widgets/app_button.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import '../helpers/hive_test_helper.dart';

void main() {
  group('Add Member Form Test (TC-WID-02)', () {
    setUp(() async {
      await HiveTestHelper.setup();
      
      final plansBox = await Hive.openBox<Plan>('plans');
      final settingsBox = await Hive.openBox<AppSettings>('settings');
      await Hive.openBox<DomainEvent>('events');
      await Hive.openBox<MemberSnapshot>('snapshots');

      await plansBox.put('plan-monthly', Plan(
        id: 'plan-monthly',
        name: 'Monthly',
        durationMonths: 1,
        components: [
          PlanComponent(id: 'c1', name: 'Base', price: 1000),
        ],
      ));
      
      await settingsBox.put('settings', AppSettings(gstRate: 18));
    });

    tearDown(() async {
      await HiveTestHelper.tearDown();
    });

    testWidgets('Should add member and persist through provider on submit', (tester) async {
       // Setup minimal GoRouter
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const QuickAddMemberScreen(),
          ),
          GoRoute(
            path: '/members',
            builder: (context, state) => const Scaffold(body: Text('Members List')),
          ),
          GoRoute(
            path: '/dashboard',
             builder: (context, state) => const Scaffold(body: Text('Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.darkTheme(),
            routerConfig: router,
          ),
        ),
      );

      // Verify form is present
      expect(find.text('FULL NAME'), findsOneWidget);
      
      // Enter "Alice Smith"
      final nameField = find.descendant(
        of: find.widgetWithText(AppTextField, 'FULL NAME'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameField, 'Alice Smith');

      // Enter phone
      final phoneField = find.descendant(
        of: find.widgetWithText(AppTextField, 'PHONE NUMBER'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(phoneField, '1234567890');

      // Select Monthly Plan (index 0 - already selected by default state if 0)
      // The screen initializes _selectedPlan = 0
      
      // Click Register
      await tester.tap(find.byType(AppButton));
      
      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify Hive persistence directly (robust check)
      final snapshotsBox = Hive.box<MemberSnapshot>('snapshots');
      expect(snapshotsBox.length, 1);
      expect(snapshotsBox.values.first.name, 'Alice Smith');
    });

    testWidgets('Should show validation error if name is empty', (tester) async {
       final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const QuickAddMemberScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.darkTheme(),
            routerConfig: router,
          ),
        ),
      );

      // Click Register without entering name
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Verify snackbar
      expect(find.text('Please enter name'), findsOneWidget);
    });
  });
}
