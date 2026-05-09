import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/features/auth/onboarding/onboarding_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/signup_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/login_screen.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:ironbook_gm/shared/widgets/app_button.dart';
import 'package:ironbook_gm/shared/widgets/app_text_field.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setupHive('auth_flow');
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
       // Register fallbacks
      try {
        registerFallbackValue(BootstrapPhase.tier1Ready);
      } catch (_) {}

      await TestHelper.pumpIronBookWidget(
        tester,
        const IronBookApp(
          storageHealthy: true,
          useGoogleFonts: false,
        ),
        overrides: [
          appSecureStorageProvider.overrideWithValue(mockStorage),
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(mockFirestore),
          entitlementProvider.overrideWithValue(mockEntitlement),
          hmacServiceProvider.overrideWith((ref) => FakeHmacService()),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
          authProvider.overrideWith((ref) => FakeAuth(
            isFirstLaunch: true, 
            isAuthenticated: false,
            isPinSetup: false,
          )),
          tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
        ],
      );

      // 1. Initially should be on Login Screen (new deterministic order: Auth > Onboarding)
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      // 2. Navigate to Signup
      final signupLink = find.textContaining('Create an account').first;
      expect(signupLink, findsOneWidget);
      await tester.ensureVisible(signupLink);
      await tester.tap(signupLink);
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // 3. Fill signup form to authenticate
      await tester.enterText(find.byType(TextFormField).at(0), 'IronBook Gym');
      await tester.enterText(find.byType(TextFormField).at(1), 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(2), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), '9876543210');
      await tester.enterText(find.byType(TextFormField).at(4), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(5), 'Password123');
      await tester.pumpAndSettle();

      // Tap Create Account button
      await tester.tap(find.widgetWithText(AppButton, 'Create Account'));
      await tester.pumpAndSettle();

      // 4. Now authenticated + first launch -> Should be on Onboarding
      expect(find.textContaining('Track every member'), findsOneWidget);
      await tester.tap(find.textContaining('Next').first);
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Instant invoices'), findsOneWidget);
      await tester.tap(find.textContaining('Next').first);
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Your gym, your rules'), findsOneWidget);
      await tester.tap(find.textContaining('Get started').first);
      await tester.pumpAndSettle();

      // 5. Finally on PIN Setup Screen
      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(find.text('Create your PIN'), findsOneWidget);
    });
  });
}


