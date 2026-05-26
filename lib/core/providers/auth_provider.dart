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
import '../monitoring/monitoring_service.dart';
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

  // --- Public API ---

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
    if (mounted) {
      state = state.copyWith(authAttempts: state.authAttempts + 1);
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      if (_firebaseAuth == null) throw Exception('Firebase not initialized');
      
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      
      if (mounted) {
        state = state.copyWith(authAttempts: 0);
        await _preferencesRepo.setString('onboarding_done', 'true');
        _ref.invalidate(entitlementStatusProvider);
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(authAttempts: state.authAttempts + 1);
      }
      return false;
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() => _performFullLogout();

  Future<void> completeOnboarding() async {
    await _preferencesRepo.setString('onboarding_done', 'true');
    if (mounted) state = state.copyWith(isFirstLaunch: false);
  }

  Future<void> setPin(String pin) async {
    await _pinService.setPin(pin);
    // Mirror to SharedPreferences so init() can read it without Keystore
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool('pin_configured', true);
    if (mounted) {
      state = state.copyWith(isPinSetup: true, unlocked: true);
      _ref.invalidate(entitlementStatusProvider);
    }
  }

  /// Called when PIN is disabled from Security Settings.
  /// Clears the stored PIN and refreshes in-memory auth state.
  Future<void> clearPin() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool('pin_configured', false);
    await _storage.delete(key: 'pin_hash');
    await _storage.delete(key: 'pin_salt');
    if (mounted) {
      state = state.copyWith(isPinSetup: false);
    }
  }

  Future<void> setBiometricOptIn(bool enabled) async {
    final settings = await _settingsRepo.getSettings();
    await _settingsRepo.updateSettings(settings.copyWith(useBiometrics: enabled));
  }

  void lock() {
    if (state.unlocked && state.isPinSetup) {
      _ref.read(loggerProvider).info('Application locked.', category: 'AUTH');
      if (mounted) {
        state = state.copyWith(unlocked: false);
      }
    }
  }

  // --- Internal & Bootstrap ---

  Future<void> init() async {
    final logger = _ref.read(loggerProvider);
    logger.info('[BOOT] AuthNotifier: Starting initialization...', category: 'AUTH');

    try {
      // 1. Check onboarding status from Drift (safe, no Keystore)
      logger.info('[BOOT] AuthNotifier: Checking onboarding status...', category: 'AUTH');
      String? onboardingDone;
      try {
        onboardingDone = await _preferencesRepo.getString('onboarding_done').timeout(const Duration(seconds: 2));
      } catch (e) {
        logger.warn('[BOOT] AuthNotifier: Onboarding status check timed out/failed: $e', category: 'AUTH');
      }

      // 2. Check PIN from SharedPreferences flag (no Keystore).
      logger.info('[BOOT] AuthNotifier: Checking PIN status...', category: 'AUTH');
      final prefs = _ref.read(sharedPreferencesProvider);
      final bool isPinSetup = prefs.getBool('pin_configured') ?? false;

      // 3. Legacy migration: if old SecureStorage flag exists, read it ONCE
      //    after a delay so it never blocks init.
      unawaited(Future.delayed(const Duration(seconds: 3), () async {
        try {
          if (!prefs.containsKey('pin_configured')) {
            logger.info('[BOOT] AuthNotifier: Running delayed PIN migration check...', category: 'AUTH');
            final pinHash = await _storage.read(key: 'pin_hash').timeout(
              const Duration(seconds: 5),
              onTimeout: () => null,
            );
            final hasPinInSecureStorage = pinHash != null;
            await prefs.setBool('pin_configured', hasPinInSecureStorage);
            if (hasPinInSecureStorage && mounted) {
              state = state.copyWith(isPinSetup: true);
              logger.info('[BOOT] AuthNotifier: Migrated PIN flag from SecureStorage.', category: 'AUTH');
            }
          }
        } catch (e) {
          logger.warn('[BOOT] AuthNotifier: PIN migration check failed (non-fatal): $e', category: 'AUTH');
        }
      }));

      // 4. Load owner + settings from Drift (safe, no Keystore)
      logger.info('[BOOT] AuthNotifier: Loading owner/settings...', category: 'AUTH');
      try {
        await _ownerRepo.getOwner().timeout(const Duration(seconds: 2));
        await _settingsRepo.getSettings().timeout(const Duration(seconds: 2));
      } catch (e) {
        logger.error('[BOOT] AuthNotifier: Failed to load owner/settings: $e', category: 'AUTH');
      }

      final hasOwner = (await _ownerRepo.getOwner().timeout(const Duration(seconds: 1), onTimeout: () => null)) != null;

      if (onboardingDone != 'true' && hasOwner) {
        await _preferencesRepo.setString('onboarding_done', 'true').timeout(const Duration(seconds: 1));
        onboardingDone = 'true';
      }

      if (mounted) {
        final isFirstLaunch = onboardingDone != 'true' && !hasOwner;
        logger.info(
          '[BOOT] AuthNotifier: Init milestones reached. PIN: $isPinSetup, FirstLaunch: $isFirstLaunch',
          category: 'AUTH',
        );
        state = state.copyWith(
          isPinSetup: isPinSetup,
          isFirstLaunch: isFirstLaunch,
          isAuthenticated: hasOwner,
        );
      }
    } catch (e, stack) {
      logger.critical('[BOOT] AuthNotifier: Fatal error in init(): $e', category: 'AUTH', error: e, stackTrace: stack);
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
        logger.info('[BOOT] AuthNotifier: isLoading set to FALSE. UI unblocked.', category: 'AUTH');

        // If Firebase is already initialized (app resume, not first launch),
        // immediately wire up the auth listener. This handles the case where
        // Tier 2 already ran but init() hadn't started the auth subscription.
        try {
          if (_firebaseAuth != null) {
            final currentUser = _firebaseAuth.currentUser;
            if (currentUser != null && mounted) {
              state = state.copyWith(
                user: currentUser,
                isAuthenticated: true,
                isFirstLaunch: false,
              );
            }
            // Start the auth subscription regardless so future sign-in/out events work
            _authSubscription?.cancel();
            _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
              if (mounted) {
                state = state.copyWith(
                  user: user,
                  isAuthenticated: user != null,
                  isFirstLaunch: user != null ? false : state.isFirstLaunch,
                );
              }
            });
          }
        } catch (e) {
          // Firebase not yet initialized — onFirebaseReady() will handle it
        }
      }
    }
  }

  Future<void> onFirebaseReady(fb.FirebaseAuth auth) async {
    // Safe to read SecureStorage now — Firebase is initialized
    try {
      _deviceId = await _hmacService.getInstallationId().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 'device-timeout-fallback',
      );
    } catch (e) {
      _ref.read(loggerProvider).warn('getInstallationId failed in onFirebaseReady: $e', category: 'AUTH');
    }

    _authSubscription?.cancel();

    _authSubscription = auth.authStateChanges().listen((user) async {
      final logger = _ref.read(loggerProvider);
      logger.info('Firebase auth state change: ${user?.email ?? "signed-out"}', category: 'AUTH');
      
      if (mounted) {
        state = state.copyWith(
          user: user,
          isAuthenticated: user != null,
          isFirstLaunch: user != null ? false : state.isFirstLaunch,
          isLoading: false,
        );
      }
    });
  }

  void triggerBackgroundRecovery() {
    _ref.read(loggerProvider).info('Triggering background recovery...', category: 'AUTH');
    _syncAndRecover();
  }

  Future<void> _syncAndRecover() async {
    final logger = _ref.read(loggerProvider);
    if (mounted) state = state.copyWith(isRecovering: true);

    try {
      logger.info('Starting sync and recovery...', category: 'AUTH');
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove('last_recovery_at');
      
      await _hmacService.syncCurrentKeyToCloud().timeout(const Duration(seconds: 10));
      await _ref.read(recoveryServiceProvider).recoverAll().timeout(const Duration(minutes: 5));
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

  Future<void> _performFullLogout() async {
    final logger = _ref.read(loggerProvider);
    logger.info('Starting full logout and data purge', category: 'AUTH');
    try {
      if (_firebaseAuth != null) await _firebaseAuth.signOut();

      final installationId = await _storage.read(key: 'installation_id');
      await _storage.deleteAll();
      if (installationId != null) {
        await _storage.write(key: 'installation_id', value: installationId);
        logger.info('Preserved installation_id during logout.', category: 'AUTH');
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
          logger.warn('Error clearing box $name: $e', category: 'AUTH');
        }
      }));

      await _ref.read(outboxRepositoryProvider).clearAll();

      if (mounted) {
        state = AuthState(
          isAuthenticated: false,
          unlocked: false,
          isPinSetup: false,
          isFirstLaunch: true,
          isLoading: false,
        );
      }
      logger.info('Logout complete', category: 'AUTH');
    } catch (e) {
      logger.error('Logout Error: $e', category: 'AUTH', error: e);
    }
  }

  Future<bool> signUp(String email, String password, {String? gymName, String? ownerName, String? phone}) async {
    state = state.copyWith(isLoading: true);
    await _storage.delete(key: 'pin_hash');
    await _storage.delete(key: 'pin_salt');
    try {
      if (_firebaseAuth == null) throw Exception('Firebase not initialized');
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      
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

        // Monitoring Sidecar: Passive Archival (Moved to AFTER profile write succeeds)
        MonitoringService.logUserRegistration(
          credential.user?.uid ?? '', 
          email,
          gymName: gymName,
          ownerName: ownerName,
          phone: phone,
          address: '',
        );

        _ref.read(syncWorkerProvider).performSync();

        if (mounted) {
          state = state.copyWith(
            isAuthenticated: true,
            isFirstLaunch: false,
            isPinSetup: false,
            unlocked: false,
            authAttempts: 0,
          );
        }
      } else {
        // Monitoring Sidecar: Passive Archival
        MonitoringService.logUserRegistration(
          credential.user?.uid ?? '', 
          email,
          gymName: gymName,
          ownerName: ownerName,
          phone: phone,
        );
      }
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(authAttempts: state.authAttempts + 1);
      return false;
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
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
