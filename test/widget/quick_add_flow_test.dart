import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/plan_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/plan_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' hide Plan, Member, Payment;
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;
import 'package:ironbook_gm/core/services/logger_service.dart';

import 'package:ironbook_gm/core/services/membership_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';

class MockEventRepo extends Mock implements IEventRepository {}
class MockSyncWorker extends Mock implements SyncWorker {}
class MockBox<T> extends Mock implements Box<T> {}
class MockHmacService extends Mock implements HmacService {}
class MockMemberRepo extends Mock implements IMemberRepository {}
class MockPlanRepo extends Mock implements IPlanRepository {}
class MockPaymentRepo extends Mock implements IPaymentRepository {}
class MockPreferencesRepo extends Mock implements IPreferencesRepository {}
class MockSequenceRepo extends Mock implements ISequenceRepository {}
class MockMembershipService extends Mock implements MembershipService {}
class MockSyncCoordinator extends Mock implements SyncCoordinator {}
class MockOutboxDatabase extends Mock implements OutboxDatabase {}
class MockLoggerService extends Mock implements LoggerService {}
class FakeDomainEvent extends Fake implements DomainEvent {}

void main() {
  late MockEventRepo mockRepo;
  late MockSyncWorker mockSyncWorker;
  late MockSyncCoordinator mockCoordinator;
  late MockMembershipService mockMembership;
  late MockHmacService mockHmac;
  late MockMemberRepo mockMemberRepo;
  late MockPlanRepo mockPlanRepo;
  late MockPaymentRepo mockPaymentRepo;
  late MockPreferencesRepo mockPreferencesRepo;
  late MockSequenceRepo mockSequenceRepo;
  late List<Plan> testPlans;
  late List<db.Plan> testDbPlans;

  setUpAll(() {
    registerFallbackValue(FakeDomainEvent());
  });

  setUp(() {
    mockRepo = MockEventRepo();
    mockSyncWorker = MockSyncWorker();
    mockCoordinator = MockSyncCoordinator();
    mockMembership = MockMembershipService();
    mockHmac = MockHmacService();
    mockMemberRepo = MockMemberRepo();
    mockPlanRepo = MockPlanRepo();
    mockPaymentRepo = MockPaymentRepo();
    mockPreferencesRepo = MockPreferencesRepo();
    mockSequenceRepo = MockSequenceRepo();

    when(() => mockSyncWorker.performSync()).thenAnswer((_) async {});
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());
    when(() => mockRepo.persist(any())).thenAnswer((_) async {});
    when(() => mockRepo.getEventsSince(any())).thenAnswer((_) async => []);
    when(() => mockHmac.getInstallationId()).thenAnswer((_) async => 'test-device');
    when(() => mockCoordinator.triggerSync()).thenReturn(null);
    when(() => mockMemberRepo.getAllMembers()).thenAnswer((_) async => []);
    when(() => mockPaymentRepo.getAllPayments()).thenAnswer((_) async => []);
    when(() => mockPreferencesRepo.getInt(any())).thenAnswer((_) async => null);
    when(() => mockPreferencesRepo.getString(any())).thenAnswer((_) async => null);

    testPlans = [
      Plan(
        id: 'p1',
        name: 'Monthly',
        durationMonths: 1,
        price: 1000,
        components: [PlanComponent(id: 'c1', name: 'Base', price: 1000)],
      ),
      Plan(
        id: 'p2',
        name: 'Quarterly',
        durationMonths: 3,
        price: 2500,
        components: [PlanComponent(id: 'c2', name: 'Base', price: 2500)],
      ),
    ];

    testDbPlans = [
      db.Plan(
        id: 'p1',
        name: 'Monthly',
        durationMonths: 1,
        price: 1000,
        active: true,
        hmacSignature: '',
        isSynced: false,
        componentsJson: '[{"id":"c1","name":"Base","price":1000.0}]',
      ),
      db.Plan(
        id: 'p2',
        name: 'Quarterly',
        durationMonths: 3,
        price: 2500,
        active: true,
        hmacSignature: '',
        isSynced: false,
        componentsJson: '[{"id":"c2","name":"Base","price":2500.0}]',
      ),
    ];
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        syncWorkerProvider.overrideWithValue(mockSyncWorker),
        eventRepositoryProvider.overrideWithValue(mockRepo),
        syncCoordinatorProvider.overrideWithValue(mockCoordinator),
        membershipServiceProvider.overrideWithValue(mockMembership),
        clockProvider.overrideWithValue(FrozenClock(DateTime(2024, 1, 1))),
        activePlansProvider.overrideWith((ref) => Stream.value(testDbPlans)),
        // Mock Notifiers
        planProvider.overrideWith((ref) {
          final notifier = PlanNotifier(MockOutboxDatabase(), mockRepo, mockPlanRepo, mockSyncWorker, mockHmac);
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = testPlans;
          return notifier;
        }),
        membersProvider.overrideWith((ref) {
          final notifier = MemberNotifier(
            MockOutboxDatabase(),
            mockRepo, 
            mockMemberRepo, 
            mockPlanRepo, 
            mockPreferencesRepo,
            FrozenClock(DateTime(2024, 1, 1)), 
            mockHmac,
            mockMembership,
            mockCoordinator,
            MockLoggerService(),
          );
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = [];
          return notifier;
        }),
        paymentsProvider.overrideWith((ref) {
          final clock = FrozenClock(DateTime(2024, 1, 1));
          final notifier = PaymentNotifier(
            MockOutboxDatabase(),
            mockSequenceRepo, 
            mockRepo, 
            mockPaymentRepo, 
            mockMemberRepo,
            clock, 
            mockHmac,
            mockMembership,
            mockCoordinator,
            MockLoggerService(),
          );
          // ignore: invalid_use_of_visible_for_testing_member
          notifier.debugState = [];
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Quick Add Member Flow Tests (TC-WID-04)', () {
    testWidgets('Should switch plans and update summary', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(wrap(const QuickAddMemberScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ORDER SUMMARY'), findsOneWidget);
      expect(find.text('MONTHLY'), findsOneWidget);
      expect(find.text('₹1000'), findsNWidgets(2));

      // Open Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Tap on Quarterly
      await tester.tap(find.text('Quarterly').last);
      await tester.pumpAndSettle();

      expect(find.text('ORDER SUMMARY'), findsOneWidget);
      expect(find.text('QUARTERLY'), findsOneWidget);
      expect(find.text('₹2500'), findsNWidgets(2));
    });

    testWidgets('Should show validation error if name is empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(wrap(const QuickAddMemberScreen()));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('register_button'), skipOffstage: false);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Please enter name'), findsOneWidget);
    });
  });
}


