import '../test_helper.dart';

class MockMemberNotifier extends StateNotifier<List<MemberSnapshot>> with Mock implements MemberNotifier {
  MockMemberNotifier(super.state);
}

void main() {
  group('Member List Widget Tests (TC-WID-01)', () {
    testWidgets('Should display member list with correct status pills', (tester) async {
      final members = [
        MemberSnapshot(
          memberId: 'm1',
          name: 'Alice Active',
          phone: '1234567890',
          joinDate: DateTime(2026, 1, 1),
          planId: 'p1',
          planName: 'Gold',
          expiryDate: DateTime(2026, 4, 1),
          totalPaid: 1000,
        ),
      ];

      final mockNotifier = MockMemberNotifier(members);

      await TestHelper.pumpIronBookWidget(
        tester,
        const MembersListScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth()),
          membersProvider.overrideWith((ref) => mockNotifier),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Alice Active'), findsOneWidget);
      expect(find.byType(MemberRow), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });
  });
}


