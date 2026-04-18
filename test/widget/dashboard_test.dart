import '../test_helper.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';
import 'package:ironbook_gm/data/models/member_snapshot.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockMemberNotifier extends Mock implements MemberNotifier {}

void main() {
  group('Dashboard Widget Tests (TC-WID-03.2)', () {
    testWidgets('Should display correct statistics based on member state', (tester) async {
      final members = [
        MemberSnapshot(
          memberId: 'm1',
          name: 'Active User',
          phone: '1234567890',
          joinDate: DateTime(2026, 1, 1),
          planId: 'p1',
          planName: 'Gold',
          expiryDate: DateTime(2026, 7, 1),
          totalPaid: 1000,
        ),
      ];

      final mockNotifier = MockMemberNotifier();
      when(() => mockNotifier.state).thenReturn(members);

      await TestHelper.pumpIronBookWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth()),
          membersProvider.overrideWith((ref) => mockNotifier),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Active Members'), findsOneWidget);
      // Stats should reflect 1 active member
      expect(find.text('1'), findsWidgets); 
    });
  });
}
