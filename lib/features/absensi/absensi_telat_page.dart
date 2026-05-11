import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'face_verification_page.dart';

/// Halaman absensi telat — untuk absen di luar jam aktif.
/// Menggunakan verifikasi wajah sebagai pengganti foto biasa.
class AbsensiTelatPage extends StatefulWidget {
  const AbsensiTelatPage({super.key});

  @override
  State<AbsensiTelatPage> createState() => _AbsensiTelatPageState();
}

class _AbsensiTelatPageState extends State<AbsensiTelatPage> {
  bool _loading = true;
  Map<String, dynamic>? _statusAbsensi;
  final _now = DateTime.now();
  bool _submitting = false;

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

  bool _sudahAbsen(int jenis) {
    if (_statusAbsensi == null) return false;
    final key = jenis == 1 ? 'pagi' : jenis == 2 ? 'siang' : 'sore';
    return _statusAbsensi![key]?['sudah'] == true;
  }

  String _namaJenis(int jenis) => switch (jenis) {
        1 => 'Pagi',
        2 => 'Siang',
        3 => 'Sore',
        _ => '',
      };

  String _jamRange(int jenis) => switch (jenis) {
        1 => '07.30 – 09.00',
        2 => '11.00 – 13.00',
        3 => '15.00 – 17.00',
        _ => '',
      };

  IconData _iconJenis(int jenis) => switch (jenis) {
        1 => Icons.wb_twilight_rounded,
        2 => Icons.wb_sunny_rounded,
        3 => Icons.nights_stay_rounded,
        _ => Icons.access_time_rounded,
      };

  Color _colorJenis(int jenis) => switch (jenis) {
        1 => Colors.orange,
        2 => Colors.amber[700]!,
        3 => Colors.red[400]!,
        _ => Colors.grey,
      };

  /// Absen telat — buka face verification dulu, lalu kirim ke API
  Future<void> _absenTelat(int jenis) async {
    // Buka halaman verifikasi wajah
    final result = await Navigator.push<FaceVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceVerificationPage(
          title: 'Verifikasi Absen Telat',
          subtitle: 'Posisikan wajah Anda untuk absen ${_namaJenis(jenis)}',
        ),
      ),
    );

    if (result == null || !result.success || result.fotoBase64 == null) {
      if (mounted && result != null && !result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi wajah dibatalkan.'),
            backgroundColor: AppColors.black,
          ),
        );
      }
      return;
    }

    setState(() => _submitting = true);

    // Tampilkan loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
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

      final today = DateFormat('yyyy-MM-dd').format(_now);

      // Kirim ke API dengan flag telat
      final res = await ApiClient.post(
        '${ApiConfig.laporan}/absensi',
        data: {
          'jenis': jenis,
          'foto_data': result.fotoBase64,
          'lokasi': lokasi,
          'tanggal': today,
          'timezone_name': 'Asia/Jakarta',
          'is_telat': true, // flag absen telat
          'alasan_telat': 'Absen di luar jam aktif melalui fitur Absen Telat',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.data['message'] ?? 'Absen telat berhasil!'),
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.canvas,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 72,
            titleSpacing: 20,
            leading: Padding(
              padding: const EdgeInsets.all(14),
              child: PressableScale(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadows.xs,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kehadiran',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Absen Telat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.black))
            : RefreshIndicator(
                color: AppColors.black,
                onRefresh: _loadStatus,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning banner
                      _buildWarningBanner(),
                      const SizedBox(height: 20),

                      // Face ID info card
                      _buildFaceIdInfoCard(),
                      const SizedBox(height: 20),

                      const Text(
                        'Pilih Sesi Absen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3 sesi absen
                      ...[1, 2, 3].asMap().entries.map((entry) {
                        final i = entry.key;
                        final jenis = entry.value;
                        return _buildSesiCard(jenis)
                            .animate(delay: (80 * i).ms)
                            .fadeIn(duration: 400.ms)
                            .moveY(
                                begin: 12,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic);
                      }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFF8B6914), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Absen di Luar Jam Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B6914),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fitur ini untuk absen yang melewati jam aktif. '
                  'Absen telat akan dicatat dan memerlukan verifikasi wajah.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceIdInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.softLime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.face_rounded,
                color: AppColors.black, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi Wajah Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kamera akan mendeteksi & memverifikasi wajah Anda secara real-time',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesiCard(int jenis) {
    final sudah = _sudahAbsen(jenis);
    final nama = _namaJenis(jenis);
    final jamRange = _jamRange(jenis);
    final icon = _iconJenis(jenis);
    final color = _colorJenis(jenis);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon sesi
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Absen $nama',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        jamRange,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Status / tombol
            if (sudah)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF4CAF8C)),
                    SizedBox(width: 5),
                    Text(
                      'Sudah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF8C),
                      ),
                    ),
                  ],
                ),
              )
            else
              PressableScale(
                onTap: _submitting ? () {} : () => _absenTelat(jenis),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.face_rounded,
                          size: 14, color: AppColors.softLime),
                      const SizedBox(width: 6),
                      const Text(
                        'Absen',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Loading dialog ────────────────────────────────────────────
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memproses absensi...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mohon tunggu sebentar',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
