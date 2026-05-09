import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/pin_entry_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/login_screen.dart';
import 'package:ironbook_gm/features/auth/onboarding/onboarding_screen.dart';
import 'package:ironbook_gm/features/auth/splash/splash_screen.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import '../helpers/test_harness.dart';
import '../helpers/mock_factory.dart';

void main() {
  setUpAll(() {
    MockFactory.registerFallbacks();
  });

  group('IronBook Autonomous Smoke Test', () {
    testWidgets('Full Application Lifecycle Smoke Test', (WidgetTester tester) async {
      // 1. Start with Onboarding (First Launch)
      await TestHarness.pumpOnboardingApp(tester);
      
      // GoRouter redirect handling: Multiple pumps to traverse Splash -> Onboarding
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify we are on onboarding
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      
      // 2. Mock state transition to Login (NOT first launch, NOT authenticated)
      FakeAuthNotifier.instance!.state = AuthState(isFirstLaunch: false, isAuthenticated: false, isLoading: false);
      for (int i = 0; i < 10; i++) await tester.pump(const Duration(milliseconds: 100));
      
      // Verify login screen
      if (find.byType(LoginScreen).evaluate().isEmpty) {
        debugPrint('FAILED TO FIND LoginScreen. Current widgets: ${tester.allWidgets.map((w) => w.runtimeType).join(', ')}');
      }
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Welcome Back'), findsOneWidget);

      // 3. Mock state transition to Authenticated BUT Locked (Requires PIN)
      FakeAuthNotifier.instance!.state = AuthState(
        isLoading: false,
        isFirstLaunch: false, 
        isAuthenticated: true, 
        isPinSetup: true, 
        unlocked: false
      );
      for (int i = 0; i < 10; i++) await tester.pump(const Duration(milliseconds: 100));
      
      // Verify PIN entry screen
      expect(find.byType(PinEntryScreen), findsOneWidget);
      expect(find.textContaining('Enter your PIN'), findsOneWidget);

      // 4. Mock state transition to Fully Authenticated & Unlocked
      FakeAuthNotifier.instance!.state = AuthState(
        isLoading: false,
        isFirstLaunch: false, 
        isAuthenticated: true, 
        isPinSetup: true, 
        unlocked: true
      );
      // Allow router to process multiple redirects (Unlock -> Dashboard)
      for(int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verify Dashboard content
      expect(find.text('DUE TODAY'), findsOneWidget);
      // Cleanup
      await tester.pumpWidget(const SizedBox());
      for(int i = 0; i < 10; i++) await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
