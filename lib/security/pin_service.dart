import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinHashKey = 'pin_hash';
  static const _editPwHashKey = 'edit_pw_hash';
  static final _localAuth = LocalAuthentication();

  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: 'pin_hash', value: hash);
  }

  Future<bool> verifyPin(String input) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    final inputHash = sha256.convert(utf8.encode(input)).toString();
    return inputHash == stored;
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
