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

  group('Scenario C: Subscription/Paywall Flow', () {
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;
    late MockEntitlementGuard mockEntitlement;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
      mockEntitlement = MockEntitlementGuard();
      
      // Mock authenticated user
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
    });

    testWidgets('Redirect to paywall when entitlement is expired', (WidgetTester tester) async {
       when(() => mockEntitlement.checkEntitlement())
          .thenAnswer((_) async => EntitlementStatus.expired);

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

        // Should bypass splash
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Redirect logic should trigger and land on Paywall
        expect(find.text('Paywall'), findsOneWidget);
      });
    });

    testWidgets('Allow access when entitlement is valid', (WidgetTester tester) async {
       when(() => mockEntitlement.checkEntitlement())
          .thenAnswer((_) async => EntitlementStatus.valid);

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

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Should NOT be on paywall (assuming it goes to PIN Setup or Dashboard)
        expect(find.text('Paywall'), findsNothing);
      });
    });
  });
}
