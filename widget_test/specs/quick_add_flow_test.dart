import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/providers/member_provider.dart';
import 'package:ironbook_gm/providers/plan_provider.dart';
import 'package:ironbook_gm/providers/payment_provider.dart';
import 'package:ironbook_gm/data/sync_worker.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';
import 'package:ironbook_gm/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';

class MockEventRepo extends Mock implements IEventRepository {}
class MockSyncWorker extends Mock implements SyncWorker {}
class MockBox<T> extends Mock implements Box<T> {}
class MockHmacService extends Mock implements HmacService {}
class FakeDomainEvent extends Fake implements DomainEvent {}

void main() {
  late MockEventRepo mockRepo;
  late MockSyncWorker mockSyncWorker;
  late MockHmacService mockHmac;
  late List<Plan> testPlans;

  setUpAll(() {
    registerFallbackValue(FakeDomainEvent());
  });

  setUp(() {
    mockRepo = MockEventRepo();
    mockSyncWorker = MockSyncWorker();
    mockHmac = MockHmacService();

    when(() => mockSyncWorker.performSync()).thenAnswer((_) async {});
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());
    when(() => mockRepo.persist(any())).thenAnswer((_) async {});
    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');

    testPlans = [
      Plan(
        id: 'p1',
        name: 'Monthly',
        durationMonths: 1,
        components: [PlanComponent(id: 'c1', name: 'Base', price: 1000)],
      ),
      Plan(
        id: 'p2',
        name: 'Quarterly',
        durationMonths: 3,
        components: [PlanComponent(id: 'c2', name: 'Base', price: 2500)],
      ),
    ];
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        syncWorkerProvider.overrideWithValue(mockSyncWorker),
        eventRepositoryProvider.overrideWithValue(mockRepo),
        clockProvider.overrideWithValue(FrozenClock(DateTime(2024, 1, 1))),
        // Mock Notifiers
        planProvider.overrideWith((ref) {
          final box = MockBox<Plan>();
          when(() => box.values).thenReturn([]);
          final notifier = PlanNotifier(box, mockRepo, mockSyncWorker, 'dev');
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = testPlans;
          return notifier;
        }),
        membersProvider.overrideWith((ref) {
          final notifier = MemberNotifier(mockRepo, FrozenClock(DateTime(2024, 1, 1)), mockHmac as HmacService);
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = [];
          return notifier;
        }),
        paymentsProvider.overrideWith((ref) {
          final pBox = MockBox<Payment>();
          when(() => pBox.values).thenReturn([]);
          final sBox = MockBox<InvoiceSequence>();
          when(() => sBox.get(any())).thenReturn(null);
          final clock = FrozenClock(DateTime(2024, 1, 1));
          // ignore: invalid_use_of_visible_for_testing_member
          return PaymentNotifier(pBox, sBox, mockRepo, clock, mockHmac as HmacService)..debugState = [];
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Quick Add Member Flow Tests (TC-WID-04)', () {
    testWidgets('Should switch plans and update summary', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const QuickAddMemberScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MONTHLY SUMMARY'), findsOneWidget);
      expect(find.text('₹1000'), findsNWidgets(2));

      await tester.tap(find.text('Quarterly ₹2500'));
      await tester.pumpAndSettle();

      expect(find.text('QUARTERLY SUMMARY'), findsOneWidget);
      expect(find.text('₹2500'), findsNWidgets(2));
    });

    testWidgets('Should show validation error if name is empty', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const QuickAddMemberScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register Member & Generate Invoice'));
      await tester.pump();

      expect(find.text('Please enter name'), findsOneWidget);
    });
  });
}
