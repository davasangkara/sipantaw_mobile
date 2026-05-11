import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../riwayat/riwayat_detail_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _laporan = [];
  List _bulanList = [];
  List _tahunList = [];
  bool _loading = true;
  String? _error;

  String? _selectedBulan;
  String? _selectedTahun;

  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loadingMore = false;

  final _scrollController = ScrollController();
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = 1;
        _laporan = [];
      });
    }

    try {
      final params = <String, dynamic>{'page': _currentPage};
      if (_selectedBulan != null) params['bulan'] = _selectedBulan;
      if (_selectedTahun != null) params['tahun'] = _selectedTahun;

      final res = await ApiClient.get(ApiConfig.riwayat, params: params);
      final data = res.data['data'];

      setState(() {
        if (reset) {
          _laporan = data['laporan'] ?? [];
          _bulanList = data['filter']['bulan_list'] ?? [];
          _tahunList = data['filter']['tahun_list'] ?? [];
        } else {
          _laporan.addAll(data['laporan'] ?? []);
        }
        _currentPage = data['pagination']['current_page'];
        _lastPage = data['pagination']['last_page'];
        _total = data['pagination']['total'];
        _loading = false;
        _loadingMore = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Gagal memuat data. Tarik ke bawah untuk coba lagi.';
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _currentPage++;
    });
    await _loadData(reset: false);
  }

  void _applyFilter() {
    Navigator.pop(context);
    _loadData();
  }

  void _resetFilter() {
    setState(() {
      _selectedBulan = null;
      _selectedTahun = null;
    });
    Navigator.pop(context);
    _loadData();
  }

  bool get _hasFilter => _selectedBulan != null || _selectedTahun != null;

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Riwayat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedBulan = null;
                        _selectedTahun = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _filterLabel('Bulan'),
              const SizedBox(height: 8),
              _styledDropdown<String>(
                value: _selectedBulan,
                hint: 'Semua Bulan',
                items: _bulanList
                    .map((b) => DropdownMenuItem<String>(
                          value: b['KodeBulan']?.toString(),
                          child: Text(b['Bulan']?.toString() ?? ''),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setModalState(() => _selectedBulan = val),
              ),
              const SizedBox(height: 16),
              _filterLabel('Tahun'),
              const SizedBox(height: 8),
              _styledDropdown<String>(
                value: _selectedTahun,
                hint: 'Semua Tahun',
                items: _tahunList
                    .map((t) => DropdownMenuItem<String>(
                          value: t.toString(),
                          child: Text(t.toString()),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setModalState(() => _selectedTahun = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  Widget _filterLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _textDark,
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
        ),
        hint: Text(hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
      );

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
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'Laporan Saya',
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
                onTap: _showFilter,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hasFilter ? _tealLight : _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: _hasFilter ? _teal : Colors.grey[400],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _hasFilter ? _teal : Colors.grey[400],
                        ),
                      ),
                      if (_hasFilter) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child:
                  Container(height: 1, color: Colors.grey.withOpacity(0.08)),
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
                onRefresh: () => _loadData(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: _buildSummaryBar(),
                        ),
                      ),
                      if (_error != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: _ErrorBanner(message: _error!),
                          ),
                        ),
                      if (_laporan.isEmpty && !_loading)
                        SliverFillRemaining(
                          child: _buildEmptyState(),
                        ),
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              if (i == _laporan.length) {
                                return _loadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: _teal,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }
                              return _buildLaporanCard(_laporan[i], i);
                            },
                            childCount: _laporan.length + 1,
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

  Widget _buildSummaryBar() {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _tealLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_rounded, size: 13, color: _teal),
              const SizedBox(width: 5),
              Text(
                '$_total laporan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (_hasFilter)
          GestureDetector(
            onTap: _resetFilter,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded,
                      size: 13, color: Colors.orange),
                  const SizedBox(width: 5),
                  const Text(
                    'Hapus Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
            decoration: BoxDecoration(
              color: _tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: _teal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat laporan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Laporan yang kamu buat akan muncul di sini',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanCard(Map l, int index) {
    final status = l['status']?.toString() ?? '-';

    final statusConfig = <String, Map<String, dynamic>>{
      'Disetujui': {
        'color': const Color(0xFF4CAF8C),
        'bg': const Color(0xFFE8F8F2),
        'icon': Icons.check_circle_rounded,
      },
      'Ditolak': {
        'color': Colors.red,
        'bg': const Color(0xFFFFEEEE),
        'icon': Icons.cancel_rounded,
      },
      'Pending': {
        'color': const Color(0xFFF4A261),
        'bg': const Color(0xFFFFF5EE),
        'icon': Icons.pending_rounded,
      },
    };

    final config = statusConfig[status] ??
        {
          'color': Colors.grey,
          'bg': Colors.grey[100]!,
          'icon': Icons.help_outline_rounded,
        };

    final statusColor = config['color'] as Color;
    final statusBg = config['bg'] as Color;
    final statusIcon = config['icon'] as IconData;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiwayatDetailPage(
            id: l['id'] as int,
            tanggal: l['tanggal']?.toString() ?? '-',
          ),
        ),
      ),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _tealLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
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
                      l['kegiatan']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l['tanggal']?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.folder_outlined,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l['bulan']?.toString() ?? '-',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
                      status,
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
        ),
      ),
    );
  }
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
          Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  TextStyle(color: Colors.red[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
} 