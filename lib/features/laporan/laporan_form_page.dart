import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import '../absensi/absensi_foto_page.dart';

class LaporanFormPage extends StatefulWidget {
  const LaporanFormPage({super.key});

  @override
  State<LaporanFormPage> createState() => _LaporanFormPageState();
}

class _LaporanFormPageState extends State<LaporanFormPage>
    with SingleTickerProviderStateMixin {
  // ── Design tokens (sama dengan SkpPage) ──────────────────
  static const _teal      = AppColors.teal;
  static const _tealDark  = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg        = AppColors.bg;
  static const _textDark  = AppColors.textPrimary;
  // ─────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();

  List _kegiatanList      = [];
  List _kategoriList      = [];
  List _jenisEfisiensiAll = [];
  List _jenisHambatanAll  = [];
  bool _loadingForm       = true;

  DateTime _tanggal = DateTime.now();
  int?     _kegiatanId;

  final _alamatController     = TextEditingController();
  final _rtrwController       = TextEditingController();
  final _kelurahanController  = TextEditingController();
  final _kecamatanController  = TextEditingController();
  final _kabkotaController    = TextEditingController();
  final _linkOutputController = TextEditingController();
  List<TextEditingController> _uraianControllers = [TextEditingController()];

  List<_EHRow> _efisiensiRows = [];
  List<_EHRow> _hambatanRows  = [];

  File?   _fotoFile;
  String? _fotoBase64;
  File?   _dokumenFile;
  String? _dokumenBase64;
  String? _dokumenNama;

  bool _submitting = false;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  String get _hariLabel {
    const days = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    return days[_tanggal.weekday % 7];
  }

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
    _alamatController.dispose();
    _rtrwController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kabkotaController.dispose();
    _linkOutputController.dispose();
    for (final c in _uraianControllers) c.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────

  Future<void> _loadFormData() async {
    try {
      final res  = await ApiClient.get(ApiConfig.laporan + '/form-data');
      final data = res.data['data'];
      setState(() {
        _kegiatanList      = data['kegiatan']       ?? [];
        _kategoriList      = data['kategori']        ?? [];
        _jenisEfisiensiAll = data['jenis_efisiensi'] ?? [];
        _jenisHambatanAll  = data['jenis_hambatan']  ?? [];
        _loadingForm       = false;
      });
      _fadeController.forward(from: 0);
    } catch (_) {
      setState(() => _loadingForm = false);
      _showSnack('Gagal memuat data form.', isError: true);
    }
  }

  // ── Media pickers ─────────────────────────────────────────

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked == null) return;
    final file  = File(picked.path);
    final bytes = await file.readAsBytes();
    setState(() {
      _fotoFile   = file;
      _fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _pickDokumen() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null) return;
    final file  = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    setState(() {
      _dokumenFile   = file;
      _dokumenNama   = result.files.single.name;
      _dokumenBase64 = 'data:application/pdf;base64,${base64Encode(bytes)}';
    });
  }

  // ── Submit ────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kegiatanId == null) {
      _showSnack('Pilih jenis kegiatan terlebih dahulu.', isError: true);
      return;
    }

    final uraianList = _uraianControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (uraianList.isEmpty) {
      _showSnack('Isi minimal satu uraian kinerja.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = {
        'tanggal'        : DateFormat('yyyy-MM-dd').format(_tanggal),
        'hari'           : _hariLabel,
        'kegiatan_id'    : _kegiatanId,
        'uraian_kinerja' : uraianList,
        'alamat_jalan'   : _alamatController.text.trim(),
        'rtrw'           : _rtrwController.text.trim().isEmpty
            ? null : _rtrwController.text.trim(),
        'kelurahan_nama' : _kelurahanController.text.trim(),
        'kecamatan_nama' : _kecamatanController.text.trim(),
        'kabkota_nama'   : _kabkotaController.text.trim(),
        'link_output'    : _linkOutputController.text.trim().isEmpty
            ? null : _linkOutputController.text.trim(),
        if (_fotoBase64    != null) 'foto_output'    : _fotoBase64,
        if (_dokumenBase64 != null) 'dokumen_output' : _dokumenBase64,
        'efisiensi': _efisiensiRows
            .where((r) =>
                r.uraian.text.trim().isNotEmpty && r.kategoriId != null)
            .map((r) => {
                  'kategori_id': r.kategoriId,
                  'jenis_id'   : r.jenisId,
                  'uraian'     : r.uraian.text.trim(),
                })
            .toList(),
        'hambatan': _hambatanRows
            .where((r) =>
                r.uraian.text.trim().isNotEmpty && r.kategoriId != null)
            .map((r) => {
                  'kategori_id': r.kategoriId,
                  'jenis_id'   : r.jenisId,
                  'uraian'     : r.uraian.text.trim(),
                })
            .toList(),
      };

      final res = await ApiClient.post(ApiConfig.laporan, data: payload);
      if (res.data['success'] == true) {
        _showSnack(res.data['message'] ?? 'Laporan berhasil disubmit!');
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnack(res.data['message'] ?? 'Gagal menyimpan laporan.',
            isError: true);
      }
    } catch (_) {
      _showSnack('Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _teal,
    ));
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  // ── Build ─────────────────────────────────────────────────

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
                  'Kinerja Pegawai',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Form Laporan WFA',
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
                    color: _teal, strokeWidth: 2.5),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildAbsenBanner(),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.info_outline_rounded,
                        title: 'Informasi Dasar',
                        children: [
                          _buildTanggalPicker(),
                          const SizedBox(height: 12),
                          _buildReadonlyField(
                            'Hari',
                            _hariLabel,
                            Icons.calendar_today_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildKegiatanDropdown(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.edit_note_rounded,
                        title: 'Uraian Kinerja',
                        children: [
                          ..._uraianControllers
                              .asMap()
                              .entries
                              .map((e) => _buildUraianItem(e.key)),
                          const SizedBox(height: 4),
                          _buildAddButton(
                            label: 'Tambah Uraian',
                            onTap: () => setState(() => _uraianControllers
                                .add(TextEditingController())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.attach_file_rounded,
                        title: 'Output Kerja',
                        children: [
                          _buildFotoPicker(),
                          const SizedBox(height: 12),
                          _buildDokumenPicker(),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _linkOutputController,
                            label: 'Link Output (opsional)',
                            hint: 'https://drive.google.com/...',
                            icon: Icons.link_rounded,
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  !v.startsWith('http')) {
                                return 'Masukkan URL yang valid.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.location_on_rounded,
                        title: 'Alamat WFA',
                        children: [
                          _buildTextField(
                            controller: _alamatController,
                            label: 'Alamat Jalan',
                            hint: 'Jl. Merdeka No. 10',
                            icon: Icons.home_rounded,
                            required: true,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _rtrwController,
                            label: 'RT/RW (opsional)',
                            hint: '001/002',
                            icon: Icons.location_city_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildKelurahanKecamatanRow(context),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _kabkotaController,
                            label: 'Kab/Kota',
                            hint: 'Kota Bandung',
                            icon: Icons.map_rounded,
                            required: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.trending_up_rounded,
                        title: 'Efisiensi Kerja',
                        children: [
                          ..._efisiensiRows.asMap().entries.map((e) =>
                              _buildEHRow(e.key, _efisiensiRows,
                                  _jenisEfisiensiAll, 'Efisiensi')),
                          const SizedBox(height: 4),
                          _buildAddButton(
                            label: 'Tambah Efisiensi',
                            onTap: () =>
                                setState(() => _efisiensiRows.add(_EHRow())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        icon: Icons.warning_amber_rounded,
                        title: 'Hambatan Kerja',
                        children: [
                          ..._hambatanRows.asMap().entries.map((e) =>
                              _buildEHRow(e.key, _hambatanRows,
                                  _jenisHambatanAll, 'Hambatan')),
                          const SizedBox(height: 4),
                          _buildAddButton(
                            label: 'Tambah Hambatan',
                            onTap: () =>
                                setState(() => _hambatanRows.add(_EHRow())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _teal, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 20, color: Colors.grey[100]),
            ...children,
          ],
        ),
      ),
    );
  }

  // ── Absen banner ──────────────────────────────────────────

  Widget _buildAbsenBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _tealLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: _teal, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pastikan Anda sudah absen hari ini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AbsensiFotoPage()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_teal, _tealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Cek Absensi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tanggal picker ────────────────────────────────────────

  Widget _buildTanggalPicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _tanggal,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: _teal),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _tanggal = picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _bg,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _teal, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_tanggal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  // ── Readonly field ────────────────────────────────────────

  Widget _buildReadonlyField(String label, String value, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[400], size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Kegiatan dropdown ─────────────────────────────────────

  Widget _buildKegiatanDropdown() {
    return DropdownButtonFormField<int>(
      value: _kegiatanId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Jenis Kegiatan *',
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
        prefixIcon:
            const Icon(Icons.work_outline_rounded, size: 20),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
      hint: Text('Pilih kegiatan',
          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      items: _kegiatanList
          .map<DropdownMenuItem<int>>((k) => DropdownMenuItem(
                value: k['KegiatanId'] as int,
                child: Text(
                  k['Kegiatan']?.toString() ?? '',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _kegiatanId = v),
      validator: (v) => v == null ? 'Pilih jenis kegiatan.' : null,
    );
  }

  // ── Uraian item ───────────────────────────────────────────

  Widget _buildUraianItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _uraianControllers[index],
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                labelText: 'Uraian ${index + 1}',
                labelStyle:
                    TextStyle(fontSize: 13, color: Colors.grey[600]),
                hintText:
                    'Deskripsikan kegiatan yang dikerjakan...',
                hintStyle:
                    TextStyle(fontSize: 12, color: Colors.grey[400]),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _teal, width: 1.5),
                ),
              ),
              validator: index == 0
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Uraian kinerja wajib diisi.'
                      : null
                  : null,
            ),
          ),
          if (index > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _uraianControllers[index].dispose();
                _uraianControllers.removeAt(index);
              }),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Foto picker ───────────────────────────────────────────

  Widget _buildFotoPicker() {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxWidth < 400 ? 140.0 : 180.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto Output (opsional)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickFoto,
            child: Container(
              height: _fotoFile != null ? height : 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _fotoFile != null ? Colors.transparent : _bg,
                border: Border.all(
                  color: _fotoFile != null
                      ? _teal
                      : Colors.grey.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _fotoFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _fotoFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: height,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _fotoFile   = null;
                              _fotoBase64 = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pilih foto dari galeri',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    });
  }

  // ── Dokumen picker ────────────────────────────────────────

  Widget _buildDokumenPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dokumen Output (PDF/DOC, opsional)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDokumen,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _dokumenFile != null
                  ? _teal.withOpacity(0.05)
                  : _bg,
              border: Border.all(
                color: _dokumenFile != null
                    ? _teal
                    : Colors.grey.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _dokumenFile != null
                        ? _tealLight
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _dokumenFile != null
                        ? Icons.description_rounded
                        : Icons.upload_file_outlined,
                    color: _dokumenFile != null
                        ? _teal
                        : Colors.grey[400],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dokumenFile != null
                        ? _dokumenNama ?? 'Dokumen dipilih'
                        : 'Pilih file PDF atau DOC',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _dokumenFile != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _dokumenFile != null
                          ? _teal
                          : Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_dokumenFile != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _dokumenFile   = null;
                      _dokumenBase64 = null;
                      _dokumenNama   = null;
                    }),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.red, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Kelurahan + Kecamatan row ─────────────────────────────

  Widget _buildKelurahanKecamatanRow(BuildContext context) {
    if (_isWide(context)) {
      return Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _kelurahanController,
              label: 'Kelurahan',
              icon: Icons.apartment_rounded,
              required: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTextField(
              controller: _kecamatanController,
              label: 'Kecamatan',
              icon: Icons.map_rounded,
              required: true,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildTextField(
          controller: _kelurahanController,
          label: 'Kelurahan',
          icon: Icons.apartment_rounded,
          required: true,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _kecamatanController,
          label: 'Kecamatan',
          icon: Icons.map_rounded,
          required: true,
        ),
      ],
    );
  }

  // ── Generic text field ────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13, color: _textDark),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '$label wajib diisi.'
                  : null
              : null),
    );
  }

  // ── EH row ────────────────────────────────────────────────

  Widget _buildEHRow(
    int index,
    List<_EHRow> rows,
    List jenisList,
    String label,
  ) {
    final row = rows[index];
    final filteredJenis = row.kategoriId == null
        ? <dynamic>[]
        : jenisList
            .where((j) =>
                int.tryParse(j['KategoriId'].toString()) ==
                row.kategoriId)
            .toList();

    InputDecoration innerDeco(String lbl) => InputDecoration(
          labelText: lbl,
          labelStyle:
              TextStyle(fontSize: 12, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _tealLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _teal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => rows.removeAt(index)),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: row.kategoriId,
            isExpanded: true,
            decoration: innerDeco('Kategori'),
            hint: Text('Pilih kategori',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[400])),
            items: _kategoriList
                .map<DropdownMenuItem<int>>((k) => DropdownMenuItem(
                      value: k['KategoriId'] as int,
                      child: Text(
                        k['Kategori']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              row.kategoriId = v;
              row.jenisId    = null;
            }),
          ),
          if (filteredJenis.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: row.jenisId,
              isExpanded: true,
              decoration: innerDeco('Jenis $label'),
              hint: Text('Pilih jenis $label',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[400])),
              items: filteredJenis.map<DropdownMenuItem<int>>((j) {
                final idKey = label == 'Efisiensi'
                    ? 'JenisEfisiensiId'
                    : 'JenisHambatanId';
                final nameKey = label == 'Efisiensi'
                    ? 'JenisEfisiensi'
                    : 'JenisHambatan';
                return DropdownMenuItem(
                  value: j[idKey] as int,
                  child: Text(
                    j[nameKey]?.toString() ?? '',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => row.jenisId = v),
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: row.uraian,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: _textDark),
            decoration: innerDeco('Uraian $label'),
          ),
        ],
      ),
    );
  }

  // ── Add button ────────────────────────────────────────────

  Widget _buildAddButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _tealLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _teal.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: _teal, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: _submitting
              ? null
              : const LinearGradient(
                  colors: [_teal, _tealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _submitting ? Colors.grey[300] : null,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_submitting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            else
              const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              _submitting ? 'Menyimpan...' : 'Submit Laporan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color:
                    _submitting ? Colors.grey[500] : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────

class _EHRow {
  int? kategoriId;
  int? jenisId;
  final TextEditingController uraian = TextEditingController();
}