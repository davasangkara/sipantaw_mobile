import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk Face ID / Fingerprint authentication.
class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();
  static const _keyNip = 'biometric_nip';
  static const _keyEnabled = 'biometric_enabled';

  /// Cek apakah device mendukung biometrik
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported; // OR bukan AND — device PIN juga valid
    } catch (_) {
      return false;
    }
  }

  /// Cek jenis biometrik yang tersedia
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Cek apakah Face ID tersedia
  static Future<bool> hasFaceId() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face) ||
          biometrics.contains(BiometricType.strong);
    } catch (_) {
      return false;
    }
  }

  /// Autentikasi dengan biometrik — return (success, errorMessage)
  static Future<({bool success, String? error})> authenticateWithDetail({
    String reason = 'Verifikasi identitas Anda untuk masuk ke SIPANTAW WFA',
  }) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // izinkan PIN/password sebagai fallback
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      return (success: result, error: result ? null : 'Autentikasi dibatalkan');
    } on PlatformException catch (e) {
      final msg = switch (e.code) {
        auth_error.notAvailable =>
          'Biometrik tidak tersedia di perangkat ini',
        auth_error.notEnrolled =>
          'Belum ada biometrik yang terdaftar. Daftarkan di Pengaturan.',
        auth_error.lockedOut =>
          'Terlalu banyak percobaan. Coba lagi nanti.',
        auth_error.permanentlyLockedOut =>
          'Biometrik dikunci. Gunakan PIN perangkat.',
        auth_error.passcodeNotSet =>
          'PIN perangkat belum diatur. Atur di Pengaturan.',
        _ => e.message ?? 'Autentikasi gagal (${e.code})',
      };
      return (success: false, error: msg);
    } catch (e) {
      return (success: false, error: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Autentikasi sederhana — return bool
  static Future<bool> authenticate({
    String reason = 'Verifikasi identitas Anda untuk masuk ke SIPANTAW WFA',
  }) async {
    final result = await authenticateWithDetail(reason: reason);
    return result.success;
  }

  /// Simpan NIP untuk biometric login
  static Future<void> saveNipForBiometric(String nip) async {
    await _storage.write(key: _keyNip, value: nip);
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  static Future<String?> getSavedNip() => _storage.read(key: _keyNip);

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  static Future<void> disableBiometric() =>
      _storage.delete(key: _keyEnabled);

  static Future<void> clearBiometric() async {
    await _storage.delete(key: _keyNip);
    await _storage.delete(key: _keyEnabled);
  }
}
