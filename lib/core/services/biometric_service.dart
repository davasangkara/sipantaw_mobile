import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk Face ID / Fingerprint authentication.
/// Menyimpan NIP terakhir agar bisa re-login tanpa ketik NIP.
class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();
  static const _keyNip = 'biometric_nip';
  static const _keyEnabled = 'biometric_enabled';

  /// Cek apakah device mendukung biometrik
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
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
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Autentikasi dengan biometrik
  static Future<bool> authenticate({
    String reason = 'Verifikasi identitas Anda untuk masuk ke SIPANTAW',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Simpan NIP untuk biometric login
  static Future<void> saveNipForBiometric(String nip) async {
    await _storage.write(key: _keyNip, value: nip);
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  /// Ambil NIP yang tersimpan
  static Future<String?> getSavedNip() =>
      _storage.read(key: _keyNip);

  /// Cek apakah biometric login diaktifkan
  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  /// Nonaktifkan biometric login
  static Future<void> disableBiometric() async {
    await _storage.delete(key: _keyEnabled);
  }

  /// Hapus semua data biometric
  static Future<void> clearBiometric() async {
    await _storage.delete(key: _keyNip);
    await _storage.delete(key: _keyEnabled);
  }
}
