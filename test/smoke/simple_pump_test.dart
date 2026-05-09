import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_harness.dart';
import '../helpers/mock_factory.dart';
import 'package:ironbook_gm/features/auth/splash/splash_screen.dart';

void main() {
  setUpAll(() {
    MockFactory.registerFallbacks();
  });

  testWidgets('Simple Pump Test', (WidgetTester tester) async {
    await TestHarness.pumpTestApp(tester);
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
