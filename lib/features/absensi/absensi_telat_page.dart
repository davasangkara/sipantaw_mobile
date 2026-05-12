import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'face_verification_page.dart';

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
    } catch (_) {
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
        3 => Colors.deepPurple[400]!,
        _ => Colors.grey,
      };

  /// Absen telat — langsung ke face verification, mood terdeteksi otomatis
  Future<void> _absenTelat(int jenis) async {
    // Face verification (sekaligus deteksi mood otomatis)
    final result = await Navigator.push<FaceVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceVerificationPage(
          title: 'Absen ${_namaJenis(jenis)}',
          subtitle: 'Posisikan wajah Anda di dalam lingkaran',
        ),
      ),
    );

    if (!mounted) return;
    if (result == null || !result.success || result.fotoBase64 == null) {
      if (result != null && !result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi wajah dibatalkan.'),
            backgroundColor: AppColors.black,
          ),
        );
      }
      return;
    }

    final mood = result.mood;

    // Kirim ke API
    setState(() => _submitting = true);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      String lokasi = 'Lokasi tidak tersedia';
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(const Duration(seconds: 6));
          lokasi = '${pos.latitude}, ${pos.longitude}';
        }
      } catch (_) {}

      final today = DateFormat('yyyy-MM-dd').format(_now);

      final res = await ApiClient.post(
        '${ApiConfig.laporan}/absensi',
        data: {
          'jenis': jenis,
          'foto_data': result.fotoBase64,
          'lokasi': lokasi,
          'tanggal': today,
          'timezone_name': 'Asia/Jakarta',
          'is_telat': true,
          if (mood != null) 'mood': mood.value,
          if (mood != null) 'mood_label': mood.label,
          if (mood != null) 'mood_score': mood.smileScore.toStringAsFixed(2),
          'alasan_telat': 'Absen di luar jam aktif',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      if (res.data['success'] == true) {
        // Tampilkan success sheet dengan mood hasil deteksi
        if (mood != null) {
          _showSuccessSheet(mood, _namaJenis(jenis));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.data['message'] ?? 'Absen berhasil!'),
            backgroundColor: AppColors.black,
          ));
        }
        _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.data['message'] ?? 'Gagal absen.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessSheet(DetectedMood mood, String namaJenis) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuccessSheet(mood: mood, namaJenis: namaJenis),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWarningBanner()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .moveY(begin: 8, end: 0, duration: 400.ms),
                      const SizedBox(height: 16),
                      _buildInfoRow()
                          .animate(delay: 80.ms)
                          .fadeIn(duration: 400.ms)
                          .moveY(begin: 8, end: 0, duration: 400.ms),
                      const SizedBox(height: 24),
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
                      ...[1, 2, 3].asMap().entries.map((e) {
                        return _buildSesiCard(e.value)
                            .animate(delay: (100 + 80 * e.key).ms)
                            .fadeIn(duration: 400.ms)
                            .moveY(
                                begin: 14,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alarm_rounded,
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
                SizedBox(height: 3),
                Text(
                  'Absen telat akan dicatat. Mood Anda terdeteksi otomatis saat verifikasi wajah.',
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

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.face_rounded,
            label: 'Verifikasi Wajah',
            color: AppColors.black,
            iconColor: AppColors.softLime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoChip(
            icon: Icons.auto_awesome_rounded,
            label: 'Deteksi Mood Otomatis',
            color: const Color(0xFF7C3AED),
            iconColor: Colors.white,
          ),
        ),
      ],
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.face_rounded,
                          size: 14, color: AppColors.softLime),
                      SizedBox(width: 6),
                      Text(
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

// ── Info chip ─────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success sheet — recap hasil absen + mood terdeteksi ───────
class _SuccessSheet extends StatelessWidget {
  final DetectedMood mood;
  final String namaJenis;

  const _SuccessSheet({required this.mood, required this.namaJenis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF34C759), size: 44),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          const Text(
            'Absen Berhasil!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Absen $namaJenis telah dicatat',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Mood detection card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: mood.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: mood.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: mood.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 11, color: mood.color),
                          const SizedBox(width: 4),
                          Text(
                            'MOOD TERDETEKSI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: mood.color,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(mood.emoji,
                        style: const TextStyle(fontSize: 56))
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                      delay: 200.ms,
                    ),
                const SizedBox(height: 10),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: mood.color,
                    letterSpacing: -0.3,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .moveY(begin: 6, end: 0, duration: 400.ms),
                const SizedBox(height: 12),
                // Confidence bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Confidence',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: mood.color.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            '${(mood.smileScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: mood.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: mood.smileScore.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: mood.color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(mood.color),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info text
          const Text(
            'Mood terdeteksi otomatis dari ekspresi wajah Anda saat verifikasi. '
            'Data ini membantu HR memantau kesejahteraan pegawai.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          PremiumButton(
            label: 'Selesai',
            onTap: () => Navigator.pop(context),
          ),
        ],
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
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
