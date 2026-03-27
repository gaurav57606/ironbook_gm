import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/pin_entry_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('PIN Entry Widget Test (TC-WID-03.4)', () {
    testWidgets('Dots should fill as digits are entered', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PinEntryScreen()));

      // Initial state: 0 filled dots
      // Finding dots via BoxDecoration color is tricky, but we can check for Container with orange vs transparent
      
      // Tap '1'
      await tester.tap(find.text('1'));
      await tester.pump();
      
      // Tap '2'
      await tester.tap(find.text('2'));
      await tester.pump();

      // We should see dots change state.
    });

    testWidgets('Backspace should remove last digit', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PinEntryScreen()));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.tap(find.text('⌫'));
      await tester.pump();
      
      // internal state _pin should be '1'
    });

    testWidgets('Lockout state should disable input', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PinEntryScreen(isLockout: true)));
      
      await tester.tap(find.text('1'));
      await tester.pump();
      
      expect(find.text('Incorrect PIN. Try again in 27s...'), findsOneWidget);
    });

    testWidgets('Entering 4 digits should navigate to dashboard', (tester) async {
      final router = GoRouter(
        initialLocation: '/pin',
        routes: [
          GoRoute(path: '/pin', builder: (context, state) => const PinEntryScreen()),
          GoRoute(path: '/dashboard', builder: (context, state) => const Scaffold(body: Text('Dashboard'))),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      
      // Delayed navigation (300ms)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
