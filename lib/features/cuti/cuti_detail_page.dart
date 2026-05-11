import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';

class CutiDetailPage extends StatefulWidget {
  final int id;
  const CutiDetailPage({super.key, required this.id});

  @override
  State<CutiDetailPage> createState() => _CutiDetailPageState();
}

class _CutiDetailPageState extends State<CutiDetailPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _cancelling = false;

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
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('${ApiConfig.cuti}/${widget.id}');
      setState(() {
        _data = res.data['data'];
        _loading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _batalkan() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Cuti',
          style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
        ),
        content:
            const Text('Yakin ingin membatalkan pengajuan cuti ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tidak', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Batalkan',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _cancelling = true);
    try {
      await ApiClient.patch('${ApiConfig.cuti}/${widget.id}/batal');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Cuti berhasil dibatalkan.',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Gagal membatalkan cuti.',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      setState(() => _cancelling = false);
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
    final status = _data?['status']?.toString() ?? '';
    final isPending = status == 'Pending';

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
                  'Detail',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'Pengajuan Cuti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
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
                onRefresh: _loadData,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(status),
                        const SizedBox(height: 12),
                        _buildPeriodeCard(),
                        if ((_data?['log'] as List?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          _buildLogCard(),
                        ],
                        if (isPending) ...[
                          const SizedBox(height: 20),
                          _buildBatalkanButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard(String status) {
    final config = _statusConfig(status);
    final statusColor = config['color'] as Color;
    final statusBg = config['bg'] as Color;
    final statusIcon = config['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_teal, Color(0xFF1C8CA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.luggage_rounded,
                    color: Colors.white, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      status.isEmpty ? '-' : status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _data?['jenis_cuti']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 12, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 5),
              Text(
                'Pejabat: ${_data?['pejabat']?.toString() ?? '-'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeCard() {
    return _sectionCard(
      icon: Icons.date_range_rounded,
      title: 'Periode Cuti',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _infoCol(
                  'Tanggal Mulai',
                  _data?['tanggal_mulai']?.toString() ?? '-',
                  icon: Icons.play_arrow_rounded,
                ),
              ),
              Expanded(
                child: _infoCol(
                  'Tanggal Selesai',
                  _data?['tanggal_selesai']?.toString() ?? '-',
                  icon: Icons.stop_rounded,
                ),
              ),
              _infoCol(
                'Durasi',
                '${_data?['jumlah_hari'] ?? 0} hari',
                icon: Icons.hourglass_bottom_rounded,
              ),
            ],
          ),
          if (_data?['keterangan'] != null &&
              _data!['keterangan'].toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 14),
            Text(
              'Keterangan',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _data!['keterangan'].toString(),
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: _textDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogCard() {
    final logs = _data!['log'] as List;

    return _sectionCard(
      icon: Icons.history_rounded,
      title: 'Riwayat Status',
      child: Column(
        children: logs.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value as Map;
          final isLast = i == logs.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _tealLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                        width: 2, height: 24, color: Colors.grey[100]),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: isLast ? 0 : 12, top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['aksi']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l['keterangan']?.toString() ?? '-',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l['waktu']} · ${l['oleh']}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBatalkanButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _cancelling ? null : _batalkan,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _cancelling
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.red),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Batalkan Pengajuan',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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

  Widget _infoCol(String label, String value, {IconData? icon}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: Colors.grey[400]),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 4),
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