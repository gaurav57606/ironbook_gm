import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/home/presentation/screens/dashboard_screen.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncWorker extends Mock implements SyncWorker {}
class MockEventRepo extends Mock implements IEventRepository {}
class MockHmacService extends Mock implements HmacService {}

void main() {
  late MockSyncWorker mockSyncWorker;
  late MockEventRepo mockRepo;
  late MockHmacService mockHmac;

  setUp(() {
    mockSyncWorker = MockSyncWorker();
    mockRepo = MockEventRepo();
    mockHmac = MockHmacService();
    
    when(() => mockSyncWorker.performSync()).thenAnswer((_) async {});
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());
    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');
  });

  Widget wrap(Widget child, List<MemberSnapshot> members) {
    return ProviderScope(
      overrides: [
        syncWorkerProvider.overrideWithValue(mockSyncWorker),
        eventRepositoryProvider.overrideWithValue(mockRepo),
        clockProvider.overrideWithValue(FrozenClock(DateTime(2026, 1, 1))),
        membersProvider.overrideWith((ref) {
          final notifier = MemberNotifier(mockRepo, FrozenClock(DateTime(2026, 1, 1)), mockHmac as HmacService);
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = members;
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Dashboard Member List Tests (TC-WID-03)', () {
    testWidgets('Should display member names and correct status descriptions', (WidgetTester tester) async {
      final now = DateTime(2026, 1, 1);
      final members = [
        MemberSnapshot(
          memberId: 'm1',
          name: 'John Doe',
          joinDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.add(const Duration(days: 20)),
        ),
        MemberSnapshot(
          memberId: 'm2',
          name: 'Jane Smith',
          joinDate: now.subtract(const Duration(days: 25)),
          expiryDate: now.add(const Duration(days: 3)),
        ),
      ];

      await tester.pumpWidget(wrap(const DashboardScreen(), members));
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Expiring in 3 days'), findsOneWidget);
    });

    testWidgets('Should show "Expired" text with correct days for expired members', (WidgetTester tester) async {
       final now = DateTime(2026, 1, 1);
       final members = [
        MemberSnapshot(
          memberId: 'm3',
          name: 'Old Member',
          joinDate: now.subtract(const Duration(days: 40)),
          expiryDate: now.subtract(const Duration(days: 5)),
        ),
      ];

      await tester.pumpWidget(wrap(const DashboardScreen(), members));
      await tester.pump();

      expect(find.text('Old Member'), findsOneWidget);
      expect(find.text('Expired 5 days ago'), findsOneWidget);
    });
  });
}


