import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:ironbook_gm/core/providers/base_providers.dart';

import 'package:ironbook_gm/core/data/local/drift/outbox_repository.dart';

enum AuthResult { success, failure, canceled, lockedOut }

class PinService {
  final FlutterSecureStorage _storage;
  final OutboxRepository _outboxRepo;
  
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';
  static const _editPwHashKey = 'edit_pw_hash';
  static const _editPwSaltKey = 'edit_pw_salt';
  static const _failCountKey = 'pin_fail_count';
  static const _lockoutUntilKey = 'pin_lockout_until';
  
  final _localAuth = LocalAuthentication();

  PinService(this._storage, this._outboxRepo);

  Future<void> savePin(String pin) async {
    final salt = base64Encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = await compute(_performHash, PinHashParams(pin, salt, 100000));
    // Prefix with v2| to indicate hardened hashing
    await _storage.write(key: _pinHashKey, value: 'v2|$hash');
    await _storage.write(key: _pinSaltKey, value: salt);
    await _outboxRepo.resetPinAttempts();
  }

  static String _performHash(PinHashParams params) {
    var hash = sha256.convert(utf8.encode(params.input + params.salt)).toString();
    // Hardened work factor: 100,000 rounds of SHA-256
    for (int i = 0; i < params.iterations - 1; i++) {
      hash = sha256.convert(utf8.encode(hash + params.salt)).toString();
    }
    return hash;
  }

  Future<void> setPin(String pin) async => savePin(pin);

  Future<bool> verifyPin(String input) async {
    // 1. Check Lockout (Now in Drift)
    final attempts = await _outboxRepo.getPinAttempts();
    if (attempts != null && attempts.lockoutUntil != null) {
      if (attempts.lockoutUntil!.isAfter(DateTime.now())) {
        return false; // Still locked out
      }
    }

    final stored = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    
    if (stored == null || salt == null) {
       // Support legacy unsalted hashes for a transition period if needed
       // For this security audit, we force re-setup if salt is missing
       return false;
    }
    
    // Determine version and work factor
    bool isCorrect = false;
    if (stored.startsWith('v2|')) {
      final actualHash = stored.substring(3);
      final inputHash = await compute(_performHash, PinHashParams(input, salt, 100000));
      isCorrect = inputHash == actualHash;
    } else {
      // Legacy v1 hash: 1000 iterations
      final inputHash = await compute(_performHash, PinHashParams(input, salt, 1000));
      isCorrect = inputHash == stored;

      // Auto-migrate to v2 if successful
      if (isCorrect) {
        await savePin(input);
      }
    }

    if (isCorrect) {
      // Success: Reset fails
      await _outboxRepo.resetPinAttempts();
      return true;
    } else {
      // Failure: Increment fails
      final currentCount = attempts?.count ?? 0;
      final newCount = currentCount + 1;
      
      DateTime? lockoutUntil;
      if (newCount >= 10) {
        lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
      } else if (newCount >= 5) {
        lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      }
      
      await _outboxRepo.updatePinAttempts(count: newCount, lockoutUntil: lockoutUntil);
      return false;
    }
  }

  Future<int> getFailCount() async {
    final attempts = await _outboxRepo.getPinAttempts();
    return attempts?.count ?? 0;
  }

  Future<DateTime?> getLockoutUntil() async {
    final attempts = await _outboxRepo.getPinAttempts();
    return attempts?.lockoutUntil;
  }

  Future<void> saveEditPassword(String password) async {
    assert(password.length >= 4, 'Edit password must be at least 4 characters');
    final salt = base64Encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = await compute(_performHash, PinHashParams(password, salt, 100000));
    await _storage.write(key: _editPwHashKey, value: 'v2|$hash');
    await _storage.write(key: _editPwSaltKey, value: salt);
  }

  Future<bool> verifyEditPassword(String input) async {
    final stored = await _storage.read(key: _editPwHashKey);
    final salt = await _storage.read(key: _editPwSaltKey);
    if (stored == null || salt == null) return false;

    if (stored.startsWith('v2|')) {
      final actualHash = stored.substring(3);
      final inputHash = await compute(_performHash, PinHashParams(input, salt, 100000));
      return inputHash == actualHash;
    } else {
      final inputHash = await compute(_performHash, PinHashParams(input, salt, 1000));
      final isCorrect = inputHash == stored;
      if (isCorrect) {
        await saveEditPassword(input);
      }
      return isCorrect;
    }
  }

  Future<AuthResult> authenticateWithBiometric() async {
    try {
      if (kIsWeb) return AuthResult.failure; // Biometrics not supported on web in this implementation
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return AuthResult.failure;

      final success = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to open IronBook GM',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return success ? AuthResult.success : AuthResult.canceled;
    } catch (e) {
      debugPrint('PinService: Biometric Auth Error: $e');
      return AuthResult.failure;
    }
  }

  /// Unified entry point for authentication.
  /// Mandatory for: Biometrics First -> PIN Fallback flow.
  Future<AuthResult> authenticate({String? pinFallback}) async {
    // 1. Try Biometrics if available and supported
    final biometricStatus = await authenticateWithBiometric();
    if (biometricStatus == AuthResult.success) {
      return AuthResult.success;
    }

    // 2. Fallback to PIN if provided (e.g., from PinEntryScreen)
    if (pinFallback != null) {
      final pinVerified = await verifyPin(pinFallback);
      return pinVerified ? AuthResult.success : AuthResult.failure;
    }

    // 3. If biometrics were canceled/failed and no PIN provided, report back
    return biometricStatus;
  }
}

class PinHashParams {
  final String input;
  final String salt;
  final int iterations;

  PinHashParams(this.input, this.salt, this.iterations);
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final outboxRepo = ref.watch(outboxRepositoryProvider);
  return PinService(storage, outboxRepo);
});











