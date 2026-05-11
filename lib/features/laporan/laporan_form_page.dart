import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import '../../core/storage/token_storage.dart';
import '../../core/services/ai_laporan_service.dart';
import '../../core/services/location_service.dart';
import '../absensi/absensi_foto_page.dart';

class LaporanFormPage extends StatefulWidget {
  const LaporanFormPage({super.key});

  @override
  State<LaporanFormPage> createState() => _LaporanFormPageState();
}

class _LaporanFormPageState extends State<LaporanFormPage>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────
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
  bool _aiGenerating = false; // state AI loading
  String? _aiLocationStatus;  // status deteksi lokasi untuk UI

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

  // ── AI Generate ───────────────────────────────────────────

  Future<void> _generateWithAI() async {
    if (_kegiatanId == null) {
      _showSnack('Pilih jenis kegiatan terlebih dahulu.', isError: true);
      return;
    }

    setState(() {
      _aiGenerating = true;
      _aiLocationStatus = 'Mendeteksi lokasi...';
    });

    try {
      // ── Step 1: Deteksi lokasi GPS + reverse geocode ──────
      LocationAddress? location;
      try {
        location = await LocationService.getAddressFromCurrentLocation();
        if (mounted) {
          setState(() => _aiLocationStatus =
              location != null ? 'Lokasi ditemukan ✓' : 'Mengisi form...');
        }
      } catch (_) {
        if (mounted) setState(() => _aiLocationStatus = 'Mengisi form...');
      }

      // ── Step 2: Isi field alamat dari GPS (dalam setState agar UI update) ──
      if (location != null && mounted) {
        setState(() {
          if (location!.alamatJalan.isNotEmpty) {
            _alamatController.text = location.alamatJalan;
          }
          // rtrw dikosongkan karena Nominatim tidak menyediakan RT/RW
          if (location.kelurahan.isNotEmpty) {
            _kelurahanController.text = location.kelurahan;
          }
          if (location.kecamatan.isNotEmpty) {
            _kecamatanController.text = location.kecamatan;
          }
          if (location.kabkota.isNotEmpty) {
            _kabkotaController.text = location.kabkota;
          }
        });
      }

      // ── Step 3: Ambil data pegawai ────────────────────────
      if (mounted) setState(() => _aiLocationStatus = 'Membuat laporan...');

      final pegawai = await TokenStorage.getPegawai();
      final jabatan = pegawai['jabatan'] ?? 'Pegawai';
      final unit = pegawai['unit'] ?? 'Unit Kerja';
      final kegiatanNama = _kegiatanList
          .firstWhere(
            (k) => k['KegiatanId'] == _kegiatanId,
            orElse: () => {'Kegiatan': 'Kegiatan WFA'},
          )['Kegiatan']
          ?.toString() ?? 'Kegiatan WFA';

      // ── Step 4: Generate AI ───────────────────────────────
      final result = await AiLaporanService.generateLaporan(
        namaKegiatan: kegiatanNama,
        jabatan: jabatan,
        unit: unit,
        tanggal: DateFormat('d MMMM yyyy', 'id_ID').format(_tanggal),
        hari: _hariLabel,
        alamat: location?.alamatJalan.isNotEmpty == true
            ? location!.alamatJalan
            : _alamatController.text.trim().isEmpty
                ? null
                : _alamatController.text.trim(),
        kota: location?.kabkota.isNotEmpty == true
            ? location!.kabkota
            : _kabkotaController.text.trim().isEmpty
                ? null
                : _kabkotaController.text.trim(),
      );

      // ── Step 5: Isi semua field form dalam satu setState ──
      if (!mounted) return;
      setState(() {
        // Uraian kinerja
        for (final c in _uraianControllers) {
          c.dispose();
        }
        _uraianControllers = result.uraianKinerja
            .map((u) => TextEditingController(text: u))
            .toList();
        if (_uraianControllers.isEmpty) {
          _uraianControllers = [TextEditingController()];
        }

        // Efisiensi
        _efisiensiRows = result.efisiensi.map((e) {
          final row = _EHRow();
          if (_kategoriList.isNotEmpty) {
            row.kategoriId = _kategoriList.first['KategoriId'] as int?;
          }
          row.uraian.text = e.uraian;
          return row;
        }).toList();

        // Hambatan
        _hambatanRows = result.hambatan.map((h) {
          final row = _EHRow();
          if (_kategoriList.isNotEmpty) {
            row.kategoriId = _kategoriList.first['KategoriId'] as int?;
          }
          row.uraian.text = h.uraian;
          return row;
        }).toList();

        // Link output
        if (result.linkOutput != null && result.linkOutput!.isNotEmpty) {
          _linkOutputController.text = result.linkOutput!;
        }

        _aiLocationStatus = null;
        _aiGenerating = false;
      });

      final locMsg = location != null && location.kabkota.isNotEmpty
          ? ' · ${location.kabkota}'
          : '';
      _showSnack('Laporan digenerate AI ✨$locMsg');
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiLocationStatus = null;
          _aiGenerating = false;
        });
        _showSnack('Gagal generate AI. Coba lagi.', isError: true);
      }
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
      backgroundColor: isError ? Colors.red : AppColors.black,
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
                    color: AppColors.black, strokeWidth: 2.5),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildAiBanner(),
                      const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.sm,
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
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.textPrimary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.border),
            ...children,
          ],
        ),
      ),
    );
  }

  // ── AI Banner ─────────────────────────────────────────────

  Widget _buildAiBanner() {
    return _AiBannerWidget(
      generating: _aiGenerating,
      locationStatus: _aiLocationStatus,
      onTap: _aiGenerating ? null : _generateWithAI,
    );
  }

  // ── Absen banner ──────────────────────────────────────────

  Widget _buildAbsenBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pastikan Anda sudah absen hari ini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.pill),
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
              colorScheme: const ColorScheme.light(primary: AppColors.black),
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
          color: AppColors.surfaceMuted,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: AppColors.textPrimary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_tanggal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppColors.textMuted, size: 22),
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
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon:
            const Icon(Icons.work_outline_rounded, size: 20),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
        ),
      ),
      hint: const Text('Pilih kegiatan',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
                hintText:
                    'Deskripsikan kegiatan yang dikerjakan...',
                hintStyle:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.black, width: 1.5),
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
                color: _fotoFile != null ? Colors.transparent : AppColors.surfaceMuted,
                border: Border.all(
                  color: _fotoFile != null
                      ? AppColors.black
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(14),
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
              color: AppColors.surfaceMuted,
              border: Border.all(
                color: _dokumenFile != null
                    ? AppColors.black
                    : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _dokumenFile != null
                        ? Icons.description_rounded
                        : Icons.upload_file_outlined,
                    color: _dokumenFile != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
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
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
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
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
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
                BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.black, width: 1.5),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary,
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
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.textPrimary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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
          color: _submitting ? Colors.grey[300] : AppColors.black,
          borderRadius: BorderRadius.circular(AppRadius.pill),
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

// ── AI Banner Widget ──────────────────────────────────────────

class _AiBannerWidget extends StatefulWidget {
  final bool generating;
  final String? locationStatus;
  final VoidCallback? onTap;

  const _AiBannerWidget({
    required this.generating,
    this.locationStatus,
    this.onTap,
  });

  @override
  State<_AiBannerWidget> createState() => _AiBannerWidgetState();
}

class _AiBannerWidgetState extends State<_AiBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap ?? () {},
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, child) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.black,
                  Color.lerp(
                    AppColors.black,
                    const Color(0xFF1A1A2E),
                    _shimmer.value * 0.4,
                  )!,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // AI Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.softLime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.generating
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            color: AppColors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.black,
                          size: 26,
                        ),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'AI Laporan WFA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.softLime,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: ValueKey(widget.locationStatus ?? 'idle'),
                          widget.generating
                              ? (widget.locationStatus ?? 'Memproses...')
                              : 'Sekali klik, semua field + alamat terisi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow / loading
                if (!widget.generating)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
            // Step indicators saat generating
            if (widget.generating) ...[
              const SizedBox(height: 14),
              _buildStepIndicators(),
            ],
            // Feature pills saat idle
            if (!widget.generating) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _FeaturePill(
                      icon: Icons.location_on_rounded, label: 'Lokasi GPS'),
                  const SizedBox(width: 8),
                  _FeaturePill(
                      icon: Icons.edit_note_rounded, label: 'Uraian Kinerja'),
                  const SizedBox(width: 8),
                  _FeaturePill(
                      icon: Icons.trending_up_rounded, label: 'Efisiensi'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicators() {
    final steps = [
      (Icons.location_on_rounded, 'Lokasi'),
      (Icons.auto_awesome_rounded, 'AI'),
      (Icons.check_rounded, 'Selesai'),
    ];

    // Tentukan step aktif berdasarkan status
    int activeStep = 0;
    final status = widget.locationStatus ?? '';
    if (status.contains('Lokasi ditemukan') || status.contains('Mengisi')) {
      activeStep = 1;
    } else if (status.contains('Membuat')) {
      activeStep = 1;
    }

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isDone = i < activeStep;
        final isActive = i == activeStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.softLime
                            : isActive
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : step.$1,
                        size: 14,
                        color: isDone
                            ? AppColors.black
                            : isActive
                                ? AppColors.white
                                : Colors.white.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.$2,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isActive || isDone
                            ? Colors.white.withOpacity(0.8)
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Container(
                  width: 20,
                  height: 1,
                  color: Colors.white.withOpacity(0.15),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.softLime),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}