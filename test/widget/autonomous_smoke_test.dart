import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/data/repositories/owner_repository.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helper.dart';

class FakeOwnerNotifier extends OwnerNotifier {
  FakeOwnerNotifier(OwnerProfile? profile, IOwnerRepository repo) 
    : super(repo, FakeDriftEventRepository(), FakeHmacService()) {
    state = profile;
  }
}

void main() {
  setUpAll(() async {
    await TestHelper.setupHive('smoke');
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(Duration.zero);
  });

  group('Autonomous Smoke Test - Visit All Screens', () {
    late MockFlutterSecureStorage mockStorage;
    late MockSyncWorker mockSync;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockSync = MockSyncWorker();
      
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockSync.startPeriodicSync(any())).thenReturn(null);
      when(() => mockSync.performSync()).thenAnswer((_) async {});
    });

    testWidgets('Smoke Test: Splash -> Onboarding -> Signup', (tester) async {
      final fakeAuth = FakeAuth(
        isAuthenticated: false,
        isFirstLaunch: true,
        isLoading: false,
      );

      await TestHelper.pumpIronBookWidget(
        tester,
        const IronBookApp(
          storageHealthy: true,
          useGoogleFonts: false,
        ),
        overrides: [
          appSecureStorageProvider.overrideWithValue(mockStorage),
          authProvider.overrideWith((ref) => fakeAuth),
          syncWorkerProvider.overrideWith((ref) => mockSync),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
        ],
      );

      // 1. Skip Splash
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // 2. Onboarding
      expect(find.textContaining('Track every member'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Instant invoices'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Your gym, your rules'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Signup
      expect(find.textContaining('Create Account'), findsWidgets);

      // Navigate to Login from Signup
      final loginLink = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Log in'));
      expect(loginLink, findsOneWidget);
      await tester.tap(loginLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 4. Login Screen
      expect(find.textContaining('Welcome Back'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Smoke Test: Dashboard (Authenticated)', (tester) async {
      final fakeAuth = FakeAuth(
        isAuthenticated: true,
        isFirstLaunch: false,
        isPinSetup: true,
        unlocked: true,
        isLoading: false,
      );

      final mockOwnerRepo = MockOwnerRepo();
      final profile = OwnerProfile(gymName: 'SMOKE TEST GYM', ownerName: 'Owner', phone: '123', address: '');
      
      when(() => mockOwnerRepo.getOwner()).thenAnswer((_) async => profile);

      await TestHelper.pumpIronBookWidget(
        tester,
        const IronBookApp(
          storageHealthy: true,
          useGoogleFonts: false,
        ),
        overrides: [
          appSecureStorageProvider.overrideWithValue(mockStorage),
          authProvider.overrideWith((ref) => fakeAuth),
          entitlementStatusProvider.overrideWith((ref) => Future.value(EntitlementStatus.valid)),
          ownerProvider.overrideWith((ref) => FakeOwnerNotifier(profile, mockOwnerRepo)),
          syncWorkerProvider.overrideWith((ref) => mockSync),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
        ],
      );

      await tester.pump(const Duration(seconds: 5)); // Bypass splash
      await tester.pump();

      // 5. Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.textContaining('SMOKE TEST GYM'), findsWidgets);
      debugPrint('[SMOKE] Dashboard verified');
      
      // Explicitly dispose tree
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      debugPrint('[SMOKE] Test finished');
    });
  });
}
