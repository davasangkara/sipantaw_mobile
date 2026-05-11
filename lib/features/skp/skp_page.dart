import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'skp_form_page.dart';
import 'skp_detail_page.dart';

class SkpPage extends StatefulWidget {
  const SkpPage({super.key});

  @override
  State<SkpPage> createState() => _SkpPageState();
}

class _SkpPageState extends State<SkpPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _skpList = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  Map _statistik = {};

  String? _filterStatus;
  int? _filterTahun;
  List _daftarTahun = [];

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
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _currentPage = 1;
      });
    }
    try {
      final params = StringBuffer('?page=$_currentPage');
      if (_filterStatus != null) params.write('&status=$_filterStatus');
      if (_filterTahun != null) params.write('&tahun=$_filterTahun');

      final res = await ApiClient.get('${ApiConfig.skpTarget}$params');
      final data = res.data['data'];

      setState(() {
        if (reset) {
          _skpList = data['skp'] ?? [];
        } else {
          _skpList.addAll(data['skp'] ?? []);
        }
        _statistik = data['statistik'] ?? {};
        _daftarTahun = data['daftar_tahun'] ?? [];
        _currentPage = data['pagination']['current_page'];
        _lastPage = data['pagination']['last_page'];
        _loading = false;
        _loadingMore = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _lastPage || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _currentPage++;
    });
    await _loadData(reset: false);
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

  bool get _hasActiveFilter =>
      _filterStatus != null || _filterTahun != null;

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
                  'SKP Target',
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
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 14),
                child: GestureDetector(
                  onTap: _showFilter,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasActiveFilter ? AppColors.surfaceMuted : AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.xs,
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: _hasActiveFilter ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 14, bottom: 14),
                child: PressableScale(
                  onTap: () async {
                    final refresh = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SkpFormPage()),
                    );
                    if (refresh == true) _loadData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: AppColors.softLime),
                        SizedBox(width: 6),
                        Text(
                          'Buat SKP',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
            : RefreshIndicator(
                color: _teal,
                onRefresh: _loadData,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _skpList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _skpList.length + 2,
                          itemBuilder: (context, i) {
                            if (i == 0) return _buildStatistikCard();
                            if (i == _skpList.length + 1) {
                              if (_currentPage < _lastPage) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  child: Center(
                                    child: TextButton(
                                      onPressed:
                                          _loadingMore ? null : _loadMore,
                                      child: _loadingMore
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                color: _teal,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Muat lebih banyak',
                                              style: TextStyle(
                                                color: _teal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox(height: 8);
                            }
                            return _buildSkpCard(_skpList[i - 1]);
                          },
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: _tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 36,
              color: _teal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada SKP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap tombol Buat SKP untuk memulai',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatistikCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_teal, _tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('Total', '${_statistik['total'] ?? 0}', Colors.white),
          _statDivider(),
          _statCol('Menunggu', '${_statistik['pending'] ?? 0}',
              const Color(0xFFFFD9B0)),
          _statDivider(),
          _statCol('Disetujui', '${_statistik['disetujui'] ?? 0}',
              const Color(0xFFB0F0D8)),
          _statDivider(),
          _statCol('Ditolak', '${_statistik['ditolak'] ?? 0}',
              const Color(0xFFFFB0B0)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withOpacity(0.2),
      );

  Widget _statCol(String label, String value, Color color) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildSkpCard(Map s) {
    final status = s['status']?.toString() ?? 'draft';
    final config = _statusConfig(status);
    final statusColor = config['color'] as Color;
    final statusBg = config['bg'] as Color;
    final statusIcon = config['icon'] as IconData;
    final statusLabel = config['label'] as String;

    return GestureDetector(
      onTap: () async {
        final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SkpDetailPage(id: int.parse(s['id'].toString())),
          ),
        );
        if (refresh == true) _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _tealLight,
                      borderRadius: BorderRadius.circular(14),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['nama_rencana_hasil']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.work_outline_rounded,
                                size: 11, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                s['kegiatan']?.toString() ?? '-',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[100]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.flag_rounded,
                      'Target',
                      '${s['target_kuantitas']} ${s['satuan_kuantitas']}',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.star_rounded,
                      'Kualitas',
                      '${s['target_kualitas']}%',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.calendar_today_rounded,
                      'Tahun',
                      '${s['tahun']}',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.assignment_rounded,
                      'Realisasi',
                      '${s['realisasi_count']}x',
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

  Widget _infoItem(IconData icon, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: Colors.grey[400]),
              const SizedBox(width: 3),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Filter SKP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['draft', 'pending', 'disetujui', 'ditolak']
                    .map((s) {
                  final cfg = _statusConfig(s);
                  final selected = _filterStatus == s;
                  return GestureDetector(
                    onTap: () =>
                        setModal(() => _filterStatus = selected ? null : s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? (cfg['bg'] as Color)
                            : _bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? (cfg['color'] as Color)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        cfg['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? (cfg['color'] as Color)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_daftarTahun.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Tahun',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _daftarTahun.map((t) {
                    final selected =
                        _filterTahun == int.parse(t.toString());
                    return GestureDetector(
                      onTap: () => setModal(() => _filterTahun =
                          selected ? null : int.parse(t.toString())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _tealLight : _bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? _teal
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '$t',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? _teal : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _filterStatus = null;
                          _filterTahun = null;
                        });
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_teal, _tealDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _teal.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Terapkan',
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
}