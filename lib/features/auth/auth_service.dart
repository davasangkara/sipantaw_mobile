import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/storage/token_storage.dart';
import '../../core/services/biometric_service.dart';

class AuthService {
  // Step 1 - Cek NIP
  static Future<Map<String, dynamic>> checkNip(String nip) async {
    try {
      final res = await ApiClient.post(
        ApiConfig.checkNip,
        data: {'NIP': nip},
      );
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Step 2 - Kirim OTP ke nomor baru
  static Future<Map<String, dynamic>> sendOtp(String tempKey, String phone) async {
    try {
      final res = await ApiClient.post(
        ApiConfig.sendOtp,
        data: {'temp_key': tempKey, 'phone': phone},
      );
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Step 3 - Verifikasi OTP
  static Future<Map<String, dynamic>> verifyOtp(
    String tempKey,
    String otp, {
    String? nip, // NIP untuk disimpan ke biometric
  }) async {
    try {
      final res = await ApiClient.post(
        ApiConfig.verifyOtp,
        data: {'temp_key': tempKey, 'otp': otp},
      );

      // Simpan token dan data pegawai
      final data = res.data;
      await TokenStorage.saveToken(data['token']);
      await TokenStorage.savePegawai(data['pegawai']);

      // Simpan NIP untuk biometric login jika disediakan
      if (nip != null && nip.isNotEmpty) {
        await BiometricService.saveNipForBiometric(nip);
      }

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout — tidak hapus biometric data agar bisa re-login dengan Face ID
  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {}
    await TokenStorage.clearAll();
    // Biometric data TIDAK dihapus — user bisa login lagi dengan Face ID
  }

  // Logout penuh — hapus semua termasuk biometric
  static Future<void> logoutFull() async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {}
    await TokenStorage.clearAll();
    await BiometricService.clearBiometric();
  }

  // Error handler
  static String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) return data['message'];
      if (data is Map && data['error'] != null) return data['error'];
    }
    return 'Tidak dapat terhubung ke server.';
  }
}