import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/members/presentation/screens/members_list_screen.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepo extends Mock implements IEventRepository {}
class MockHmacService extends Mock implements HmacService {}

void main() {
  late MockEventRepo mockRepo;
  late MockHmacService mockHmac;
  late List<MemberSnapshot> testMembers;

  setUp(() {
    mockRepo = MockEventRepo();
    mockHmac = MockHmacService();
    
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());
    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');

    testMembers = [
      MemberSnapshot(
        memberId: 'm1',
        name: 'John Doe',
        phone: '1234567890',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 2, 1), // Active
      ),
      MemberSnapshot(
        memberId: 'm2',
        name: 'Jane Smith',
        phone: '0987654321',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2023, 12, 1), // Expired
      ),
      MemberSnapshot(
        memberId: 'm3',
        name: 'Bob Wilson',
        phone: '5556667777',
        joinDate: DateTime(2024, 1, 1),
        expiryDate: DateTime(2024, 1, 5), // Expiring (within 7 days of 1-1)
      ),
    ];
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockRepo),
        clockProvider.overrideWithValue(FrozenClock(DateTime(2024, 1, 1))),
        membersProvider.overrideWith((ref) {
          final notifier = MemberNotifier(mockRepo, FrozenClock(DateTime(2024, 1, 1)), mockHmac as HmacService);
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = testMembers;
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Member List Search/Filter Tests (TC-WID-05)', () {
    testWidgets('Should filter by name', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const MembersListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'John');
      await tester.pump(); 

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsNothing);
      expect(find.text('Bob Wilson'), findsNothing);
    });

    testWidgets('Should filter by phone', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const MembersListScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '0987');
      await tester.pump();

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('John Doe'), findsNothing);
    });

    testWidgets('Should filter by status tabs', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const MembersListScreen()));
      await tester.pumpAndSettle();

      // Tap "Expired" tab (index 3)
      await tester.tap(find.text('Expired 1'));
      await tester.pump();

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('John Doe'), findsNothing);
      expect(find.text('Bob Wilson'), findsNothing);

      // Tap "Expiring" tab (index 2)
      await tester.tap(find.text('Expiring 1'));
      await tester.pump();

      expect(find.text('Bob Wilson'), findsOneWidget);
      expect(find.text('John Doe'), findsNothing);
    });
  });
}
