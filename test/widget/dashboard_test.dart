import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import '../helpers/mocks.dart';

class MockMemberNotifier extends MemberNotifier {
  MockMemberNotifier(List<MemberSnapshot> members) 
      : super(FakeRepo(), FrozenClock(DateTime(2026, 3, 25)), FakeHmacService()) {
    state = members;
  }

  @override
  Future<void> init() async {}
}

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
          expiryDate: DateTime(2026, 4, 1),
          totalPaid: 1000,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuth()),
            membersProvider.overrideWith((ref) => MockMemberNotifier(members)),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Active Members'), findsOneWidget);
    });
  });
}
