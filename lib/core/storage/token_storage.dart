import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken        = 'auth_token';
  static const _keyBiometricToken = 'biometric_token'; // token khusus Face ID
  static const _keyPegawaiId    = 'pegawai_id';
  static const _keyNama         = 'pegawai_nama';
  static const _keyNip          = 'pegawai_nip';
  static const _keyJabatan      = 'pegawai_jabatan';
  static const _keyUnit         = 'pegawai_unit';
  static const _keyPhoto        = 'pegawai_photo';

  // Token aktif
  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: _keyToken);

  static Future<void> deleteToken() =>
      _storage.delete(key: _keyToken);

  // Token biometric — disimpan terpisah, tidak dihapus saat logout biasa
  static Future<void> saveBiometricToken(String token) =>
      _storage.write(key: _keyBiometricToken, value: token);

  static Future<String?> getBiometricToken() =>
      _storage.read(key: _keyBiometricToken);

  static Future<void> deleteBiometricToken() =>
      _storage.delete(key: _keyBiometricToken);

  // Data Pegawai
  static Future<void> savePegawai(Map<String, dynamic> pegawai) async {
    await _storage.write(key: _keyPegawaiId, value: pegawai['id'].toString());
    await _storage.write(key: _keyNama,      value: pegawai['nama'] ?? '');
    await _storage.write(key: _keyNip,       value: pegawai['nip'] ?? '');
    await _storage.write(key: _keyJabatan,   value: pegawai['jabatan_nama'] ?? '');
    await _storage.write(key: _keyUnit,      value: pegawai['unit_nama'] ?? '');
    await _storage.write(key: _keyPhoto,     value: pegawai['photo'] ?? '');
  }

  static Future<Map<String, String?>> getPegawai() async {
    return {
      'id'      : await _storage.read(key: _keyPegawaiId),
      'nama'    : await _storage.read(key: _keyNama),
      'nip'     : await _storage.read(key: _keyNip),
      'jabatan' : await _storage.read(key: _keyJabatan),
      'unit'    : await _storage.read(key: _keyUnit),
      'photo'   : await _storage.read(key: _keyPhoto),
    };
  }

  /// Logout biasa — hapus token aktif, tapi PERTAHANKAN biometric token + data pegawai
  static Future<void> clearForLogout() async {
    await _storage.delete(key: _keyToken);
    // biometric token, NIP, dan data pegawai TIDAK dihapus
  }

  /// Logout penuh — hapus semua termasuk biometric
  static Future<void> clearAll() => _storage.deleteAll();

  // Cek sudah login (token aktif)
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Cek bisa login dengan biometric (ada biometric token)
  static Future<bool> canLoginWithBiometric() async {
    final token = await getBiometricToken();
    return token != null && token.isNotEmpty;
  }
}