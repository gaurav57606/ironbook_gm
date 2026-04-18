import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../providers/base_providers.dart';

enum AuthResult { success, failure, canceled }

class PinService {
  final FirebaseAuth? _auth;
  final FlutterSecureStorage _storage;
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';
  static const _editPwHashKey = 'edit_pw_hash';
  static const _editPwSaltKey = 'edit_pw_salt';
  static const _failCountKey = 'pin_fail_count';
  static const _lockoutUntilKey = 'pin_lockout_until';
  
  final _localAuth = LocalAuthentication();

  PinService(this._storage, this._auth);

  Future<void> savePin(String pin) async {
    final salt = base64Encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = _hashWithSalt(pin, salt, iterations: 100000);
    // Prefix with v2| to indicate hardened hashing
    await _storage.write(key: _pinHashKey, value: 'v2|$hash');
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.delete(key: _failCountKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  String _hashWithSalt(String input, String salt, {int iterations = 100000}) {
    var hash = sha256.convert(utf8.encode(input + salt)).toString();
    // Hardened work factor: 100,000 rounds of SHA-256
    for (int i = 0; i < iterations; i++) {
      hash = sha256.convert(utf8.encode(hash + salt)).toString();
    }
    return hash;
  }

  Future<void> setPin(String pin) async => savePin(pin);

  Future<bool> verifyPin(String input) async {
    // 1. Check Lockout
    final lockoutUntilRaw = await _storage.read(key: _lockoutUntilKey);
    if (lockoutUntilRaw != null) {
      final lockoutUntil = DateTime.tryParse(lockoutUntilRaw);
      if (lockoutUntil != null && lockoutUntil.isAfter(DateTime.now())) {
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
      final inputHash = _hashWithSalt(input, salt, iterations: 100000);
      isCorrect = inputHash == actualHash;
    } else {
      // Legacy v1 hash: 1000 iterations
      final inputHash = _hashWithSalt(input, salt, iterations: 1000);
      isCorrect = inputHash == stored;

      // Auto-migrate to v2 if successful
      if (isCorrect) {
        await savePin(input);
      }
    }

    if (isCorrect) {
      // Success: Reset fails
      await _storage.delete(key: _failCountKey);
      await _storage.delete(key: _lockoutUntilKey);
      return true;
    } else {
      // Failure: Increment fails
      final countRaw = await _storage.read(key: _failCountKey);
      final count = (int.tryParse(countRaw ?? '0') ?? 0) + 1;
      await _storage.write(key: _failCountKey, value: count.toString());

      if (count >= 10) {
        // P0: 10 failed attempts -> Force Logout & Nuke PIN
        await _storage.delete(key: _pinHashKey);
        await _storage.delete(key: _failCountKey);
        await _storage.delete(key: _lockoutUntilKey);
        await _auth?.signOut();
        return false;
      }

      if (count >= 5) {
        // Lockout for 30 seconds
        final lockoutTime = DateTime.now().add(const Duration(seconds: 30));
        await _storage.write(key: _lockoutUntilKey, value: lockoutTime.toIso8601String());
      }
      return false;
    }
  }

  Future<int> getFailCount() async {
    final count = await _storage.read(key: _failCountKey);
    return int.tryParse(count ?? '0') ?? 0;
  }

  Future<DateTime?> getLockoutUntil() async {
    final raw = await _storage.read(key: _lockoutUntilKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> saveEditPassword(String password) async {
    assert(password.length >= 4, 'Edit password must be at least 4 characters');
    final salt = base64Encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = _hashWithSalt(password, salt, iterations: 100000);
    await _storage.write(key: _editPwHashKey, value: 'v2|$hash');
    await _storage.write(key: _editPwSaltKey, value: salt);
  }

  Future<bool> verifyEditPassword(String input) async {
    final stored = await _storage.read(key: _editPwHashKey);
    final salt = await _storage.read(key: _editPwSaltKey);
    if (stored == null || salt == null) return false;

    if (stored.startsWith('v2|')) {
      final actualHash = stored.substring(3);
      return _hashWithSalt(input, salt, iterations: 100000) == actualHash;
    } else {
      final isCorrect = _hashWithSalt(input, salt, iterations: 1000) == stored;
      if (isCorrect) {
        await saveEditPassword(input);
      }
      return isCorrect;
    }
  }

  Future<AuthResult> authenticateWithBiometric() async {
    try {
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
  /// Attempts biometrics first (if enrolled), then falls back to PIN.
  Future<AuthResult> authenticate({String? pinFallback}) async {
    // 1. Try Biometrics
    final bioResult = await authenticateWithBiometric();
    if (bioResult == AuthResult.success) return AuthResult.success;
    
    // 2. Fallback to PIN if provided and biometrics didn't succeed
    if (pinFallback != null) {
      final pinSuccess = await verifyPin(pinFallback);
      return pinSuccess ? AuthResult.success : AuthResult.failure;
    }

    return bioResult;
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return PinService(storage, auth);
});
