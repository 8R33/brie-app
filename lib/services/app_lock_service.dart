import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const String _lockTypeKey = 'brie_lock_type';
  static const String _lockCredentialKey = 'brie_lock_credential';
  static const String _biometricEnabledKey = 'brie_biometric_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Saves the user's selected lock type.
  ///
  /// Possible values:
  /// - pin
  /// - password
  Future<void> setLock({
    required String type,
    required String credential,
  }) async {
    final hashedCredential = _hashCredential(credential);

    await _storage.write(key: _lockTypeKey, value: type);

    await _storage.write(key: _lockCredentialKey, value: hashedCredential);
  }

  /// Returns the current lock type.
  Future<String?> getLockType() async {
    return _storage.read(key: _lockTypeKey);
  }

  /// Checks whether a PIN/password has been configured.
  Future<bool> hasLock() async {
    final type = await getLockType();
    final credential = await _storage.read(key: _lockCredentialKey);

    return type != null && credential != null;
  }

  /// Checks the entered PIN/password against the stored hash.
  Future<bool> verifyCredential(String credential) async {
    final storedHash = await _storage.read(key: _lockCredentialKey);

    if (storedHash == null) {
      return false;
    }

    return _hashCredential(credential) == storedHash;
  }

  /// Enables or disables fingerprint/face unlock.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Returns whether biometric unlock is enabled.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);

    return value == 'true';
  }

  /// Removes the brié app lock.
  ///
  /// This does NOT sign the user out of Firebase.
  Future<void> clearLock() async {
    await _storage.delete(key: _lockTypeKey);
    await _storage.delete(key: _lockCredentialKey);
    await _storage.delete(key: _biometricEnabledKey);
  }

  /// Changes the existing PIN/password.
  Future<void> changeCredential(String newCredential) async {
    final currentType = await getLockType();

    if (currentType == null) {
      throw StateError('No brié lock has been configured.');
    }

    await _storage.write(
      key: _lockCredentialKey,
      value: _hashCredential(newCredential),
    );
  }

  String _hashCredential(String credential) {
    final bytes = utf8.encode(credential);

    return sha256.convert(bytes).toString();
  }
}
