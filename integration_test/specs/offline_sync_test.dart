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

void registerAllAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(DomainEventAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MemberSnapshotAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PaymentAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlanAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(PlanComponentAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(OwnerProfileAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AppSettingsAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(JoinDateChangeAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(PlanComponentSnapshotAdapter());
  if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(InvoiceSequenceAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(ProductAdapter());
  if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SaleAdapter());
  if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(SaleItemAdapter());
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
    registerAllAdapters();

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
          pinServiceProvider.overrideWithValue(mockPin),
          syncWorkerProvider.overrideWithValue(mockSync),
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
