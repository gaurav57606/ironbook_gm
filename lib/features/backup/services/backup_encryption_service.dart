import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;

class InvalidBackupPasswordException implements Exception {
  final String message;
  InvalidBackupPasswordException([this.message = 'Invalid backup password']);
  @override
  String toString() => message;
}

class BackupEncryptionService {
  static const int _saltSize = 16;
  static const int _ivSize = 16;
  static const int _keySize = 32; // 256-bit
  static const int _pbkdf2Iterations = 10000;

  /// Encrypts the payload and returns [Salt][IV][Ciphertext]
  Future<Uint8List> encrypt(String password, String jsonPayload) async {
    return compute(
      _encryptTask,
      _EncryptionParams(password: password, payload: jsonPayload),
    );
  }

  /// Decrypts the data. Throws InvalidBackupPasswordException if decryption fails.
  Future<String> decrypt(String password, Uint8List data) async {
    return compute(
      _decryptTask,
      _DecryptionParams(password: password, data: data),
    );
  }

  static Uint8List _encryptTask(_EncryptionParams params) {
    final salt = _generateRandomBytes(_saltSize);
    final iv = _generateRandomBytes(_ivSize);
    
    final key = _deriveKey(params.password, salt);
    
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(params.payload, iv: enc.IV(iv));
    
    final result = BytesBuilder();
    result.add(salt);
    result.add(iv);
    result.add(encrypted.bytes);
    
    return result.toBytes();
  }

  static String _decryptTask(_DecryptionParams params) {
    if (params.data.length < _saltSize + _ivSize) {
      throw const FormatException('Invalid backup file format');
    }

    final salt = params.data.sublist(0, _saltSize);
    final iv = params.data.sublist(_saltSize, _saltSize + _ivSize);
    final ciphertext = params.data.sublist(_saltSize + _ivSize);

    final key = _deriveKey(params.password, salt);
    
    try {
      final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
      return encrypter.decrypt(enc.Encrypted(ciphertext), iv: enc.IV(iv));
    } catch (e) {
      throw InvalidBackupPasswordException();
    }
  }

  static Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, _pbkdf2Iterations, _keySize));
    
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _generateRandomBytes(int size) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(size, (_) => random.nextInt(256)));
  }
}

class _EncryptionParams {
  final String password;
  final String payload;
  _EncryptionParams({required this.password, required this.payload});
}

class _DecryptionParams {
  final String password;
  final Uint8List data;
  _DecryptionParams({required this.password, required this.data});
}









