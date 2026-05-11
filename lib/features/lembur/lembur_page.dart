import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import 'lembur_form_page.dart';

class LemburPage extends StatefulWidget {
  const LemburPage({super.key});

  @override
  State<LemburPage> createState() => _LemburPageState();
}

class _LemburPageState extends State<LemburPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _lemburList = [];
  bool _loading = true;
  String? _error;
  double _totalJamBulanIni = 0;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

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
        _error = null;
        _currentPage = 1;
      });
    }
    try {
      final res = await ApiClient.get(
        '${ApiConfig.lembur}?page=$_currentPage',
      );
      final data = res.data['data'];
      setState(() {
        if (reset) {
          _lemburList = data['lembur'] ?? [];
        } else {
          _lemburList.addAll(data['lembur'] ?? []);
        }
        _totalJamBulanIni = (data['total_jam_bulan_ini'] ?? 0).toDouble();
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
        _error = 'Gagal memuat data lembur.';
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

  Future<void> _hapus(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Lembur',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16, color: _textDark),
        ),
        content: const Text(
          'Yakin ingin menghapus pengajuan lembur ini?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiClient.delete('${ApiConfig.lembur}/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lembur berhasil dihapus.'),
            backgroundColor: _teal,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus. Lembur sudah disetujui.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            iconTheme: const IconThemeData(color: _textDark),
            toolbarHeight: 64,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengajuan',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'Lembur Saya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () async {
                  final refresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LemburFormPage()),
                  );
                  if (refresh == true) _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_teal, _tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Ajukan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  height: 1, color: Colors.grey.withOpacity(0.08)),
            ),
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
                child: _error != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _ErrorBanner(message: _error!),
                          ),
                        ],
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _lemburList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 16, 16, 32),
                                itemCount: _lemburList.length + 2,
                                itemBuilder: (context, i) {
                                  if (i == 0) return _buildSummaryCard();
                                  if (i == _lemburList.length + 1) {
                                    if (_currentPage < _lastPage) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Center(
                                          child: TextButton(
                                            onPressed: _loadingMore
                                                ? null
                                                : _loadMore,
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
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox(height: 8);
                                  }
                                  return _buildLemburCard(
                                      _lemburList[i - 1]);
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
              Icons.more_time_rounded,
              size: 36,
              color: _teal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pengajuan lembur',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap tombol Ajukan untuk membuat pengajuan baru',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Lembur Bulan Ini',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_totalJamBulanIni.toStringAsFixed(1)} jam',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLemburCard(Map l) {
    final approved = l['status_approve'] == true;
    final statusColor =
        approved ? const Color(0xFF4CAF8C) : const Color(0xFFF4A261);
    final statusBg =
        approved ? const Color(0xFFE8F8F2) : const Color(0xFFFFF5EE);
    final statusIcon =
        approved ? Icons.check_circle_rounded : Icons.pending_rounded;
    final statusLabel = approved ? 'Disetujui' : 'Menunggu';

    return Container(
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
                    Icons.more_time_rounded,
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
                        l['tanggal']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${l['jam_mulai']} – ${l['jam_selesai']}',
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
                    Icons.hourglass_bottom_rounded,
                    'Durasi',
                    '${l['jam_total']} jam',
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    Icons.notes_rounded,
                    'Keterangan',
                    l['keterangan']?.toString() ?? '-',
                  ),
                ),
                if (!approved)
                  GestureDetector(
                    onTap: () =>
                        _hapus(int.parse(l['id'].toString())),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red[400],
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[400]),
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
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}