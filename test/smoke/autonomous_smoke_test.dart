import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/login_screen.dart';
import 'package:ironbook_gm/features/auth/onboarding/onboarding_screen.dart';
import 'package:drift/drift.dart';
import '../helpers/test_harness.dart';
import '../helpers/mock_factory.dart';

void main() {
  setUpAll(() {
    MockFactory.registerFallbacks();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('IronBook Autonomous Smoke Test', () {
    testWidgets('Verify Onboarding Screen', (WidgetTester tester) async {
      await TestHarness.pumpOnboardingApp(tester);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Verify Login Screen', (WidgetTester tester) async {
      await TestHarness.pumpTestApp(tester, isAuthenticated: false, isFirstLaunch: false);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Verify Dashboard Screen', (WidgetTester tester) async {
      await TestHarness.pumpDashboardApp(tester);
      // Wait for long animations to finish
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
