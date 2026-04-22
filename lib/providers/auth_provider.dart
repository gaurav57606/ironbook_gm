import 'dart:async'; // Added for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/sync/recovery_service.dart';
import 'package:ironbook_gm/data/local/drift/outbox_repository.dart';
import '../data/local/models/owner_profile_model.dart';
import '../data/local/models/app_settings_model.dart';
import '../data/sync_worker.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/repositories/event_repository.dart';
import '../security/pin_service.dart';
import '../security/entitlement_guard.dart';
import '../constants/event_payload_keys.dart';
import '../core/utils/clock.dart';
import 'base_providers.dart';

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
    this.isLoading = true,
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
  final FlutterSecureStorage _storage;
  final PinService _pinService;
  final fb.FirebaseAuth? _firebaseAuth;
  final SyncWorker _syncWorker;
  final IEventRepository _eventRepo;
  final Ref _ref;
  final String _deviceId = 'device-${const Uuid().v4().substring(0, 8)}';

  StreamSubscription<fb.User?>? _authSubscription;

  AuthNotifier(this._storage, this._pinService, this._firebaseAuth,
      this._eventRepo, this._syncWorker, this._ref)
      : super(AuthState(settings: AppSettings())) {
    _init();
    _syncWorker.startPeriodicSync(const Duration(seconds: 30));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final pinHash = await _storage.read(key: 'pin_hash');
    final onboardingDone = await _storage.read(key: 'onboarding_done');

    // Load Hive state
    late OwnerProfile? owner;
    late AppSettings settings;
    try {
      final ownerBox = Hive.box<OwnerProfile>('owner');
      owner = ownerBox.isEmpty ? null : ownerBox.values.first;

      final settingsBox = Hive.box<AppSettings>('settings');
      settings = settingsBox.isEmpty
          ? AppSettings()
          : settingsBox.get('app_settings') ?? AppSettings();
    } catch (e) {
      debugPrint('AuthNotifier Hive Init Error: $e');
      owner = null;
      settings = AppSettings();
    }

    // Finalize loading state if Firebase wasn't ready or was skipped
    if (mounted && state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  void onFirebaseReady(fb.FirebaseAuth auth) {
    debugPrint('AuthNotifier: Firebase Ready. Starting listener.');
    _authSubscription?.cancel();
    _authSubscription = auth.authStateChanges().listen((user) {
      if (mounted) {
        state = state.copyWith(
          user: user,
          isAuthenticated: user != null,
          isLoading: false,
        );
      }
    });

    // Trigger recovery if signed in
    if (auth.currentUser != null) {
      _ref.read(recoveryServiceProvider).recoverAll();
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: 'onboarding_done', value: 'true');
    state = state.copyWith(isFirstLaunch: false);
  }

  Future<bool> authenticate({String? pin}) async {
    final result = await _pinService.authenticate(pinFallback: pin);
    if (result == AuthResult.success) {
      if (mounted) {
        state = state.copyWith(unlocked: true);
      }
      return true;
    }
    return false;
  }

  // Aliases for backward compatibility where needed, though we should migrate all to authenticate()
  Future<bool> verifyPin(String pin) => authenticate(pin: pin);
  Future<bool> unlockWithBiometrics() => authenticate();
  Future<bool> loginWithBiometrics() => authenticate();

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('AuthNotifier Login Error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AuthNotifier Login Error: $e');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _performFullLogout();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _performFullLogout() async {
    try {
      await _firebaseAuth!.signOut();
      await _storage.deleteAll();

      // CRITICAL: Wipe all local Hive data for isolation
      final boxes = [
        'snapshots',
        'events',
        'payments',
        'plans',
        'owner',
        'settings',
        'invoice_sequences'
      ];
      for (final name in boxes) {
        try {
          await Hive.box(name).clear();
        } catch (e) {
          debugPrint('Error clearing box $name: $e');
        }
      }

      // NEW: Clear Drift Outbox
      try {
        await _ref.read(outboxRepositoryProvider).clearAll();
      } catch (e) {
        debugPrint('Error clearing Drift Outbox: $e');
      }

      state = AuthState(
        isAuthenticated: false,
        unlocked: false,
        isPinSetup: false,
        isFirstLaunch: true,
        isLoading: false,
        settings: AppSettings(),
      );
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  Future<bool> signUp(String email, String password,
      {String? gymName, String? ownerName, String? phone}) async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
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
        // Data Pipeline: Queue for Sync FIRST (Enforce Outbox-First Rule)
        final event = DomainEvent(
          entityId: 'owner',
          eventType: EventType.ownerProfileCreated,
          deviceId: _deviceId,
          deviceTimestamp: DateTime.now(),
          payload: {
            EventPayloadKeys.name: gymName, 
            'ownerName': ownerName ?? '',
            EventPayloadKeys.phone: phone ?? '',
          },
        );
        
        // This will throw if the Drift Outbox write fails, preventing local Hive corruption
        await _eventRepo.persist(event);

        // Persist Cache Locally
        await Hive.box<OwnerProfile>('owner').add(owner);
        _ref.read(syncWorkerProvider).performSync();

        state = state.copyWith(owner: owner);
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('AuthNotifier SignUp Error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AuthNotifier SignUp Error: $e');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateOwner(OwnerProfile updated) async {
    final box = Hive.box<OwnerProfile>('owner');
    if (box.isEmpty) {
      await box.add(updated);
    } else {
      await box.putAt(0, updated);
    }
    state = state.copyWith(owner: updated);
  }

  Future<void> logout() => _performFullLogout();
  Future<void> logOut() => _performFullLogout();

  Future<void> setPin(String pin) async {
    await _pinService.setPin(pin);
    state = state.copyWith(isPinSetup: true, unlocked: true);
  }

  Future<void> setBiometricOptIn(bool enabled) async {
    final settings = state.settings.copyWith(
      biometricEnabled: enabled,
      useBiometrics: enabled,
    );

    await Hive.box<AppSettings>('settings').put('app_settings', settings);
    state = state.copyWith(settings: settings);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await Hive.box<AppSettings>('settings').put('app_settings', settings);
    state = state.copyWith(settings: settings);
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth!.sendPasswordResetEmail(email: email);
  }
}

final entitlementProvider = Provider<EntitlementGuard?>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final clock = ref.watch(clockProvider);

  // On Web/Audit mode, we might not have Firebase initialized
  if (auth == null || firestore == null) return null;

  return EntitlementGuard(storage, auth, firestore, clock);
});

final entitlementStatusProvider = FutureProvider<EntitlementStatus>((ref) async {
  final guard = ref.watch(entitlementProvider);
  if (guard == null) return EntitlementStatus.expired;
  return await guard.checkEntitlement();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final pinService = ref.watch(pinServiceProvider);
  final repo = ref.watch(eventRepositoryProvider);
  final syncWorker = ref.watch(syncWorkerProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthNotifier(storage, pinService, firebaseAuth, repo, syncWorker, ref);
});
