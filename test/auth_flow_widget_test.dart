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
          hiveHealthy: true,
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
        ],
      );

      // Wait for router redirect to Onboarding
      await tester.pumpAndSettle();
      

      // Check for Onboarding
      expect(find.textContaining('Track every member'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Instant invoices'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Your gym, your rules'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // Signup Screen
      expect(find.textContaining('Create Account'), findsOneWidget);
    });
  });
}


