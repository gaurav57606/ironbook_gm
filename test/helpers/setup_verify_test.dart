import 'package:flutter_test/flutter_test.dart';
import 'hive_test_helper.dart';
import 'provider_test_helper.dart';
import 'widget_test_helper.dart';
import 'package:flutter/material.dart';

void main() {
  test('HiveTestHelper setup/teardown works', () async {
    await HiveTestHelper.setup();
    final box = await HiveTestHelper.openBox('test_box');
    await box.put('key', 'value');
    expect(box.get('key'), 'value');
    await HiveTestHelper.tearDown();
  });

  test('ProviderTestHelper works', () {
    final container = makeContainer();
    expect(container, isNotNull);
  });

  testWidgets('WidgetTestHelper works', (tester) async {
    await tester.pumpWidget(wrapWithProviders(const Text('Hello')));
    expect(find.text('Hello'), findsOneWidget);
  });
}
