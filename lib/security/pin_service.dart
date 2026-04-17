import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../providers/base_providers.dart';

class PinService {
  final FirebaseAuth _auth;
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
    final hash = _hashWithSalt(pin, salt);
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.delete(key: _failCountKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  String _hashWithSalt(String input, String salt) {
    var hash = sha256.convert(utf8.encode(input + salt)).toString();
    // Perform 1000 rounds for basic work factor without being too slow in pure Dart
    for (int i = 0; i < 1000; i++) {
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
    
    final inputHash = _hashWithSalt(input, salt);
    final isCorrect = inputHash == stored;

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
        await _auth.signOut();
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
    final hash = _hashWithSalt(password, salt);
    await _storage.write(key: _editPwHashKey, value: hash);
    await _storage.write(key: _editPwSaltKey, value: salt);
  }

  Future<bool> verifyEditPassword(String input) async {
    final stored = await _storage.read(key: _editPwHashKey);
    final salt = await _storage.read(key: _editPwSaltKey);
    if (stored == null || salt == null) return false;
    return _hashWithSalt(input, salt) == stored;
  }

  Future<bool> authenticateWithBiometric() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return false;

    return await _localAuth.authenticate(
      localizedReason: 'Verify your identity to open IronBook GM',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(appSecureStorageProvider);
  final auth = ref.watch(firebaseAuthProvider)!;
  return PinService(storage, auth);
});
