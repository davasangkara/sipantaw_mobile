import 'package:flutter/foundation.dart';

@immutable
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'http://10.33.225.98:8000/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String checkNip = '/auth/check-nip';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String logout = '/auth/logout';

  static const String dashboard = '/dashboard';
  static const String profil = '/profil';
  static const String absensi = '/absensi';
  static const String laporan = '/laporan';
  static const String riwayat = '/riwayat';
  static const String cuti = '/cuti';
  static const String lembur = '/lembur';
  static const String skpTarget = '/skp-target';
  static const String chat = '/chat';
}