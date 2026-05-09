import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';

class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}
class MockUser extends Mock implements fb.User {}
class MockAuthNotifier extends Mock implements AuthNotifier {}

MockFirebaseAuth createMockFirebaseAuth() {
  final auth = MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(null);
  when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());
  when(() => auth.idTokenChanges()).thenAnswer((_) => const Stream.empty());
  when(() => auth.userChanges()).thenAnswer((_) => const Stream.empty());
  return auth;
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier({
    bool isAuthenticated = false,
    bool isFirstLaunch = true,
    bool isPinSetup = false,
    bool unlocked = false,
    bool isLoading = false,
  }) : super(AuthState(
          isAuthenticated: isAuthenticated,
          isFirstLaunch: isFirstLaunch,
          isPinSetup: isPinSetup,
          unlocked: unlocked,
          isLoading: isLoading,
        ));

  @override
  Future<void> init() async {}
  
  @override
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isAuthenticated: true, unlocked: true);
    return true;
  }

  @override
  Future<bool> signUp(String email, String password, {String? gymName, String? ownerName, String? phone}) async {
    state = state.copyWith(isAuthenticated: true, unlocked: true);
    return true;
  }

  @override
  Future<void> signOut() async {
    state = state.copyWith(isAuthenticated: false, unlocked: false);
  }

  @override
  Future<void> completeOnboarding() async {
    state = state.copyWith(isFirstLaunch: false);
  }

  @override
  Future<bool> verifyPin(String pin) async => true;

  @override
  Future<bool> authenticate({String? pin}) async {
    state = state.copyWith(unlocked: true);
    return true;
  }

  @override
  void onFirebaseReady(dynamic auth) {}

  @override
  void lock() {
    state = state.copyWith(unlocked: false);
  }

  @override
  Future<void> logout() async {
    state = state.copyWith(isAuthenticated: false, unlocked: false);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> setBiometricOptIn(bool enabled) async {}

  @override
  Future<void> setPin(String pin) async {
    state = state.copyWith(isPinSetup: true);
  }
}
