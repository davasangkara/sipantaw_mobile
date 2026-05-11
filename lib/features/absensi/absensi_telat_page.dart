import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Tampilkan mood picker, lalu face verification, lalu kirim API
  Future<void> _absenTelat(int jenis) async {
    // Step 1: Pilih mood
    final mood = await _showMoodPicker(jenis);
    if (mood == null || !mounted) return;

    // Step 2: Verifikasi wajah
    final result = await Navigator.push<FaceVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceVerificationPage(
          title: 'Verifikasi Absen Telat',
          subtitle: 'Posisikan wajah untuk absen ${_namaJenis(jenis)}',
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

    // Step 3: Kirim ke API
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
          'mood': mood.value,
          'mood_label': mood.label,
          'alasan_telat': 'Absen di luar jam aktif',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      if (res.data['success'] == true) {
        _showSuccessSheet(mood, _namaJenis(jenis));
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

  /// Bottom sheet pilih mood
  Future<_MoodData?> _showMoodPicker(int jenis) {
    return showModalBottomSheet<_MoodData>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MoodPickerSheet(namaJenis: _namaJenis(jenis)),
    );
  }

  /// Bottom sheet sukses
  void _showSuccessSheet(_MoodData mood, String namaJenis) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessSheet(mood: mood, namaJenis: namaJenis),
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
                  'Absen telat akan dicatat beserta mood Anda dan memerlukan verifikasi wajah.',
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
            icon: Icons.emoji_emotions_rounded,
            label: 'Rating Mood',
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
                fontSize: 12,
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

// ── Mood data ─────────────────────────────────────────────────
class _MoodData {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _MoodData({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });
}

const _moods = [
  _MoodData(
    emoji: '😄',
    label: 'Sangat Senang',
    value: 'very_happy',
    color: Color(0xFF34C759),
    bg: Color(0xFFE8F8EE),
  ),
  _MoodData(
    emoji: '🙂',
    label: 'Baik',
    value: 'good',
    color: Color(0xFF007AFF),
    bg: Color(0xFFE5F1FF),
  ),
  _MoodData(
    emoji: '😐',
    label: 'Biasa',
    value: 'neutral',
    color: Color(0xFFFF9500),
    bg: Color(0xFFFFF3E0),
  ),
  _MoodData(
    emoji: '😔',
    label: 'Tidak Happy',
    value: 'unhappy',
    color: Color(0xFFFF3B30),
    bg: Color(0xFFFFECEB),
  ),
];

// ── Mood picker sheet ─────────────────────────────────────────
class _MoodPickerSheet extends StatefulWidget {
  final String namaJenis;
  const _MoodPickerSheet({required this.namaJenis});

  @override
  State<_MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<_MoodPickerSheet> {
  _MoodData? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
          const SizedBox(height: 24),

          // Title
          Text(
            'Bagaimana perasaan Anda\npagi ini?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Absen ${widget.namaJenis} · ${DateFormat('HH:mm').format(DateTime.now())}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          // Mood grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _moods.map((mood) {
              final isSelected = _selected?.value == mood.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = mood);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? mood.bg : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? mood.color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: mood.color.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mood.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? mood.color : AppColors.textMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Tombol lanjut
          PremiumButton(
            label: _selected == null
                ? 'Pilih mood terlebih dahulu'
                : 'Lanjut Verifikasi Wajah',
            onTap: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Success sheet ─────────────────────────────────────────────
class _SuccessSheet extends StatelessWidget {
  final _MoodData mood;
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

          const SizedBox(height: 20),

          // Mood recap
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mood.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: mood.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mood hari ini',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: mood.color,
                      ),
                    ),
                  ],
                ),
              ],
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
