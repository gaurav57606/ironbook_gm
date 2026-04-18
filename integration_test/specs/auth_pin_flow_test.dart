import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/app.dart';
import 'package:ironbook_gm/providers/base_providers.dart';
import 'package:ironbook_gm/security/pin_service.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/data/local/hive_init.dart';
import 'package:ironbook_gm/providers/bootstrap_provider.dart';
import '../mocks/mock_firebase.dart';
import '../mocks/mock_services.dart';

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
  // We use the REAL PinService but mock the dependencies if needed
  // OR we use the MockPinService to verify navigation triggers correctly.
  // For true E2E, we use real Business Logic but mock the I/O.
  late MockPinService mockPin; 
  late MockSyncWorker mockSync;
  late Directory tempDir;

  setUp(() async {
    mockAuth = MockFirebaseAuth();
    mockPin = MockPinService();
    mockSync = MockSyncWorker();
    
    tempDir = await Directory.systemTemp.createTemp('ironbook_auth_');
    await Hive.initFlutter(tempDir.path);
    await HiveInit.openWithCorruptionGuard();

    when(() => mockAuth.currentUser).thenReturn(MockUser());
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('TC-INT-03: Auth & PIN Flow (Login -> PIN Prompt -> Dashboard Access)', (WidgetTester tester) async {
    // 1. Launch app with PIN required
    // Mocking the notifier state might be easier but this is an Integration test
    // So we want to see the UI behavior.
    
    // Stub PIN verification to fail then succeed
    when(() => mockPin.verifyPin("1111")).thenAnswer((_) async => false);
    when(() => mockPin.verifyPin("1234")).thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          pinServiceProvider.overrideWithValue(mockPin),
          syncWorkerProvider.overrideWithValue(mockSync),
          bootstrapStateProvider.overrideWith((ref) => BootstrapPhase.tier2Ready),
        ],
        child: const IronBookApp(hiveHealthy: true),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Expect PIN Entry Screen
    expect(find.text('Enter PIN'), findsOneWidget);

    // 3. Enter WRONG PIN (1111)
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('1'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    
    // Verify error state (vibration/text) - assuming 'Invalid PIN' message
    expect(find.text('Invalid PIN'), findsOneWidget);

    // 4. Enter CORRECT PIN (1234)
    await tester.tap(find.text('1')); await tester.pump();
    await tester.tap(find.text('2')); await tester.pump();
    await tester.tap(find.text('3')); await tester.pump();
    await tester.tap(find.text('4')); await tester.pump();
    await tester.pumpAndSettle();

    // 5. Verify Navigation to Dashboard
    expect(find.text('Good Morning'), findsOneWidget); // Assuming dashboard welcome
  });
}
