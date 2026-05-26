import '../test_helper.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MemberSnapshot(
      memberId: '0',
      name: '',
      joinDate: DateTime.now(),
      totalPaid: 0,
    ));
  });

  group('Dashboard Quick Stats Tests (TC-WID-02)', () {
    testWidgets('Should display correct counts for active, expiring, and expired members', (tester) async {
      final now = DateTime(2025, 1, 1, 12, 0, 0); // FakeClock default is 2025-01-01
      final members = [
        MemberSnapshot(
          memberId: '1',
          name: 'Active User',
          joinDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.add(const Duration(days: 20)), // Active
          totalPaid: 1000,
        ),
        MemberSnapshot(
          memberId: '2',
          name: 'Expiring User',
          joinDate: now.subtract(const Duration(days: 25)),
          expiryDate: now.add(const Duration(days: 5)), // Expiring (<= 7 days)
          totalPaid: 1000,
        ),
        MemberSnapshot(
          memberId: '3',
          name: 'Expired User',
          joinDate: now.subtract(const Duration(days: 40)),
          expiryDate: now.subtract(const Duration(days: 1)), // Expired
          totalPaid: 1000,
        ),
      ];

      final mockNotifier = FakeMemberNotifier(members);
      final mockPaymentNotifier = FakePaymentNotifier([]);

      await TestHelper.pumpIronBookWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(unlocked: true)),
          membersProvider.overrideWith((ref) => mockNotifier),
          paymentsProvider.overrideWith((ref) => mockPaymentNotifier),
          unsyncedCountProvider.overrideWith((ref) => Stream.value(0)),
          tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
        ],
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify stats are visible
      expect(find.textContaining('TOTAL MEMBERS'), findsOneWidget);
      expect(find.textContaining('ACTIVE'), findsOneWidget);
      
      // Let's verify stats reflect the members counts
      expect(find.text('3'), findsOneWidget); // Total members count
      expect(find.text('1'), findsAtLeast(2)); // Active, Expiring, Expired each have 1

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Should show "Welcome to IronBook" when list is empty', (tester) async {
      final mockNotifier = FakeMemberNotifier([]);
      final mockPaymentNotifier = FakePaymentNotifier([]);

      await TestHelper.pumpIronBookWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(unlocked: true)),
          membersProvider.overrideWith((ref) => mockNotifier),
          paymentsProvider.overrideWith((ref) => mockPaymentNotifier),
          unsyncedCountProvider.overrideWith((ref) => Stream.value(0)),
          tier2StatusProvider.overrideWith((ref) => Tier2Status.ready),
        ],
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.textContaining('Welcome to IronBook'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
