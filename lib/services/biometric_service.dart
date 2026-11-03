import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  // 🛡️ Hardware Keystore with EncryptedSharedPreferences on Android
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keySessionToken = 'passkeep_session_token';
  static const String _keyUserEmail = 'passkeep_user_email';
  static const String _keyUserName = 'passkeep_user_name';
  static const String _keyUserId = 'passkeep_user_id';
  static const String _keyBiometricEnabled = 'passkeep_biometric_enabled';

  /// Check if device supports ANY screen lock (Fingerprint, Face, PIN, Pattern, or Password)
  static Future<bool> isDeviceSecurityAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Trigger native Android security prompt (Fingerprint, Face, Phone PIN, Pattern, or Password)
  static Future<bool> authenticateWithDeviceSecurity({
    String reason = 'Unlock PassKeep using your Fingerprint, Face, or Phone PIN',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 👈 Allows Phone PIN, Pattern & Password fallback!
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Store session token and user profile in hardware keystore
  static Future<void> saveSessionToken({
    required String email,
    required String token,
    String? name,
    String? userId,
  }) async {
    await _storage.write(key: _keySessionToken, value: token);
    await _storage.write(key: _keyUserEmail, value: email);
    if (name != null) await _storage.write(key: _keyUserName, value: name);
    if (userId != null) await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Check if an active signed-in session exists on device
  static Future<bool> hasActiveSession() async {
    final String? email = await _storage.read(key: _keyUserEmail);
    final String? token = await _storage.read(key: _keySessionToken);
    return email != null && email.isNotEmpty && token != null && token.isNotEmpty;
  }

  /// Get stored user profile
  static Future<Map<String, String?>> getStoredUserProfile() async {
    final email = await _storage.read(key: _keyUserEmail);
    final name = await _storage.read(key: _keyUserName);
    final userId = await _storage.read(key: _keyUserId);
    final token = await _storage.read(key: _keySessionToken);
    return {
      'email': email,
      'name': name,
      'userId': userId,
      'token': token,
    };
  }

  /// Get stored session token for the user
  static Future<String?> getStoredSessionToken([String? email]) async {
    final String? isEnabled = await _storage.read(key: _keyBiometricEnabled);
    if (isEnabled != 'true') return null;

    if (email != null) {
      final String? storedEmail = await _storage.read(key: _keyUserEmail);
      if (storedEmail != email) return null;
    }

    return await _storage.read(key: _keySessionToken);
  }

  /// Check if user has device security enabled
  static Future<bool> isDeviceSecurityEnabled([String? email]) async {
    final String? isEnabled = await _storage.read(key: _keyBiometricEnabled);
    if (email != null) {
      final String? storedEmail = await _storage.read(key: _keyUserEmail);
      return isEnabled == 'true' && storedEmail == email;
    }
    return isEnabled == 'true';
  }

  /// Clear stored credentials on logout
  static Future<void> clearStoredSession() async {
    await _storage.delete(key: _keySessionToken);
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserId);
  }
}
