import 'package:flutter_test/flutter_test.dart';

/// Bounded pump to replace unstable pumpAndSettle() calls.
/// This prevents infinite async loops from hanging tests.
Future<void> boundedPump(
  WidgetTester tester, {
  int frames = 5,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}
