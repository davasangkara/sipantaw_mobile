import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

/// Hasil reverse geocoding — alamat lengkap terstruktur
class LocationAddress {
  final String alamatJalan;
  final String rtrw;
  final String kelurahan;
  final String kecamatan;
  final String kabkota;
  final String provinsi;
  final double latitude;
  final double longitude;

  const LocationAddress({
    required this.alamatJalan,
    required this.rtrw,
    required this.kelurahan,
    required this.kecamatan,
    required this.kabkota,
    required this.provinsi,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      // Nominatim requires a User-Agent
      'User-Agent': 'SIPANTAW-Mobile/1.0 (sipantaw@app.id)',
      'Accept-Language': 'id,en',
    },
  ));

  /// Minta izin dan ambil posisi GPS saat ini
  static Future<Position?> getCurrentPosition() async {
    try {
      // Cek service aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Cek & minta izin
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Ambil posisi dengan timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocoding menggunakan Nominatim (OpenStreetMap) — gratis, tanpa API key
  static Future<LocationAddress?> reverseGeocode(
    double lat,
    double lon,
  ) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'addressdetails': 1,
          'zoom': 18,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      // Bangun alamat jalan dari komponen yang tersedia
      final road = addr['road']?.toString() ??
          addr['pedestrian']?.toString() ??
          addr['footway']?.toString() ??
          addr['path']?.toString() ??
          '';
      final houseNumber = addr['house_number']?.toString() ?? '';
      final alamatJalan = houseNumber.isNotEmpty
          ? '$road No. $houseNumber'
          : road.isNotEmpty
              ? road
              : data['display_name']?.toString().split(',').first ?? '';

      // Kelurahan / desa
      final kelurahan = addr['village']?.toString() ??
          addr['suburb']?.toString() ??
          addr['neighbourhood']?.toString() ??
          addr['quarter']?.toString() ??
          '';

      // Kecamatan
      final kecamatan = addr['city_district']?.toString() ??
          addr['district']?.toString() ??
          addr['county']?.toString() ??
          '';

      // Kab/Kota
      final kabkota = addr['city']?.toString() ??
          addr['town']?.toString() ??
          addr['municipality']?.toString() ??
          addr['county']?.toString() ??
          '';

      // Provinsi
      final provinsi = addr['state']?.toString() ?? '';

      return LocationAddress(
        alamatJalan: alamatJalan,
        rtrw: '',
        kelurahan: kelurahan,
        kecamatan: kecamatan,
        kabkota: kabkota,
        provinsi: provinsi,
        latitude: lat,
        longitude: lon,
      );
    } catch (_) {
      return null;
    }
  }

  /// Ambil posisi + reverse geocode sekaligus
  static Future<LocationAddress?> getAddressFromCurrentLocation() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;
    return reverseGeocode(pos.latitude, pos.longitude);
  }
}
