import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/security/pin_service.dart';
import 'package:ironbook_gm/security/entitlement_guard.dart';
import 'package:google_fonts/google_fonts.dart';

import '../integration_test/mocks/mock_firebase.dart';
import '../integration_test/mocks/mock_secure_storage.dart';
import '../integration_test/mocks/mock_entitlement.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = true;

  group('Autonomous Smoke Test - Visit All Screens', () {
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;
    late MockEntitlementGuard mockEntitlement;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
      mockEntitlement = MockEntitlementGuard();

      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(null));
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async {});
      when(() => mockEntitlement.checkEntitlement())
          .thenAnswer((_) async => EntitlementStatus.valid);
    });

    testWidgets('Smoke Test: Splash -> Onboarding -> Signup',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              secureStorageProvider.overrideWithValue(mockStorage),
              firebaseAuthProvider.overrideWithValue(mockAuth),
              entitlementProvider.overrideWithValue(mockEntitlement),
            ],
            child: const IronBookApp(
              hiveHealthy: true,
              useGoogleFonts: false,
            ),
          ),
        );

        // 1. Splash
        await tester.pump();
        expect(find.text('IronBook GM'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // 2. Onboarding
        expect(find.text('Track every member'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Get started'));
        await tester.pumpAndSettle();

        // 3. Signup
        expect(find.text('Create Account'), findsOneWidget);

        // Navigate to Login from Signup
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // 4. Login Screen
        expect(find.text('Welcome Back!'), findsOneWidget);
      });
    });

    testWidgets('Smoke Test: Dashboard (Authenticated)',
        (WidgetTester tester) async {
      final mockUser = MockUser();
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('test-user-id');

      // Pretend onboarding and PIN are done
      when(() => mockStorage.read(key: 'onboarding_done'))
          .thenAnswer((_) async => 'true');
      when(() => mockStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'hashed-pin');

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              secureStorageProvider.overrideWithValue(mockStorage),
              firebaseAuthProvider.overrideWithValue(mockAuth),
              entitlementProvider.overrideWithValue(mockEntitlement),
            ],
            child: const IronBookApp(
              hiveHealthy: true,
              useGoogleFonts: false,
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 3)); // Bypass splash
        await tester
            .pumpAndSettle(); // Should go to PIN ENTRY because it's not "unlocked" yet

        expect(find.text('Enter PIN'), findsOneWidget);

        // We skip UI PIN entry for this smoke test and force the provider state to unlocked?
        // No, let's actually enter the PIN if we can find the keys.
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('1'));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // 5. Dashboard
        expect(find.text('Admin Dashboard'), findsOneWidget);
      });
    });
  });
}
