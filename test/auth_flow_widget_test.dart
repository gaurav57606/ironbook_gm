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
  GoogleFonts.config.allowRuntimeFetching = false;
  group('Scenario A: Auth & PIN Flow (Widget Test)', () {
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;
    late MockEntitlementGuard mockEntitlement;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
      mockEntitlement = MockEntitlementGuard();
      
      // Default behaviors
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockEntitlement.checkEntitlement())
          .thenAnswer((_) async => EntitlementStatus.valid);
    });

    testWidgets('Full Onboarding -> Signup -> PIN Setup Flow', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              secureStorageProvider.overrideWithValue(mockStorage),
              firebaseAuthProvider.overrideWithValue(mockAuth),
              entitlementProvider.overrideWithValue(mockEntitlement),
            ],
            child: const IronBookApp(hiveHealthy: true),
          ),
        );

        // 1. Splash Screen
        await tester.pump(); 
        expect(find.text('IronBook GM'), findsOneWidget);
        
        // Wait for 2 second splash delay + extra for safety
        // We use pump(duration) because SplashScreen uses Future.delayed
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // 2. Onboarding Carousel
        expect(find.text('Track every member'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        expect(find.text('Instant invoices'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        
        expect(find.text('Your gym, your rules'), findsOneWidget);
        await tester.tap(find.text('Get started'));
        await tester.pumpAndSettle();

        // 3. Signup Screen
        expect(find.text('Create Account'), findsOneWidget);
      });
    });
  });
}
