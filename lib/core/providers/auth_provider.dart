import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:hive/hive.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ironbook_gm/core/sync/recovery_service.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/owner_repository.dart';
import 'package:ironbook_gm/core/data/repositories/settings_repository.dart';
import 'package:ironbook_gm/core/data/repositories/preferences_repository.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';
import 'package:ironbook_gm/core/security/pin_service.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';
import 'package:ironbook_gm/core/constants/event_payload_keys.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
import '../services/logger_service.dart';
import 'base_providers.dart';

class AuthState {
  final bool isLoading;
  final bool isFirstLaunch;
  final fb.User? user;
  final bool isAuthenticated;
  final bool isPinSetup;
  final bool unlocked;
  final int authAttempts;
  final bool isRecovering;

  AuthState({
    this.isLoading = true,
    this.isFirstLaunch = true,
    this.user,
    this.isAuthenticated = false,
    this.isPinSetup = false,
    this.unlocked = false,
    this.authAttempts = 0,
    this.isRecovering = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isFirstLaunch,
    fb.User? user,
    bool? isAuthenticated,
    bool? isPinSetup,
    bool? unlocked,
    int? authAttempts,
    bool? isRecovering,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPinSetup: isPinSetup ?? this.isPinSetup,
      unlocked: unlocked ?? this.unlocked,
      authAttempts: authAttempts ?? this.authAttempts,
      isRecovering: isRecovering ?? this.isRecovering,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final PinService _pinService;
  final fb.FirebaseAuth? _firebaseAuth;
  final IEventRepository _eventRepo;
  final IOwnerRepository _ownerRepo;
  final ISettingsRepository _settingsRepo;
  final HmacService _hmacService;
  final IPreferencesRepository _preferencesRepo;
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
    this._hmacService,
    this._preferencesRepo,
    this._ref,
  ) : super(AuthState()) {
    init();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    final logger = _ref.read(loggerProvider);

    // ── CRITICAL FIX ──────────────────────────────────────────────────────────
    // FlutterSecureStorage.read() on Android calls into the Android Keystore
    // which can deadlock indefinitely if the keystore is not yet initialized
    // (fresh install, post-wipe, emulator without hardware keystore).
    //
    // The router redirect watches authState.isLoading. If isLoading stays true
    // forever (because init() never completes), the splash screen is permanent.
    //
    // FIX: Read only from PreferencesRepository (Drift/SQLite) and
    // SharedPreferences here. All FlutterSecureStorage reads are deferred to
    // onFirebaseReady() where they are actually needed and Firebase is alive.
    // ──────────────────────────────────────────────────────────────────────────

    // _deviceId is only needed for event signing — defer to onFirebaseReady
    // where HmacService is fully initialized with auth + firestore context.
    // Default value 'device-unknown' is safe for the init phase.

    // 1. Check onboarding status from Drift (safe, no Keystore)
    String? onboardingDone = await _preferencesRepo.getString('onboarding_done');

    // 2. Check PIN from SharedPreferences flag (no Keystore).
    //    We store a lightweight boolean flag in prefs to avoid the Keystore
    //    during startup. The actual pin_hash/salt are only read during
    //    authentication where the user is already on the PIN screen.
    final prefs = _ref.read(sharedPreferencesProvider);
    final bool isPinSetup = prefs.getBool('pin_configured') ?? false;

    // 3. Legacy migration: if old SecureStorage flag exists, read it ONCE
    //    in a fire-and-forget manner after a small delay so it never blocks init.
    unawaited(Future.delayed(const Duration(seconds: 3), () async {
      try {
        if (!prefs.containsKey('pin_configured')) {
          // Safe to call now — app is already rendered, keystore is warmed up
          final pinHash = await _storage.read(key: 'pin_hash').timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
          final hasPinInSecureStorage = pinHash != null;
          await prefs.setBool('pin_configured', hasPinInSecureStorage);
          if (hasPinInSecureStorage && mounted) {
            state = state.copyWith(isPinSetup: true);
            logger.info('Migrated PIN flag from SecureStorage to SharedPreferences.', category: 'AUTH');
          }
        }
      } catch (e) {
        logger.warn('PIN migration check failed (non-fatal): $e', category: 'AUTH');
      }
    }));

    // 4. Load owner + settings from Drift (safe, no Keystore)
    try {
      await _ownerRepo.getOwner();
      await _settingsRepo.getSettings();
    } catch (e) {
      logger.error('Failed to load owner/settings: $e', category: 'AUTH');
    }

    final hasOwner = await _ownerRepo.getOwner() != null;

    // 5. Recovery: If prefs cleared but DB has owner, restore flag
    if (onboardingDone != 'true' && hasOwner) {
      await _preferencesRepo.setString('onboarding_done', 'true');
      onboardingDone = 'true';
    }

    if (mounted) {
      logger.info(
        'AuthNotifier init complete. PIN: $isPinSetup, FirstLaunch: ${onboardingDone != 'true' && !hasOwner}',
        category: 'AUTH',
      );
      // ✅ This sets isLoading=false, which unblocks the router redirect
      state = state.copyWith(
        isPinSetup: isPinSetup,
        isFirstLaunch: onboardingDone != 'true' && !hasOwner,
        isLoading: false,
      );
    }
  }

  Future<void> onFirebaseReady(fb.FirebaseAuth auth) async {
    // Safe to read SecureStorage now — Firebase is initialized, keystore is warmed up
    try {
      _deviceId = await _hmacService.getInstallationId().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 'device-timeout-fallback',
      );
    } catch (e) {
      _ref.read(loggerProvider).warn('getInstallationId failed in onFirebaseReady: $e', category: 'AUTH');
    }

    _authSubscription?.cancel();

    if (auth.currentUser != null) {
      _syncAndRecover();
    }

    _authSubscription = auth.authStateChanges().listen((user) async {
      final logger = _ref.read(loggerProvider);
      logger.info('Firebase auth state change: ${user?.email ?? 'signed-out'}', category: 'AUTH');

      final wasNull = state.user == null;

      if (mounted) {
        state = state.copyWith(
          user: user,
          isAuthenticated: user != null,
          isFirstLaunch: user != null ? false : state.isFirstLaunch,
          isLoading: false,
        );

        if (user != null && wasNull) {
          _syncAndRecover();
        }
      }
    });
  }

