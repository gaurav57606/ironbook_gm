import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/providers/base_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/security/pin_service.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import '../mocks/mock_firebase.dart';
import '../mocks/mock_services.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/data/local/hive_init.dart';
import 'package:ironbook_gm/providers/bootstrap_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    
    tempDir = await Directory.systemTemp.createTemp('ironbook_offline_');
    await Hive.initFlutter(tempDir.path);
    await HiveInit.openWithCorruptionGuard();

    when(() => mockPin.verifyPin(any())).thenAnswer((_) async => true);
    when(() => mockAuth.currentUser).thenReturn(MockUser());
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('TC-INT-02: Offline Operation & Sync (Persistence -> Event Queue -> Sync Push)', (WidgetTester tester) async {
    // 1. Launch Offline
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(null),
          pinServiceProvider.overrideWithValue(mockPin),
          syncWorkerProvider.overrideWithValue(mockSync),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
        ],
        child: const IronBookApp(hiveHealthy: true),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Perform Action (Add Member)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Offline User');
    await tester.enterText(find.byType(TextField).at(1), '1234567890');
    await tester.tap(find.text('Create Member'));
    await tester.pumpAndSettle();

    // 3. Verify Local Persistence (Even if sync fails/is slow)
    expect(find.text('Offline User'), findsOneWidget);

    // 4. Verify Event exists in Hive (via Repository)
    final container = ProviderScope.containerOf(tester.element(find.byType(IronBookApp)));
    final repo = container.read(eventRepositoryProvider);
    final unsynced = await repo.getAllUnsynced();
    expect(unsynced, isNotEmpty);
    expect(unsynced.any((e) => e.payload['name'] == 'Offline User'), true);

    // 5. Trigger Sync (Simulate 'Online' callback)
    when(() => mockSync.performSync()).thenAnswer((_) async => {});
    await mockSync.performSync();
    
    verify(() => mockSync.performSync()).called(1);
  });
}
