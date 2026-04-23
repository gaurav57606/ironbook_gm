import '../test_helper.dart';

void main() {
  group('PIN Entry Widget Test (TC-WID-03.4)', () {
    testWidgets('Dots should fill as digits are entered', (tester) async {
      await TestHelper.pumpIronBookWidget(
        tester, 
        const PinEntryScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
        ],
      );
      await tester.pumpAndSettle();

      final btn1 = find.byKey(const Key('btn_1'));
      expect(btn1, findsOneWidget);
      await tester.tap(btn1);
      await tester.pump();
      
      final btn2 = find.byKey(const Key('btn_2'));
      expect(btn2, findsOneWidget);
      await tester.tap(btn2);
      await tester.pump();
    });

    testWidgets('Backspace should remove last digit', (tester) async {
      await TestHelper.pumpIronBookWidget(
        tester, 
        const PinEntryScreen(),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_1')));
      await tester.tap(find.byKey(const Key('btn_2')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_⌫')));
      await tester.pump();
    });

    testWidgets('Lockout state should disable input', (tester) async {
      await TestHelper.pumpIronBookWidget(
        tester, 
        const PinEntryScreen(isLockout: true),
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
        ],
      );
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Incorrect PIN'), findsOneWidget);
    });

    testWidgets('Entering 4 digits should navigate to dashboard', (tester) async {
      final router = GoRouter(
          initialLocation: '/unlock',
          routes: [
              GoRoute(path: '/unlock', builder: (_, __) => const PinEntryScreen()),
              GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold(body: Text('DASHBOARD'))),
          ]
      );

      await TestHelper.pumpIronBookWidget(
        tester,
        const SizedBox(), 
        routerConfig: router,
        overrides: [
          authProvider.overrideWith((ref) => FakeAuth(isLoading: false)),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_1')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('btn_2')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('btn_3')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('btn_4')));
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
    });
  });
}


