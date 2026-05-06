import 'test_helper.dart';

void main() {
  group('Scenario C: Subscription/Paywall Flow', () {
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;

    setUp(() async {
      await TestHelper.setupHive('paywall');
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
      
      // Mock authenticated user
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.idTokenChanges()).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.userChanges()).thenAnswer((_) => Stream.value(mockUser));
      
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
    });

    tearDown(() async {
      await TestHelper.cleanHive();
    });

    testWidgets('Redirect to paywall when entitlement is expired', (WidgetTester tester) async {
       // Register fallbacks
      try {
        registerFallbackValue(EntitlementStatus.valid);
      } catch (_) {}

      await TestHelper.pumpIronBookWidget(
        tester,
        const IronBookApp(
          hiveHealthy: true,
          useGoogleFonts: false,
        ),
        overrides: [
          appSecureStorageProvider.overrideWithValue(mockStorage),
          firebaseAuthProvider.overrideWithValue(mockAuth),
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
          entitlementStatusProvider.overrideWith((ref) => EntitlementStatus.expired),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Skip splash if visible
      if (find.textContaining('IronBook').evaluate().isNotEmpty) {
           await tester.pump(const Duration(seconds: 4));
           await tester.pump();
      }

      // Redirect logic should trigger and land on Paywall
      expect(find.text('Paywall'), findsOneWidget);
    });

    testWidgets('Allow access when entitlement is valid', (WidgetTester tester) async {
      await TestHelper.pumpIronBookWidget(
        tester,
        const IronBookApp(
          hiveHealthy: true,
          useGoogleFonts: false,
        ),
        overrides: [
          appSecureStorageProvider.overrideWithValue(mockStorage),
          firebaseAuthProvider.overrideWithValue(mockAuth),
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
          entitlementStatusProvider.overrideWith((ref) => EntitlementStatus.valid),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Skip splash if visible
      if (find.textContaining('IronBook').evaluate().isNotEmpty) {
           await tester.pump(const Duration(seconds: 4));
           await tester.pump();
      }

      // Should NOT be on paywall
      expect(find.text('Paywall'), findsNothing);
    });
  });
}


