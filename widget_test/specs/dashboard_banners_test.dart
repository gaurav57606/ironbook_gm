import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/dashboard/dashboard_screen.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
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

  group('Dashboard Quick Stats Tests (TC-WID-02)', () {
    testWidgets('Should display correct counts for active, expiring, and expired members', (WidgetTester tester) async {
      final now = DateTime(2026, 1, 1);
      final members = [
        MemberSnapshot(
          memberId: '1',
          name: 'Active User',
          joinDate: now.subtract(const Duration(days: 10)),
          expiryDate: now.add(const Duration(days: 20)), // Active
        ),
        MemberSnapshot(
          memberId: '2',
          name: 'Expiring User',
          joinDate: now.subtract(const Duration(days: 25)),
          expiryDate: now.add(const Duration(days: 5)), // Expiring (<= 7 days)
        ),
        MemberSnapshot(
          memberId: '3',
          name: 'Expired User',
          joinDate: now.subtract(const Duration(days: 40)),
          expiryDate: now.subtract(const Duration(days: 1)), // Expired
        ),
      ];

      await tester.pumpWidget(wrap(const DashboardScreen(), members));
      await tester.pump(); 

      expect(find.widgetWithText(Container, 'ACTIVE'), findsOneWidget);
      expect(find.widgetWithText(Container, 'EXPIRING'), findsOneWidget);
      expect(find.widgetWithText(Container, 'EXPIRED'), findsOneWidget);
      
      expect(find.text('1'), findsNWidgets(3)); 
    });

    testWidgets('Should show "No members yet" when list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DashboardScreen(), []));
      await tester.pump();

      expect(find.text('No members yet.'), findsOneWidget);
    });
  });
}
