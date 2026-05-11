import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'cuti_form_page.dart';
import 'cuti_detail_page.dart';

class CutiPage extends StatefulWidget {
  const CutiPage({super.key});

  @override
  State<CutiPage> createState() => _CutiPageState();
}

class _CutiPageState extends State<CutiPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _cutiList = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.get(ApiConfig.cuti);
      setState(() {
        _cutiList = res.data['data'] ?? [];
        _loading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat data cuti.';
      });
    }
  }

  Map<String, dynamic> _statusConfig(String status) =>
      switch (status) {
        'Disetujui' => {
            'color': const Color(0xFF4CAF8C),
            'bg': const Color(0xFFE8F8F2),
            'icon': Icons.check_circle_rounded,
          },
        'Ditolak' => {
            'color': Colors.red,
            'bg': const Color(0xFFFFEEEE),
            'icon': Icons.cancel_rounded,
          },
        'Dibatalkan' => {
            'color': Colors.grey,
            'bg': Color(0xFFF0F0F0),
            'icon': Icons.remove_circle_rounded,
          },
        _ => {
            'color': const Color(0xFFF4A261),
            'bg': const Color(0xFFFFF5EE),
            'icon': Icons.pending_rounded,
          },
      };

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
                  'Pengajuan',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Cuti Saya',
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
                padding: const EdgeInsets.only(right: 20, top: 14, bottom: 14),
                child: PressableScale(
                  onTap: () async {
                    final refresh = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const CutiFormPage()),
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
                          'Ajukan',
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
                        child: _cutiList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 16, 16, 32),
                                itemCount: _cutiList.length,
                                itemBuilder: (context, i) =>
                                    _buildCutiCard(_cutiList[i]),
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
              Icons.beach_access_rounded,
              size: 36,
              color: _teal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pengajuan cuti',
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

  Widget _buildCutiCard(Map c) {
    final status = c['status']?.toString() ?? 'Pending';
    final config = _statusConfig(status);
    final statusColor = config['color'] as Color;
    final statusBg = config['bg'] as Color;
    final statusIcon = config['icon'] as IconData;

    return GestureDetector(
      onTap: () async {
        final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CutiDetailPage(id: int.parse(c['id'].toString())),
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
                      Icons.luggage_rounded,
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
                          c['jenis_cuti']?.toString() ?? '-',
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
                            Icon(Icons.calendar_today_rounded,
                                size: 11, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Diajukan: ${c['tanggal_pengajuan']?.toString() ?? '-'}',
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
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[100]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.play_arrow_rounded,
                      'Mulai',
                      c['tanggal_mulai']?.toString() ?? '-',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.stop_rounded,
                      'Selesai',
                      c['tanggal_selesai']?.toString() ?? '-',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.hourglass_bottom_rounded,
                      'Durasi',
                      '${c['jumlah_hari'] ?? 0} hari',
                    ),
                  ),
                ],
              ),
              if (c['keterangan'] != null &&
                  c['keterangan'].toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    c['keterangan'].toString(),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
          Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 20),
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