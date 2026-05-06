import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setupHive('smoke');
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Autonomous Smoke Test - Visit All Screens', () {
    late MockFirebaseAuth mockAuth;
    late MockFlutterSecureStorage mockStorage;
    late MockFirebaseFirestore mockFirestore;
    late MockEntitlementGuard mockEntitlement;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFlutterSecureStorage();
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
      mockEntitlement = MockEntitlementGuard();

      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(null));
      when(() => mockStorage.read(key: 'onboarding_done'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async {});
      when(() => mockEntitlement.checkEntitlement())
          .thenAnswer((_) async => EntitlementStatus.valid);
    });

    testWidgets('Smoke Test: Splash -> Onboarding -> Signup',
        (WidgetTester tester) async {
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
          hmacServiceProvider.overrideWithValue(MockHmacService()),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier1Ready),
        ],
      );

      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('IronBook')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      // 2. Onboarding
      expect(find.text('Track every member'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Signup
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Create Account'), findsOneWidget);

      // Navigate to Login from Signup
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      // 4. Login Screen
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Smoke Test: Dashboard (Authenticated)',
        (WidgetTester tester) async {
      final mockUser = MockUser();
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('test-user-id');
      final mockPinService = MockPinService();
      final mockSyncWorker = MockSyncWorker();
      when(() => mockPinService.verifyPin(any())).thenAnswer((_) async => true);
      when(() => mockPinService.getLockoutUntil()).thenAnswer((_) async => null);
      when(() => mockPinService.getFailCount()).thenAnswer((_) async => 0);
      when(() => mockSyncWorker.performSync()).thenAnswer((_) async {});
      when(() => mockSyncWorker.startPeriodicSync(any())).thenReturn(null);

      // Pretend onboarding and PIN are done
      when(() => mockStorage.read(key: 'onboarding_done'))
          .thenAnswer((_) async => 'true');
      when(() => mockStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'hashed-pin');

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
          pinServiceProvider.overrideWithValue(mockPinService),
          syncWorkerProvider.overrideWithValue(mockSyncWorker),
          hmacServiceProvider.overrideWithValue(MockHmacService()),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
        ],
      );

      await tester.pump(const Duration(seconds: 3)); // Bypass splash
      await tester.pumpAndSettle(); // Should go to PIN ENTRY because it's not "unlocked" yet

      expect(find.text('Enter your PIN'), findsOneWidget);

      // Enter the PIN
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('1'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // 5. Dashboard
      await tester.pumpAndSettle();
      expect(find.text('IRONBOOK GM'), findsOneWidget);
    });
  });
}


