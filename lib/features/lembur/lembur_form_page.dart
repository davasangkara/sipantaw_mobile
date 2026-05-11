import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';

class LemburFormPage extends StatefulWidget {
  const LemburFormPage({super.key});

  @override
  State<LemburFormPage> createState() => _LemburFormPageState();
}

class _LemburFormPageState extends State<LemburFormPage> {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  bool _submitting = false;
  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  final _keteranganController = TextEditingController();

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _tanggal = date);
  }

  Future<void> _pickJam(bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMulai
          ? (_jamMulai ?? const TimeOfDay(hour: 17, minute: 0))
          : (_jamSelesai ?? const TimeOfDay(hour: 19, minute: 0)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isMulai) {
        _jamMulai = picked;
      } else {
        _jamSelesai = picked;
      }
    });
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  double _hitungDurasi() {
    if (_jamMulai == null || _jamSelesai == null) return 0;
    final mulai = _jamMulai!.hour * 60 + _jamMulai!.minute;
    final selesai = _jamSelesai!.hour * 60 + _jamSelesai!.minute;
    if (selesai <= mulai) return 0;
    return (selesai - mulai) / 60;
  }

  Future<void> _submit() async {
    if (_tanggal == null) {
      _showSnack('Pilih tanggal lembur.', isError: true);
      return;
    }
    if (_jamMulai == null) {
      _showSnack('Pilih jam mulai.', isError: true);
      return;
    }
    if (_jamSelesai == null) {
      _showSnack('Pilih jam selesai.', isError: true);
      return;
    }
    if (_hitungDurasi() <= 0) {
      _showSnack('Jam selesai harus setelah jam mulai.', isError: true);
      return;
    }
    if (_keteranganController.text.trim().isEmpty) {
      _showSnack('Keterangan wajib diisi.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient.post(ApiConfig.lembur, data: {
        'tanggal': _tanggal!.toIso8601String().substring(0, 10),
        'jam_mulai': _formatTime(_jamMulai!),
        'jam_selesai': _formatTime(_jamSelesai!),
        'keterangan': _keteranganController.text.trim(),
      });
      if (mounted) {
        _showSnack('Pengajuan lembur berhasil dikirim!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('Gagal mengajukan lembur.', isError: true);
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _teal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final durasi = _hitungDurasi();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                  'Pengajuan',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Ajukan Lembur',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Tanggal Lembur'),
                    _datePickerField(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Waktu Lembur'),
                    Row(
                      children: [
                        Expanded(
                          child: _timePickerField(
                            label: 'Jam Mulai',
                            time: _jamMulai,
                            onTap: () => _pickJam(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _timePickerField(
                            label: 'Jam Selesai',
                            time: _jamSelesai,
                            onTap: () => _pickJam(false),
                          ),
                        ),
                      ],
                    ),
                    if (durasi > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _tealLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 15, color: _teal),
                            const SizedBox(width: 8),
                            Text(
                              'Estimasi durasi: ${durasi.toStringAsFixed(1)} jam',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Keterangan'),
                    TextField(
                      controller: _keteranganController,
                      maxLines: 4,
                      style: const TextStyle(
                          fontSize: 13, color: _textDark),
                      decoration: _inputDeco(
                          'Uraikan pekerjaan yang dilakukan saat lembur...'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: _submitting
                          ? null
                          : const LinearGradient(
                              colors: [_teal, _tealDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color:
                          _submitting ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _submitting
                          ? []
                          : [
                              BoxShadow(
                                color: _teal.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kirim Pengajuan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      );

  Widget _datePickerField() => GestureDetector(
        onTap: _pickTanggal,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: _teal),
              const SizedBox(width: 10),
              Text(
                _tanggal != null
                    ? '${_tanggal!.day.toString().padLeft(2, '0')}/${_tanggal!.month.toString().padLeft(2, '0')}/${_tanggal!.year}'
                    : 'Pilih tanggal',
                style: TextStyle(
                  fontSize: 13,
                  color: _tanggal != null
                      ? _textDark
                      : Colors.grey[400],
                  fontWeight: _tanggal != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _timePickerField({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: _teal),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  time != null ? _formatTime(time) : label,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        time != null ? _textDark : Colors.grey[400],
                    fontWeight: time != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
        filled: true,
        fillColor: _bg,
      );
}