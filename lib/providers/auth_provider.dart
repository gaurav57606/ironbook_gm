import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/local/models/owner_profile_model.dart';
import '../data/local/models/app_settings_model.dart';
import '../security/pin_service.dart';

class AuthState {
  final bool isLoading;
  final bool isFirstLaunch;
  final fb.User? user;
  final bool isAuthenticated;
  final OwnerProfile? owner;
  final AppSettings settings;
  final bool isPinSetup;
  final bool unlocked;

  AuthState({
    this.isLoading = false,
    this.isFirstLaunch = true,
    this.user,
    this.isAuthenticated = false,
    this.owner,
    required this.settings,
    this.isPinSetup = false,
    this.unlocked = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isFirstLaunch,
    fb.User? user,
    bool? isAuthenticated,
    OwnerProfile? owner,
    AppSettings? settings,
    bool? isPinSetup,
    bool? unlocked,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      owner: owner ?? this.owner,
      settings: settings ?? this.settings,
      isPinSetup: isPinSetup ?? this.isPinSetup,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final _pinService = PinService();

  AuthNotifier() : super(AuthState(settings: AppSettings())) {
    _init();
  }

  Future<void> _init() async {
    // Check PIN setup in secure storage
    final pinHash = await _storage.read(key: 'pin_hash');
    final onboardingDone = await _storage.read(key: 'onboarding_done');
    
    fb.FirebaseAuth.instance.authStateChanges().listen((user) {
      state = state.copyWith(
        user: user,
        isAuthenticated: user != null,
        isFirstLaunch: onboardingDone != 'true',
        isPinSetup: pinHash != null,
        isLoading: false,
      );
    });
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: 'onboarding_done', value: 'true');
    state = state.copyWith(isFirstLaunch: false);
  }

  Future<bool> unlockWithPin(String pin) async {
    final success = await _pinService.verifyPin(pin);
    if (success) {
      state = state.copyWith(unlocked: true);
    }
    return success;
  }

  Future<bool> verifyPin(String pin) => unlockWithPin(pin);

  Future<bool> unlockWithBiometrics() async {
    final success = await _pinService.authenticateWithBiometric();
    if (success) {
      state = state.copyWith(unlocked: true);
    }
    return success;
  }

  Future<bool> loginWithBiometrics() => unlockWithBiometrics();
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signUp(String email, String password, {String? gymName, String? ownerName, String? phone}) async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null && gymName != null) {
        final owner = OwnerProfile(
          gymName: gymName,
          ownerName: ownerName ?? '',
          phone: phone ?? '',
          address: '',
        );
        state = state.copyWith(owner: owner);
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    await fb.FirebaseAuth.instance.signOut();
    state = state.copyWith(unlocked: false);
  }

  Future<void> logOut() => logout();

  Future<void> setPin(String pin) async {
    await _pinService.setPin(pin);
    state = state.copyWith(isPinSetup: true);
  }

  Future<void> setBiometricOptIn(bool enabled) async {
    final settings = state.settings;
    // Update settings in state (In real app, save to Hive)
    state = state.copyWith(
      settings: AppSettings(
        gstRate: settings.gstRate,
        expiryReminderDays: settings.expiryReminderDays,
        whatsappReminders: settings.whatsappReminders,
        biometricEnabled: enabled,
        useBiometrics: enabled,
        businessType: settings.businessType,
      ),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
