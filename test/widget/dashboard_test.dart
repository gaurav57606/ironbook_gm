import '../test_helper.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';

class MockSyncWorker extends Mock implements SyncWorker {}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MemberSnapshot(
      memberId: '0',
      name: '',
      joinDate: DateTime.now(),
      totalPaid: 0,
    ));
    registerFallbackValue(Duration.zero);
  });

  group('Dashboard Widget Tests (TC-WID-03.2)', () {
    testWidgets('Should display correct statistics based on member state', (tester) async {
      final m1 = MemberSnapshot(
        memberId: '1',
        name: 'Test Member',
        phone: '1234567890',
        joinDate: DateTime.now(),
        planId: 'p1',
        planName: 'Monthly',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        totalPaid: 1000,
      );

      // Use Fake notifiers from test_helper.dart
      final mockNotifier = FakeMemberNotifier([m1]);
      final mockPaymentNotifier = FakePaymentNotifier([]);
      final mockSync = MockSyncWorker();

      when(() => mockSync.startPeriodicSync(any())).thenReturn(null);

      await TestHelper.pumpIronBookWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(unlocked: true)),
          membersProvider.overrideWith((ref) => mockNotifier),
          paymentsProvider.overrideWith((ref) => mockPaymentNotifier),
          unsyncedCountProvider.overrideWith((ref) => Stream.value(0)),
          tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
          syncWorkerProvider.overrideWithValue(mockSync),
        ],
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeast(1));

      // Verify stats are visible
      expect(find.textContaining('TOTAL MEMBERS'), findsOneWidget);
      expect(find.textContaining('ACTIVE'), findsOneWidget);
      
      // Stats should reflect 1 active member
      // There might be multiple '1's (Total, Active)
      expect(find.text('1'), findsAtLeast(2)); 
    });
  });
}
