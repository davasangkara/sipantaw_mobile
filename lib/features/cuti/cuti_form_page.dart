import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';

class CutiFormPage extends StatefulWidget {
  const CutiFormPage({super.key});

  @override
  State<CutiFormPage> createState() => _CutiFormPageState();
}

class _CutiFormPageState extends State<CutiFormPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _jenisCutiList = [];
  List _pejabatList = [];
  bool _loadingForm = true;
  bool _submitting = false;
  String? _error;

  int? _selectedJenisCuti;
  int? _selectedPejabat;
  bool _perluDokumen = false;
  List<Map<String, dynamic>> _dokumenList = [];
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final _keteranganController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadFormData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      final res = await ApiClient.get('${ApiConfig.cuti}/form-data');
      setState(() {
        _jenisCutiList = res.data['data']['jenis_cuti'] ?? [];
        _pejabatList = res.data['data']['pejabat'] ?? [];
        _loadingForm = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loadingForm = false;
        _error = 'Gagal memuat form.';
      });
    }
  }

  Future<void> _pickDate(bool isMulai) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isMulai
          ? (_tanggalMulai ?? now)
          : (_tanggalSelesai ?? _tanggalMulai ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    setState(() {
      if (isMulai) {
        _tanggalMulai = date;
        if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(date)) {
          _tanggalSelesai = date;
        }
      } else {
        _tanggalSelesai = date;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedJenisCuti == null) {
      _showSnack('Pilih jenis cuti terlebih dahulu.', isError: true);
      return;
    }
    if (_selectedPejabat == null) {
      _showSnack('Pilih pejabat penyetuju.', isError: true);
      return;
    }
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      _showSnack('Pilih tanggal mulai dan selesai.', isError: true);
      return;
    }
    if (_perluDokumen && _dokumenList.isEmpty) {
      _showSnack('Dokumen pendukung wajib dilampirkan.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient.post(ApiConfig.cuti, data: {
        'IdJenisCuti': _selectedJenisCuti,
        'PejabatId': _selectedPejabat,
        'TanggalMulai': _tanggalMulai!.toIso8601String().substring(0, 10),
        'TanggalSelesai': _tanggalSelesai!.toIso8601String().substring(0, 10),
        'Keterangan': _keteranganController.text,
        'Dokumen': _dokumenList,
      });

      if (mounted) {
        _showSnack('Pengajuan cuti berhasil dikirim!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('Gagal mengajukan cuti.', isError: true);
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red : _teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _pickDokumen() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.bytes == null) continue;
        _dokumenList.add({
          'data':
              'data:${_mimeFromExt(f.extension!)};base64,${base64Encode(f.bytes!)}',
          'nama_file': f.name,
          'mime_type': _mimeFromExt(f.extension!),
        });
      }
    });
  }

  String _mimeFromExt(String ext) => switch (ext.toLowerCase()) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'application/octet-stream',
      };

  int get _estimasiHari =>
      (_tanggalMulai != null && _tanggalSelesai != null)
          ? _tanggalSelesai!.difference(_tanggalMulai!).inDays + 1
          : 0;

  @override
  Widget build(BuildContext context) {
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
                  'Form',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Ajukan Cuti',
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
        body: _loadingForm
            ? const Center(
                child: CircularProgressIndicator(
                  color: _teal,
                  strokeWidth: 2.5,
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline_rounded,
                                size: 32, color: Colors.red[400]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadFormData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Coba Lagi',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            icon: Icons.luggage_rounded,
                            title: 'Informasi Cuti',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Jenis Cuti', required: true),
                                _styledDropdown<int>(
                                  value: _selectedJenisCuti,
                                  hint: 'Pilih jenis cuti',
                                  items: _jenisCutiList
                                      .map((j) => DropdownMenuItem<int>(
                                            value: int.parse(
                                                j['id'].toString()),
                                            child: Text(
                                              '${j['nama']} (${j['kuota_hari']} hari)',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    final jenis = _jenisCutiList.firstWhere(
                                        (j) =>
                                            int.parse(j['id'].toString()) ==
                                            val);
                                    setState(() {
                                      _selectedJenisCuti = val;
                                      _perluDokumen =
                                          jenis['perlu_dokumen'] == true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _fieldLabel('Pejabat Penyetuju',
                                    required: true),
                                _styledDropdown<int>(
                                  value: _selectedPejabat,
                                  hint: 'Pilih pejabat',
                                  items: _pejabatList
                                      .map((p) => DropdownMenuItem<int>(
                                            value: int.parse(
                                                p['PejabatId'].toString()),
                                            child: Text(
                                              p['Nama']?.toString() ?? '-',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedPejabat = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _sectionCard(
                            icon: Icons.date_range_rounded,
                            title: 'Periode Cuti',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Tanggal Mulai', required: true),
                                _datePicker(
                                  label: 'Pilih tanggal mulai',
                                  date: _tanggalMulai,
                                  onTap: () => _pickDate(true),
                                ),
                                const SizedBox(height: 14),
                                _fieldLabel('Tanggal Selesai', required: true),
                                _datePicker(
                                  label: 'Pilih tanggal selesai',
                                  date: _tanggalSelesai,
                                  onTap: () => _pickDate(false),
                                ),
                                if (_tanggalMulai != null &&
                                    _tanggalSelesai != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: _tealLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_rounded,
                                            size: 15, color: _teal),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Estimasi: $_estimasiHari hari kalender',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _teal,
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
                          _sectionCard(
                            icon: Icons.edit_note_rounded,
                            title: 'Keterangan',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Alasan Pengajuan'),
                                TextField(
                                  controller: _keteranganController,
                                  maxLines: 4,
                                  style: const TextStyle(
                                      fontSize: 13, color: _textDark),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tuliskan alasan pengajuan cuti...',
                                    hintStyle: TextStyle(
                                        color: Colors.grey[400], fontSize: 13),
                                    contentPadding: const EdgeInsets.all(14),
                                    filled: true,
                                    fillColor: _bg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: _teal, width: 1.5),
                                    ),
                                  ),
                                ),
                                if (_perluDokumen) ...[
                                  const SizedBox(height: 16),
                                  _fieldLabel('Dokumen Pendukung',
                                      required: true),
                                  GestureDetector(
                                    onTap: _pickDokumen,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _tealLight,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _teal.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.upload_file_rounded,
                                              color: _teal, size: 26),
                                          const SizedBox(height: 6),
                                          Text(
                                            _dokumenList.isEmpty
                                                ? 'Ketuk untuk melampirkan dokumen'
                                                : '${_dokumenList.length} file terpilih',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _teal,
                                            ),
                                          ),
                                          Text(
                                            'PDF, JPG, PNG',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[400]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_dokumenList.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ..._dokumenList.map((d) => Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 6),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _bg,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons
                                                      .insert_drive_file_rounded,
                                                  size: 16,
                                                  color: _teal),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  d['nama_file'],
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => setState(
                                                    () => _dokumenList
                                                        .remove(d)),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                      Icons.close_rounded,
                                                      size: 12,
                                                      color: Colors.red[400]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _teal,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _teal.withOpacity(0.5),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Kirim Pengajuan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _teal, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red),
              ),
          ],
        ),
      );

  Widget _styledDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
        hint: Text(hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
      );

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: date != null
                ? Border.all(color: _teal.withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: date != null ? _teal : Colors.grey[400],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date != null
                      ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                      : label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: date != null
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: date != null ? _textDark : Colors.grey[400],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      );
}