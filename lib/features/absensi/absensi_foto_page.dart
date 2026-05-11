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
        child: CircularProgressIndicator(color: AppColors.black),
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
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
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
          backgroundColor: AppColors.black,
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
    const timezone = 'WIB (UTC+7)';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.xs,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.textPrimary),
            ),
          ),
        ),
        leadingWidth: 64,
        title: const Text(
          'Absensi WFA',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  jamSekarang,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  timezone,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.black))
          : RefreshIndicator(
              color: AppColors.black,
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Info banner — premium style
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Setiap sesi absen dibuka sesuai jam aktif. '
                              'Sesi yang sudah lewat waktunya akan terkunci otomatis. '
                              'Foto otomatis diberi watermark waktu & lokasi.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
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
                        color: AppColors.black,
                      ),
                      label: const Text(
                        'Absensi Jika Tidak Melakukan WFA',
                        style: TextStyle(color: AppColors.black),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.black),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
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

    // Pertahankan warna semantik per jenis (orange/amber/red)
    Color headerColor = switch (jenis) {
      1 => Colors.orange,
      2 => Colors.amber[700]!,
      3 => Colors.red[400]!,
      _ => Colors.grey,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: headerColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Absen $nama',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  jamRange,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

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
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fotoUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.textMuted, size: 48),
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
              const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lokasi,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                aktif ? Icons.camera_alt_outlined : Icons.lock_outline,
                color: aktif ? AppColors.black : AppColors.textMuted,
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
                  color: aktif ? AppColors.textPrimary : AppColors.textMuted,
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
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
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
