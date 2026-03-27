import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/members/presentation/screens/quick_add_member_screen.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../helpers/hive_test_helper.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/core/widgets/app_button.dart';

class MockEventRepo extends Mock implements IEventRepository {}
class FakeDomainEvent extends Fake implements DomainEvent {}

void main() {
  late MockEventRepo mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeDomainEvent());
  });

  setUp(() async {
    mockRepo = MockEventRepo();
    
    // Set a realistic viewport size for testing
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final view = binding.renderViews.first.configuration.logicalConstraints.biggest;
    binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => binding.setSurfaceSize(view));

    await HiveTestHelper.setup();
    
    // Explicitly register again to be safe
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlanAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlanComponentAdapter());
    
    final plansBox = await Hive.openBox<Plan>('plans');
    final settingsBox = await Hive.openBox<AppSettings>('settings');
    await Hive.openBox<DomainEvent>('events');
    await Hive.openBox<MemberSnapshot>('snapshots');

    await plansBox.put('plan-monthly', Plan(
      id: 'plan-monthly',
      name: 'Monthly',
      durationMonths: 1,
      components: [
        PlanComponent(id: 'c1', name: 'Base', price: 1000),
      ],
    ));
    
    await settingsBox.put('settings', AppSettings(gstRate: 18));
  });

  tearDown(() async {
    await HiveTestHelper.tearDown();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockRepo),
        clockProvider.overrideWithValue(FrozenClock(DateTime(2024, 3, 25))),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/quick-add',
          routes: [
            GoRoute(
              path: '/quick-add',
              builder: (context, state) => const QuickAddMemberScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const Scaffold(body: Text('Dashboard')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('QuickAddMemberScreen should show error if name is empty', (tester) async {
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final button = find.byType(AppButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Please enter name'), findsOneWidget);
  });

  testWidgets('QuickAddMemberScreen should call addMember on success', (tester) async {
    when(() => mockRepo.persist(any())).thenAnswer((_) async {});
    when(() => mockRepo.watch()).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'John Test');
    await tester.enterText(find.byType(TextField).at(1), '9876543210');
    
    final button = find.byType(AppButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    verify(() => mockRepo.persist(any())).called(greaterThan(0));
    
    // Verify it navigated away (e.g. back to dashboard or popped)
    // Since it's initialLocation /quick-add and it pops, it might go to empty or / if configured.
  });
}