  Future<void> _syncAndRecover() async {
    final logger = _ref.read(loggerProvider);
    if (mounted) state = state.copyWith(isRecovering: true);

    try {
      logger.info('Starting identity sync and recovery...', category: 'AUTH');

      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove('last_recovery_at');
      logger.info('Recovery checkpoint cleared.', category: 'AUTH');

      await _hmacService.syncCurrentKeyToCloud().timeout(
        const Duration(seconds: 10),
        onTimeout: () => logger.warn('Key sync timed out, continuing in degraded mode.', category: 'AUTH'),
      );

      await _ref.read(recoveryServiceProvider).recoverAll().timeout(
        const Duration(minutes: 5),
        onTimeout: () => logger.error('Full recovery timed out after 5 minutes.', category: 'AUTH'),
      );

      _ref.read(syncCoordinatorProvider).triggerSync();

      final hasOwner = await _ownerRepo.getOwner().timeout(const Duration(seconds: 2));
      if (hasOwner != null) {
        await _preferencesRepo.setString('onboarding_done', 'true');
        if (mounted) state = state.copyWith(isFirstLaunch: false);
      }
    } catch (e) {
      logger.error('Sync/Recovery failed: $e', category: 'AUTH', error: e);
    } finally {
      if (mounted) state = state.copyWith(isRecovering: false);
    }
  }

  Future<void> completeOnboarding() async {
    await _preferencesRepo.setString('onboarding_done', 'true');
    state = state.copyWith(isFirstLaunch: false);
  }

  Future<bool> authenticate({String? pin}) async {
    // FlutterSecureStorage is safe here — user is on PIN screen, app is fully rendered
    final result = await _pinService.authenticate(pinFallback: pin);
    if (result == AuthResult.success) {
      _ref.read(loggerProvider).info('PIN Authentication successful', category: 'AUTH');
      if (mounted) {
        state = state.copyWith(unlocked: true, authAttempts: 0);
      }
      return true;
    }
    _ref.read(loggerProvider).warn('PIN Authentication failed', category: 'AUTH');
    state = state.copyWith(authAttempts: state.authAttempts + 1);
    return false;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      if (_firebaseAuth == null) {
        throw Exception('Firebase not initialized');
      }

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(authAttempts: 0);
      await _preferencesRepo.setString('onboarding_done', 'true');
      _ref.invalidate(entitlementStatusProvider);
      return true;
    } catch (e) {
      state = state.copyWith(authAttempts: state.authAttempts + 1);
      return false;
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setPin(String pin) async {
    await _pinService.setPin(pin);
    // Mirror to SharedPreferences so init() can read it without Keystore
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool('pin_configured', true);
    state = state.copyWith(isPinSetup: true, unlocked: true);
    _ref.invalidate(entitlementStatusProvider);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _performFullLogout();
    state = state.copyWith(isLoading: false);
  }

  void lock() {
    if (state.unlocked && state.isPinSetup) {
      _ref.read(loggerProvider).info('Application locked.', category: 'AUTH');
      state = state.copyWith(unlocked: false);
    }
  }

  Future<void> _performFullLogout() async {
    _ref.read(loggerProvider).info('Starting full logout and data purge', category: 'AUTH');
    try {
      if (_firebaseAuth != null) {
        await _firebaseAuth.signOut();
      }

      final installationId = await _storage.read(key: 'installation_id');
      await _storage.deleteAll();
      if (installationId != null) {
        await _storage.write(key: 'installation_id', value: installationId);
        _ref.read(loggerProvider).info('Preserved installation_id during logout.', category: 'AUTH');
      }

      // Clear PIN flag from SharedPreferences too
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove('pin_configured');

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
      );
    } catch (e) {
      _ref.read(loggerProvider).error('Logout Error: $e', category: 'AUTH', error: e);
    }
  }

  Future<bool> signUp(String email, String password,
      {String? gymName, String? ownerName, String? phone}) async {
    state = state.copyWith(isLoading: true);
    await _storage.delete(key: 'pin_hash');
    await _storage.delete(key: 'pin_salt');
    try {
      if (_firebaseAuth == null) {
        throw Exception('Firebase not initialized');
      }
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
        await _preferencesRepo.setString('onboarding_done', 'true');

        _ref.read(syncWorkerProvider).performSync();

        state = state.copyWith(
          isAuthenticated: true,
          isFirstLaunch: false,
          isPinSetup: false,
          unlocked: false,
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

  Future<void> logout() => _performFullLogout();

  Future<void> setBiometricOptIn(bool enabled) async {
    final settings = await _settingsRepo.getSettings();
    await _settingsRepo.updateSettings(settings.copyWith(useBiometrics: enabled));
  }

  Future<void> sendPasswordReset(String email) async {
    if (_firebaseAuth == null) throw Exception('Firebase not initialized');
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
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final hmac = ref.watch(hmacServiceProvider);
  final preferences = ref.watch(preferencesRepositoryProvider);

  return AuthNotifier(
    storage,
    pinService,
    firebaseAuth,
    eventRepo,
    ownerRepo,
    settingsRepo,
    hmac,
    preferences,
    ref,
  );
});
