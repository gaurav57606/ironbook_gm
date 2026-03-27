import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinService {
  final FlutterSecureStorage _storage;
  static const _pinHashKey = 'pin_hash';
  static const _editPwHashKey = 'edit_pw_hash';
  static const _failCountKey = 'pin_fail_count';
  static const _lockoutUntilKey = 'pin_lockout_until';
  
  final _localAuth = LocalAuthentication();

  PinService(this._storage);

  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.delete(key: _failCountKey);
    await _storage.delete(key: _lockoutUntilKey);
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
    if (stored == null) return false;
    
    final inputHash = sha256.convert(utf8.encode(input)).toString();
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
        await FirebaseAuth.instance.signOut();
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
    final hash = sha256.convert(utf8.encode(password)).toString();
    await _storage.write(key: _editPwHashKey, value: hash);
  }

  Future<bool> verifyEditPassword(String input) async {
    final stored = await _storage.read(key: _editPwHashKey);
    if (stored == null) return false;
    return sha256.convert(utf8.encode(input)).toString() == stored;
  }

  Future<bool> authenticateWithBiometric() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return false;

    return await _localAuth.authenticate(
      localizedReason: 'Verify your identity to open IronBook GM',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final pinServiceProvider = Provider<PinService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PinService(storage);
});
