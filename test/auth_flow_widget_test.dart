import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/security/pin_service.dart';
import 'package:ironbook_gm/security/entitlement_guard.dart';
import '../integration_test/mocks/mock_firebase.dart';
import '../integration_test/mocks/mock_firestore.dart';
import '../integration_test/mocks/mock_secure_storage.dart';
import '../integration_test/mocks/mock_entitlement.dart';
import '../integration_test/mocks/mock_services.dart';
import 'package:ironbook_gm/providers/base_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setupHive('auth_flow');
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Scenario A: Auth & PIN Flow (Widget Test)', () {
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;
    late MockEntitlementGuard mockEntitlement;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
      mockEntitlement = MockEntitlementGuard();
      mockFirestore = MockFirebaseFirestore();
      
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockQuerySnapshot = MockQuerySnapshot();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.orderBy(any())).thenReturn(mockCollection);
      when(() => mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([]);
      
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
              appSecureStorageProvider.overrideWithValue(mockStorage),
              firebaseAuthProvider.overrideWithValue(mockAuth),
              firestoreProvider.overrideWithValue(mockFirestore),
              entitlementProvider.overrideWithValue(mockEntitlement),
              hmacServiceProvider.overrideWithValue(MockHmacService()),
            ],
            child: const IronBookApp(
              hiveHealthy: true,
              useGoogleFonts: false,
            ),
          ),
        );

        expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('IronBook')), findsOneWidget);
        
        // Wait for 2 second splash delay + extra for safety
        // We use pump(duration) because SplashScreen uses Future.delayed
        await tester.pump(const Duration(seconds: 3));
        // await tester.pumpAndSettle();

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
        await tester.pump(const Duration(milliseconds: 500));

        await tester.pump(const Duration(milliseconds: 500));
        // 3. Signup Screen
        expect(find.text('Create Account'), findsOneWidget);
      });
    });
  });
}
