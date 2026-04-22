import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/providers/base_providers.dart';
import 'package:ironbook_gm/security/pin_service.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/data/local/hive_init.dart';
import 'package:ironbook_gm/providers/bootstrap_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks/mock_firebase.dart';
import '../mocks/mock_services.dart';

void registerAllAdapters() {
  HiveInit.registerAdapters();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockPinService mockPin;
  late MockSyncWorker mockSync;
  late Directory tempDir;

  setUp(() async {
    mockAuth = MockFirebaseAuth();
    mockPin = MockPinService();
    mockSync = MockSyncWorker();
    
    // Set up a unique temp directory for Hive
    tempDir = await Directory.systemTemp.createTemp('ironbook_lifecycle_');
    await Hive.initFlutter(tempDir.path);
    await HiveInit.openWithCorruptionGuard();

    // Mock successful pin verification
    when(() => mockPin.verifyPin(any())).thenAnswer((_) async => true);
    when(() => mockAuth.currentUser).thenReturn(MockUser());
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('TC-INT-01: Full Member Lifecycle (Add -> Renew -> Attendance -> Delete)', (WidgetTester tester) async {
    // 1. App Launch with Overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(null), // Mock firestore too
          pinServiceProvider.overrideWithValue(mockPin),
          syncWorkerProvider.overrideWithValue(mockSync),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
        ],
        child: const IronBookApp(hiveHealthy: true),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Dashboard - Tap "Add" (FAB or Nav item)
    // The FAB is likely unique enough. Let's find it.
    final addFab = find.byIcon(Icons.add);
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();

    // 3. Quick Add Screen - Fill Data
    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextField).at(1), '9876543210');
    
    // Select a plan (assuming at least one default or we add one to Hive in setUp)
    // For now, let's just tap the first plan if visible
    // Actually, let's seed a plan first in setUp to be safe.
    
    // Tap "Save"
    await tester.tap(find.text('Create Member'));
    await tester.pumpAndSettle();

    // 4. Verify in Member List
    expect(find.text('John Doe'), findsOneWidget);

    // 5. Navigate to Details
    await tester.tap(find.text('John Doe'));
    await tester.pumpAndSettle();

    // 6. Record Attendance (Check In)
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();
    // Verify toast or state change if possible (here we just ensure no crash)

    // 7. Renew Membership
    await tester.tap(find.text('Renew'));
    await tester.pumpAndSettle();
    // (Assuming simple renewal for now)

    // 8. Delete Member
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete')); // In Dialog
    await tester.pumpAndSettle();

    // 9. Verify Removal
    expect(find.text('John Doe'), findsNothing);
  });
}
