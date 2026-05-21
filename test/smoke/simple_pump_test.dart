import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_harness.dart';
import '../helpers/mock_factory.dart';
import 'package:ironbook_gm/features/auth/splash/splash_screen.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';

void main() {
  setUpAll(() {
    MockFactory.registerFallbacks();
  });

  testWidgets('Simple Pump Test', (WidgetTester tester) async {
    await TestHarness.pumpTestApp(
      tester,
      overrides: [
        tier2StatusProvider.overrideWith((ref) => Tier2Status.pending),
      ],
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
