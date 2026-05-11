import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/login_screen.dart';
import 'package:ironbook_gm/core/router/app_router.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'infrastructure/test_database.dart';
import 'mocks/mock_auth.dart';
import 'infrastructure/test_harness.dart';
import 'infrastructure/test_app.dart';
import 'infrastructure/test_bindings.dart';

void main() {
  TestBootstrap.init();

  group('Infrastructure Canary Test', () {
    late TestHarness harness;

    setUp(() async {
      harness = TestHarness();
      await harness.setup();
      harness.overrides.add(authProvider.overrideWith((ref) => FakeAuthNotifier(isFirstLaunch: false)));
      addTearDown(() => TestDatabaseFactory.dispose());
    });

    testWidgets('Should render LoginScreen with deterministic infrastructure', (WidgetTester tester) async {
      final container = harness.container;
      final router = container.read(routerProvider(true));

      await tester.pumpWidget(
        createTestRouterApp(
          routerConfig: router,
          overrides: harness.overrides,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
