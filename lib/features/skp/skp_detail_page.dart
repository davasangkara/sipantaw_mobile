import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'skp_form_page.dart';

class SkpDetailPage extends StatefulWidget {
  final int id;
  const SkpDetailPage({super.key, required this.id});

  @override
  State<SkpDetailPage> createState() => _SkpDetailPageState();
}

class _SkpDetailPageState extends State<SkpDetailPage> {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  Map? _data;
  bool _loading = true;
  bool _deleting = false;
  bool _ajuking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res =
          await ApiClient.get('${ApiConfig.skpTarget}/${widget.id}');
      setState(() {
        _data = res.data['data'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _ajukan() async {
    setState(() => _ajuking = true);
    try {
      await ApiClient.patch(
          '${ApiConfig.skpTarget}/${widget.id}/ajukan');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SKP berhasil diajukan.'),
          backgroundColor: _teal,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal mengajukan SKP.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _ajuking = false);
    }
  }

  Future<void> _hapus() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus SKP',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _textDark),
        ),
        content: const Text(
          'Yakin ingin menghapus SKP ini?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ya, Hapus',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await ApiClient.delete('${ApiConfig.skpTarget}/${widget.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SKP berhasil dihapus.'),
          backgroundColor: _teal,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menghapus SKP.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _deleting = false);
    }
  }

  Map<String, dynamic> _statusConfig(String status) => switch (status) {
        'disetujui' => {
            'color': const Color(0xFF4CAF8C),
            'bg': const Color(0xFFE8F8F2),
            'icon': Icons.check_circle_rounded,
            'label': 'Disetujui',
          },
        'ditolak' => {
            'color': Colors.red,
            'bg': const Color(0xFFFFEEEE),
            'icon': Icons.cancel_rounded,
            'label': 'Ditolak',
          },
        'pending' => {
            'color': const Color(0xFFF4A261),
            'bg': const Color(0xFFFFF5EE),
            'icon': Icons.pending_rounded,
            'label': 'Menunggu',
          },
        _ => {
            'color': Colors.grey,
            'bg': const Color(0xFFF0F0F0),
            'icon': Icons.edit_note_rounded,
            'label': 'Draft',
          },
      };

  @override
  Widget build(BuildContext context) {
    final status = _data?['status']?.toString() ?? '';
    final isDraft = status == 'draft';
    final isDitolak = status == 'ditolak';
    final canEdit = isDraft || isDitolak;
    final cfg = _statusConfig(status);

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
                  'Detail SKP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            actions: [
              if (canEdit && !_loading) ...[
                GestureDetector(
                  onTap: () async {
                    final refresh = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SkpFormPage(existingData: _data),
                      ),
                    );
                    if (refresh == true) _loadData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.xs,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _deleting ? null : _hapus,
                  child: Container(
                    margin: const EdgeInsets.only(right: 20),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.xs,
                    ),
                    child: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.red, strokeWidth: 2),
                          )
                        : Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red[400],
                          ),
                  ),
                ),
              ],
              if (!canEdit || _loading) const SizedBox(width: 16),
            ],
          ),
        ],
        body: _loading
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
                  children: [
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _tealLight,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: _teal,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _data?['nama_rencana_hasil']
                                              ?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _data?['kegiatan']
                                              ?.toString() ??
                                          '-',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cfg['bg'] as Color,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cfg['icon'] as IconData,
                                        size: 11,
                                        color: cfg['color'] as Color),
                                    const SizedBox(width: 4),
                                    Text(
                                      cfg['label'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: cfg['color'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: Colors.grey[100]),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _infoCol(
                                  Icons.calendar_today_rounded,
                                  'Tahun',
                                  '${_data?['tahun'] ?? '-'}',
                                ),
                              ),
                              Expanded(
                                child: _infoCol(
                                  Icons.schedule_rounded,
                                  'Target Waktu',
                                  '${_data?['target_waktu'] ?? 0} bulan',
                                ),
                              ),
                              Expanded(
                                child: _infoCol(
                                  Icons.star_rounded,
                                  'Kualitas',
                                  '${_data?['target_kualitas'] ?? 0}%',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoCol(
                            Icons.flag_rounded,
                            'Target Kuantitas',
                            '${_data?['target_kuantitas'] ?? 0} ${_data?['satuan_kuantitas'] ?? ''}',
                          ),
                          const SizedBox(height: 12),
                          _infoCol(
                            Icons.info_outline_rounded,
                            'Indikator',
                            _data?['indikator']?.toString() ?? '-',
                          ),
                        ],
                      ),
                    ),
                    if ((_data?['realisasi'] as List?)?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 12),
                      _buildCard(
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
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Realisasi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...(_data!['realisasi'] as List)
                                .map((r) => Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 10),
                                      padding:
                                          const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _bg,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                                decoration:
                                                    BoxDecoration(
                                                  color: _tealLight,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(20),
                                                ),
                                                child: Text(
                                                  'Semester ${r['semester']}',
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: _teal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _infoCol(
                                                  Icons.flag_rounded,
                                                  'Kuantitas',
                                                  '${r['realisasi_kuantitas']}',
                                                ),
                                              ),
                                              Expanded(
                                                child: _infoCol(
                                                  Icons.star_rounded,
                                                  'Kualitas',
                                                  '${r['realisasi_kualitas']}%',
                                                ),
                                              ),
                                              Expanded(
                                                child: _infoCol(
                                                  Icons.schedule_rounded,
                                                  'Waktu',
                                                  '${r['realisasi_waktu']} bln',
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (r['keterangan'] !=
                                                  null &&
                                              r['keterangan']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              r['keterangan']
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    ],
                    if (isDraft) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _ajuking ? null : _ajukan,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: _ajuking
                                ? null
                                : const LinearGradient(
                                    colors: [_teal, _tealDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: _ajuking ? Colors.grey[300] : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _ajuking
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
                            child: _ajuking
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.send_rounded,
                                          color: Colors.white,
                                          size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Ajukan ke Pejabat',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) => Container(
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

  Widget _infoCol(IconData icon, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ],
      );
}