import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';

class SkpFormPage extends StatefulWidget {
  final Map? existingData;
  const SkpFormPage({super.key, this.existingData});

  @override
  State<SkpFormPage> createState() => _SkpFormPageState();
}

class _SkpFormPageState extends State<SkpFormPage> {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _kegiatanList = [];
  bool _loadingForm = true;
  bool _submitting = false;

  int? _selectedKegiatan;
  int _tahun = DateTime.now().year;
  final _rencanaController = TextEditingController();
  final _indikatorController = TextEditingController();
  String? _selectedSatuan;

  static const _satuanList = [
    'Dokumen',
    'Laporan',
    'Kegiatan',
    'Surat',
    'Paket',
    'Orang',
    'Unit',
    'Kali',
    'Buah',
    'Lainnya',
  ];

  double _targetKuantitas = 1;
  double _targetKualitas = 100;
  int _targetWaktu = 12;

  bool get _isEdit => widget.existingData != null;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    if (_isEdit) _fillExisting();
  }

  void _fillExisting() {
    final d = widget.existingData!;
    _tahun = d['tahun'] ?? DateTime.now().year;
    _targetKuantitas = (d['target_kuantitas'] ?? 1).toDouble();
    _targetKualitas = (d['target_kualitas'] ?? 100).toDouble();
    _targetWaktu = d['target_waktu'] ?? 12;
    _rencanaController.text = d['nama_rencana_hasil'] ?? '';
    _indikatorController.text = d['indikator'] ?? '';
    final satuan = d['satuan_kuantitas']?.toString() ?? '';
    _selectedSatuan = _satuanList.contains(satuan) ? satuan : null;
  }

  @override
  void dispose() {
    _rencanaController.dispose();
    _indikatorController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      final res = await ApiClient.get('${ApiConfig.skpTarget}/form-data');
      setState(() {
        _kegiatanList = res.data['data']['kegiatan'] ?? [];
        _loadingForm = false;
        if (_isEdit) {
          final kegiatanNama = widget.existingData!['kegiatan'];
          final match = _kegiatanList.firstWhere(
            (k) => k['Kegiatan'] == kegiatanNama,
            orElse: () => null,
          );
          if (match != null) {
            _selectedKegiatan =
                int.parse(match['KegiatanId'].toString());
          }
        }
      });
    } catch (e) {
      setState(() => _loadingForm = false);
    }
  }

  Future<void> _submit(String action) async {
    if (_selectedKegiatan == null) {
      _showSnack('Pilih jenis kegiatan.', isError: true);
      return;
    }
    if (_rencanaController.text.trim().isEmpty) {
      _showSnack('Nama rencana hasil wajib diisi.', isError: true);
      return;
    }
    if (_indikatorController.text.trim().isEmpty) {
      _showSnack('Indikator wajib diisi.', isError: true);
      return;
    }
    if (_selectedSatuan == null) {
      _showSnack('Pilih satuan kuantitas.', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = {
        'Tahun': _tahun,
        'KegiatanId': _selectedKegiatan,
        'NamaRencanaHasil': _rencanaController.text.trim(),
        'Indikator': _indikatorController.text.trim(),
        'TargetKuantitas': _targetKuantitas,
        'SatuanKuantitas': _selectedSatuan,
        'TargetKualitas': _targetKualitas,
        'TargetWaktu': _targetWaktu,
        'action': action,
      };

      if (_isEdit) {
        final id = widget.existingData!['id'];
        await ApiClient.put('${ApiConfig.skpTarget}/$id', data: payload);
      } else {
        await ApiClient.post(ApiConfig.skpTarget, data: payload);
      }

      if (mounted) {
        _showSnack(action == 'ajukan'
            ? 'SKP berhasil diajukan!'
            : 'SKP disimpan sebagai draft.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('Gagal menyimpan SKP.', isError: true);
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kinerja Pegawai',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  _isEdit ? 'Edit SKP' : 'Buat SKP',
                  style: const TextStyle(
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
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Informasi Dasar',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Tahun'),
                          DropdownButtonFormField<int>(
                            value: _tahun,
                            isExpanded: true,
                            decoration: _inputDeco('Pilih tahun'),
                            items: List.generate(6, (i) {
                              final y = DateTime.now().year - 1 + i;
                              return DropdownMenuItem(
                                  value: y, child: Text('$y'));
                            }),
                            onChanged: (v) =>
                                setState(() => _tahun = v!),
                          ),
                          const SizedBox(height: 14),
                          _label('Jenis Kegiatan'),
                          _kegiatanPickerField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: 'Rencana Hasil',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Nama Rencana Hasil'),
                          TextField(
                            controller: _rencanaController,
                            maxLines: 2,
                            style: const TextStyle(
                                fontSize: 13, color: _textDark),
                            decoration: _inputDeco(
                                'Contoh: Laporan bulanan tersusun'),
                          ),
                          const SizedBox(height: 14),
                          _label('Indikator'),
                          TextField(
                            controller: _indikatorController,
                            maxLines: 2,
                            style: const TextStyle(
                                fontSize: 13, color: _textDark),
                            decoration: _inputDeco(
                                'Contoh: Jumlah laporan yang dibuat'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: 'Target',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Target Kuantitas'),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _tealLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _targetKuantitas.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _teal,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _targetKuantitas,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  activeColor: _teal,
                                  inactiveColor: _tealLight,
                                  onChanged: (v) => setState(
                                      () => _targetKuantitas = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _label('Satuan Kuantitas'),
                          DropdownButtonFormField<String>(
                            value: _selectedSatuan,
                            isExpanded: true,
                            decoration: _inputDeco('Pilih satuan'),
                            items: _satuanList
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSatuan = v),
                          ),
                          const SizedBox(height: 14),
                          _label(
                              'Target Kualitas: ${_targetKualitas.toStringAsFixed(0)}%'),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _tealLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_targetKualitas.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _teal,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _targetKualitas,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  activeColor: _teal,
                                  inactiveColor: _tealLight,
                                  onChanged: (v) => setState(
                                      () => _targetKualitas = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _label('Target Waktu: $_targetWaktu bulan'),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _tealLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_targetWaktu bln',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _teal,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _targetWaktu.toDouble(),
                                  min: 1,
                                  max: 12,
                                  divisions: 11,
                                  activeColor: _teal,
                                  inactiveColor: _tealLight,
                                  onChanged: (v) => setState(
                                      () => _targetWaktu = v.toInt()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _submitting
                                ? null
                                : () => _submit('draft'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _teal.withOpacity(0.4),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Simpan Draft',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _teal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _submitting
                                ? null
                                : () => _submit('ajukan'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _submitting
                                    ? null
                                    : const LinearGradient(
                                        colors: [_teal, _tealDark],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color: _submitting
                                    ? Colors.grey[300]
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _submitting
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: _teal.withOpacity(0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _submitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Ajukan',
                                        style: TextStyle(
                                          fontSize: 13,
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
                  ],
                ),
              ),
      ),
    );
  }

  String? get _selectedKegiatanNama {
    if (_selectedKegiatan == null) return null;
    final match = _kegiatanList.firstWhere(
      (k) => int.parse(k['KegiatanId'].toString()) == _selectedKegiatan,
      orElse: () => null,
    );
    return match?['Kegiatan']?.toString();
  }

  Widget _kegiatanPickerField() => GestureDetector(
        onTap: _showKegiatanPicker,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedKegiatanNama ?? 'Pilih kegiatan',
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedKegiatan != null
                        ? _textDark
                        : Colors.grey[400],
                    fontWeight: _selectedKegiatan != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      );

  void _showKegiatanPicker() {
    String _query = '';
    List _filtered = List.from(_kegiatanList);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _teal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Pilih Jenis Kegiatan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    autofocus: true,
                    style:
                        const TextStyle(fontSize: 13, color: _textDark),
                    decoration: InputDecoration(
                      hintText: 'Cari kegiatan...',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _teal, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _teal, width: 1.5),
                      ),
                      filled: true,
                      fillColor: _bg,
                    ),
                    onChanged: (val) {
                      setModal(() {
                        _query = val;
                        _filtered = _kegiatanList
                            .where((k) => k['Kegiatan']
                                .toString()
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey[100]),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ditemukan',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                              20, 8, 20, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey[100],
                          ),
                          itemBuilder: (ctx, i) {
                            final k = _filtered[i];
                            final id = int.parse(
                                k['KegiatanId'].toString());
                            final nama =
                                k['Kegiatan']?.toString() ?? '-';
                            final selected = _selectedKegiatan == id;
                            return GestureDetector(
                              onTap: () {
                                setState(
                                    () => _selectedKegiatan = id);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nama,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: selected
                                              ? _teal
                                              : _textDark,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: _teal,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) =>
      Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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