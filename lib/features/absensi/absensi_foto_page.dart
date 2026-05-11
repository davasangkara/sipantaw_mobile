import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import 'absensi_page.dart';

class AbsensiFotoPage extends StatefulWidget {
  const AbsensiFotoPage({super.key});

  @override
  State<AbsensiFotoPage> createState() => _AbsensiFotoPageState();
}

class _AbsensiFotoPageState extends State<AbsensiFotoPage> {
  static const _teal = AppColors.teal;

  bool _loading = true;
  Map<String, dynamic>? _statusAbsensi;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('${ApiConfig.laporan}/cek-absensi');
      setState(() {
        _statusAbsensi = res.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Cek jam aktif
  bool _isJamAktif(int jenis) {
    final jam = _now.hour;
    return switch (jenis) {
      1 => jam >= 7 && jam < 10, // Pagi 07.30-09.00
      2 => jam >= 11 && jam < 14, // Siang 11.00-13.00
      3 => jam >= 15 && jam < 18, // Sore 15.00-17.00
      _ => false,
    };
  }

  bool _sudahAbsen(int jenis) {
    if (_statusAbsensi == null) return false;
    final key = jenis == 1
        ? 'pagi'
        : jenis == 2
            ? 'siang'
            : 'sore';
    return _statusAbsensi![key]?['sudah'] == true;
  }

  String _jamRange(int jenis) => switch (jenis) {
        1 => '07.30 – 09.00',
        2 => '11.00 – 13.00',
        3 => '15.00 – 17.00',
        _ => '',
      };

  String _namaJenis(int jenis) => switch (jenis) {
        1 => 'Pagi',
        2 => 'Siang',
        3 => 'Sore',
        _ => '',
      };

  IconData _iconJenis(int jenis) => switch (jenis) {
        1 => Icons.wb_twilight,
        2 => Icons.wb_sunny,
        3 => Icons.nights_stay_outlined,
        _ => Icons.access_time,
      };

  Future<void> _absen(int jenis) async {
    // Minta izin kamera & lokasi
    final picker = ImagePicker();

    // Ambil foto
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked == null) return;

    // Tampilkan loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _teal),
      ),
    );

    try {
      // Ambil lokasi
      String lokasi = 'Lokasi tidak tersedia';
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 5));
        lokasi = '${pos.latitude}, ${pos.longitude}';
      } catch (_) {}

      // Convert foto ke base64
      final bytes = await File(picked.path).readAsBytes();
      final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final today = DateFormat('yyyy-MM-dd').format(_now);

      // Kirim ke API
      final res = await ApiClient.post(
        '${ApiConfig.laporan}/absensi',
        data: {
          'jenis': jenis,
          'foto_data': base64,
          'lokasi': lokasi,
          'tanggal': today,
          'timezone_name': 'Asia/Jakarta',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.data['message'] ?? 'Absen berhasil!'),
          backgroundColor: _teal,
        ));
        _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.data['message'] ?? 'Gagal absen.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Terjadi kesalahan. Coba lagi.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jamSekarang = DateFormat('HH.mm').format(_now);
    final timezone = 'WIB (UTC+7)';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Absensi & Geolocation',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(jamSekarang,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(timezone, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : RefreshIndicator(
              color: _teal,
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Setiap sesi absen dibuka sesuai jam aktif. '
                              'Sesi yang sudah lewat waktunya akan terkunci otomatis. '
                              'Foto otomatis diberi watermark waktu & lokasi.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3 Card absensi
                    ...[1, 2, 3].map(
                      (jenis) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAbsenCard(jenis),
                      ),
                    ),

                    const SizedBox(height: 8),

                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AbsensiPage(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.calendar_month,
                        color: _teal,
                      ),
                      label: const Text(
                        'Absensi Jika Tidak Melakukan WFA',
                        style: TextStyle(color: _teal),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAbsenCard(int jenis) {
    final sudah = _sudahAbsen(jenis);
    final aktif = _isJamAktif(jenis);
    final nama = _namaJenis(jenis);
    final jamRange = _jamRange(jenis);
    final icon = _iconJenis(jenis);

    // Data foto jika sudah absen
    final key = jenis == 1
        ? 'pagi'
        : jenis == 2
            ? 'siang'
            : 'sore';
    final dataAbsen = _statusAbsensi?[key] as Map?;
    final waktu = dataAbsen?['waktu']?.toString();
    final fotoUrl = dataAbsen?['foto']?.toString();
    final lokasi = dataAbsen?['lokasi']?.toString();

    Color headerColor = switch (jenis) {
      1 => Colors.orange,
      2 => Colors.amber[700]!,
      3 => Colors.red[400]!,
      _ => Colors.grey,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: headerColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Absen $nama',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  jamRange,
                  style: TextStyle(
                      fontSize: 12, color: _teal, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: sudah
                ? _buildSudahAbsen(fotoUrl, waktu, lokasi)
                : _buildBelumAbsen(jenis, aktif, nama),
          ),
        ],
      ),
    );
  }

  Widget _buildSudahAbsen(String? fotoUrl, String? waktu, String? lokasi) {
    return Column(
      children: [
        // Foto
        if (fotoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              fotoUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.grey[100],
                child: const Icon(Icons.image_not_supported,
                    color: Colors.grey, size: 48),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Text(
              'Sudah absen${waktu != null ? ' · $waktu' : ''}',
              style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (lokasi != null && lokasi.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lokasi,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBelumAbsen(int jenis, bool aktif, String nama) {
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: aktif
                ? _teal.withOpacity(0.05)
                : Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                aktif ? Icons.camera_alt_outlined : Icons.lock_outline,
                color: aktif ? _teal : Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 6),
              Text(
                aktif
                    ? 'Tap tombol untuk absen $nama'
                    : _isLewat(jenis)
                        ? 'Waktu absen sudah lewat'
                        : 'Dibuka pukul ${_jamRange(jenis).split(' ')[0]}',
                style: TextStyle(
                  fontSize: 12,
                  color: aktif ? _teal : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        if (aktif) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _absen(jenis),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text('Absen $nama Sekarang',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _isLewat(int jenis) {
    final jam = _now.hour;
    return switch (jenis) {
      1 => jam >= 10,
      2 => jam >= 14,
      3 => jam >= 18,
      _ => false,
    };
  }
}
