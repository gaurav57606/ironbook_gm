import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/signup_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/login_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'mocks/mock_auth.dart';
import 'infrastructure/test_harness.dart';
import 'infrastructure/test_database.dart';
import 'infrastructure/test_app.dart';
import 'infrastructure/test_bindings.dart';
import 'infrastructure/deterministic_pump.dart';

void main() {
  TestBootstrap.init();

  group('Scenario A: Auth & PIN Flow (Widget Test)', () {
    late TestHarness harness;

    setUp(() async {
      harness = TestHarness();
      await harness.setup();
      addTearDown(() => TestDatabaseFactory.dispose());
    });

    testWidgets('Full Onboarding -> Signup -> PIN Setup Flow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        createTestApp(
          overrides: harness.overrides,
          child: const IronBookApp(
            storageHealthy: true,
            useGoogleFonts: false,
          ),
        ),
      );

      // 1. Initially should be on Onboarding Screen (First Launch)
      await boundedPump(tester);
      expect(find.textContaining('Track every member'), findsOneWidget);
      await tester.tap(find.textContaining('Next').first);
      await boundedPump(tester);
      
      expect(find.textContaining('Instant invoices'), findsOneWidget);
      await tester.tap(find.textContaining('Next').first);
      await boundedPump(tester);
      
      expect(find.textContaining('Your gym, your rules'), findsOneWidget);
      await tester.tap(find.textContaining('Get started').first);
      await boundedPump(tester);

      // 2. After completing onboarding, should be redirected to Login Screen (not yet authenticated)
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      // 3. Navigate to Signup
      final signupLink = find.textContaining('Create an account', findRichText: true);
      expect(signupLink, findsOneWidget);
      await tester.ensureVisible(signupLink);
      await tester.tap(signupLink);
      await boundedPump(tester);
      expect(find.byType(SignupScreen), findsOneWidget);

      // 4. Fill signup form and complete Signup
      await tester.enterText(find.byKey(const Key('input-signup-gym')), 'IronBook Gym');
      await tester.enterText(find.byKey(const Key('input-signup-owner')), 'John Doe');
      await tester.enterText(find.byKey(const Key('input-signup-email')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('input-signup-phone')), '9876543210');
      await tester.enterText(find.byKey(const Key('input-signup-password')), 'Password123');
      await tester.enterText(find.byKey(const Key('input-signup-confirm')), 'Password123');
      await boundedPump(tester);

      // Tap Create Account button
      final signupBtn = find.byKey(const Key('btn-signup'));
      await tester.ensureVisible(signupBtn);
      await tester.tap(signupBtn, warnIfMissed: false);
      await boundedPump(tester);

      // 5. Finally on PIN Setup Screen (Authenticated but PIN not setup yet)
      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(find.text('Create your PIN'), findsOneWidget);
    });
  });
}
