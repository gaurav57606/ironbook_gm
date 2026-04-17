import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/auth/presentation/screens/pin_entry_screen.dart';
import 'package:ironbook_gm/providers/auth_provider.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthNotifier extends StateNotifier<AuthState> with Mock implements AuthNotifier {
  MockAuthNotifier() : super(AuthState(settings: AppSettings(), isLoading: false, unlocked: false));
}

void main() {
  late MockAuthNotifier mockAuth;

  setUp(() {
    mockAuth = MockAuthNotifier();
    // Default stub to avoid MissingStubError in async calls
    when(() => mockAuth.verifyPin(any())).thenAnswer((_) async => false);
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => mockAuth),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        routes: {
          '/dashboard': (_) => const Scaffold(body: Text('Dashboard Page')),
        },
      ),
    );
  }

  group('PIN Entry Widget Tests (TC-WID-05)', () {
    testWidgets('Should verify PIN after 4 digits and navigate on success', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockAuth.verifyPin('1234')).thenAnswer((_) async => true);

      await tester.pumpWidget(wrap(const PinEntryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      
      await tester.pumpAndSettle();

      verify(() => mockAuth.verifyPin('1234')).called(1);
      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('Should show error message on incorrect PIN', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockAuth.verifyPin('0000')).thenAnswer((_) async => false);

      await tester.pumpWidget(wrap(const PinEntryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      
      await tester.pumpAndSettle();

      verify(() => mockAuth.verifyPin('0000')).called(1);
      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
    });

    testWidgets('Should handle backspace', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Stub specifically for the expected pin after backspace
      when(() => mockAuth.verifyPin('1345')).thenAnswer((_) async => true);

      await tester.pumpWidget(wrap(const PinEntryScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      
      final backspace = find.text('⌫');
      await tester.ensureVisible(backspace);
      await tester.tap(backspace);
      
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.tap(find.text('5'));
      
      await tester.pumpAndSettle();
      verify(() => mockAuth.verifyPin('1345')).called(1);
    });
  });
}
