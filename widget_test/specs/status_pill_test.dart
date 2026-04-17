import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/widgets/status_pill.dart';
import 'package:ironbook_gm/core/constants/colors.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme(useGoogleFonts: false),
      home: Scaffold(body: child),
    );
  }

  group('StatusPill Widget Tests (TC-WID-01)', () {
    testWidgets('Active status should be green', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusPill(status: MemberStatus.active)));
      
      final text = tester.widget<Text>(find.text('Active'));
      expect(text.style?.color, AppColors.green);
      
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.green.withValues(alpha: 0.15));
    });

    testWidgets('Expiring status should be amber', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusPill(status: MemberStatus.expiring)));
      
      final text = tester.widget<Text>(find.text('Expiring'));
      expect(text.style?.color, AppColors.amber);
    });

    testWidgets('Expired status should be red', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusPill(status: MemberStatus.expired)));
      
      final text = tester.widget<Text>(find.text('Expired'));
      expect(text.style?.color, AppColors.red);
    });

    testWidgets('Pending status should be text3 color', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusPill(status: MemberStatus.pending)));
      
      final text = tester.widget<Text>(find.text('Pending'));
      expect(text.style?.color, AppColors.text3);
    });

    testWidgets('Custom label should override default', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusPill(status: MemberStatus.active, label: 'Current')));
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });
  });
}
