import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:hive/hive.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/core/sync/recovery_service.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/owner_repository.dart';
import 'package:ironbook_gm/core/data/repositories/settings_repository.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
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
  final int authAttempts;

  AuthState({
    this.isLoading = true,
    this.isFirstLaunch = true,
    this.user,
    this.isAuthenticated = false,
    this.owner,
    required this.settings,
    this.isPinSetup = false,
    this.unlocked = false,
    this.authAttempts = 0,
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
    int? authAttempts,
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
      authAttempts: authAttempts ?? this.authAttempts,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final PinService _pinService;
  final fb.FirebaseAuth _firebaseAuth;
  final SyncWorker _syncWorker;
  final IEventRepository _eventRepo;
  final IOwnerRepository _ownerRepo;
  final ISettingsRepository _settingsRepo;
  final HmacService _hmacService;
  final Ref _ref;
  String _deviceId = 'device-unknown';

  StreamSubscription<fb.User?>? _authSubscription;

  AuthNotifier(
    this._storage,
    this._pinService,
    this._firebaseAuth,
    this._eventRepo,
    this._ownerRepo,
    this._settingsRepo,
    this._syncWorker,
    this._hmacService,
    this._ref,
  ) : super(AuthState(settings: AppSettings())) {
    init();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    _syncWorker.startPeriodicSync(const Duration(seconds: 30));
    final pinHash = await _storage.read(key: 'pin_hash');
    final pinSalt = await _storage.read(key: 'pin_salt');
    final onboardingDone = await _storage.read(key: 'onboarding_done');
    _deviceId = await _hmacService.getInstallationId();

    bool isPinSetup = pinHash != null && pinSalt != null;
    if (pinHash != null && pinSalt == null) {
      await _storage.delete(key: 'pin_hash');
      isPinSetup = false;
    }

    final owner = await _ownerRepo.getOwner();
    final settings = await _settingsRepo.getSettings();

    if (mounted) {
      state = state.copyWith(
        isPinSetup: isPinSetup,
        isFirstLaunch: onboardingDone != 'true',
        owner: owner,
        settings: settings,
        isLoading: false,
      );
    }
  }

  void onFirebaseReady(fb.FirebaseAuth auth) {
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
        state = state.copyWith(unlocked: true, authAttempts: 0);
      }
      return true;
    }
    state = state.copyWith(authAttempts: state.authAttempts + 1);
    return false;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      if (kDebugMode && _firebaseAuth.currentUser == null) {
         // Debug/Test flow - should be overridden in tests via MockFirebaseAuth
      }
      
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(authAttempts: 0);
      return true;
    } catch (e) {
      state = state.copyWith(authAttempts: state.authAttempts + 1);
      return false;
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _performFullLogout();
    state = state.copyWith(isLoading: false);
  }


  Future<void> _performFullLogout() async {
    try {
      await _firebaseAuth.signOut();
      await _storage.deleteAll();

      // OPTIMIZED: Parallel Hive clearing + Batched Drift clearing
      final boxes = ['members', 'payments', 'plans', 'settings', 'events', 'snapshots'];
      await Future.wait(boxes.map((name) async {
        try {
          if (Hive.isBoxOpen(name)) {
            await Hive.box(name).clear();
          } else {
            final box = await Hive.openBox(name);
            await box.clear();
          }
        } catch (e) {
          debugPrint('Error clearing box $name: $e');
        }
      }));

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
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (gymName != null) {
        final owner = OwnerProfile(
          gymName: gymName,
          ownerName: ownerName ?? '',
          phone: phone ?? '',
          address: '',
        );

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
        
        await _eventRepo.persist(event);
        await _ownerRepo.upsertOwner(owner);
        
        _ref.read(syncWorkerProvider).performSync();

        state = state.copyWith(
          owner: owner,
          isAuthenticated: true,
          authAttempts: 0,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(authAttempts: state.authAttempts + 1);
      return false;
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateOwner(OwnerProfile updated) async {
    await _ownerRepo.upsertOwner(updated);
    state = state.copyWith(owner: updated);
  }

  Future<void> logout() => _performFullLogout();

  Future<void> setPin(String pin) async {
    await _pinService.setPin(pin);
    state = state.copyWith(isPinSetup: true, unlocked: true);
  }

  Future<void> setBiometricOptIn(bool enabled) async {
    final settings = state.settings.copyWith(
      biometricEnabled: enabled,
      useBiometrics: enabled,
    );

    await _settingsRepo.updateSettings(settings);
    state = state.copyWith(settings: settings);
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsRepo.updateSettings(settings);
    state = state.copyWith(settings: settings);
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}



final entitlementProvider = Provider<EntitlementGuard>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final clock = ref.watch(clockProvider);

  return EntitlementGuard(storage, auth, firestore, clock);
});

final entitlementStatusProvider = FutureProvider<EntitlementStatus>((ref) async {
  final guard = ref.watch(entitlementProvider);
  return await guard.checkEntitlement();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final pinService = ref.watch(pinServiceProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final ownerRepo = ref.watch(ownerRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final syncWorker = ref.watch(syncWorkerProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final hmac = ref.watch(hmacServiceProvider);
  
  return AuthNotifier(
    storage, 
    pinService, 
    firebaseAuth, 
    eventRepo, 
    ownerRepo, 
    settingsRepo, 
    syncWorker, 
    hmac, 
    ref
  );
});
