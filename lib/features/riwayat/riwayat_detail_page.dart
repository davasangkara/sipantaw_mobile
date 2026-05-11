import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';

class RiwayatDetailPage extends StatefulWidget {
  final int id;
  final String tanggal;

  const RiwayatDetailPage({
    super.key,
    required this.id,
    required this.tanggal,
  });

  @override
  State<RiwayatDetailPage> createState() => _RiwayatDetailPageState();
}

class _RiwayatDetailPageState extends State<RiwayatDetailPage>
    with SingleTickerProviderStateMixin {
  static const _textDark = AppColors.textPrimary;

  Map<String, dynamic>? _data;
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
      final res = await ApiClient.get('${ApiConfig.laporan}/${widget.id}');
      setState(() {
        _data = res.data['data'];
        _loading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat detail laporan.';
      });
    }
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
                  'Detail Laporan',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  widget.tanggal,
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
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2.5,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    color: AppColors.black,
                    onRefresh: _loadData,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroCard(),
                            const SizedBox(height: 12),
                            _buildAbsensiCard(),
                            const SizedBox(height: 12),
                            _buildKinerjaCard(),
                            if ((_data?['efisiensi'] as List?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 12),
                              _buildEfisiensiCard(),
                            ],
                            if ((_data?['hambatan'] as List?)?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 12),
                              _buildHambatanCard(),
                            ],
                            if (_data?['alamat'] != null) ...[
                              const SizedBox(height: 12),
                              _buildAlamatCard(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final pelaporan = _data?['pelaporan'] ?? {};
    final status = pelaporan['status']?.toString() ?? '-';

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
        {'color': Colors.grey, 'bg': Colors.grey[100]!, 'icon': Icons.help_outline_rounded};

    final statusColor = config['color'] as Color;
    final statusBg = config['bg'] as Color;
    final statusIcon = config['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.softLime.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.description_outlined,
                    color: Colors.white, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      status,
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
            pelaporan['kegiatan']?.toString() ?? '-',
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
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                pelaporan['tanggal']?.toString() ?? '-',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbsensiCard() {
    final absensi = (_data?['absensi'] as List?) ?? [];
    final jamKerja = _data?['jam_kerja'];

    return _sectionCard(
      icon: Icons.fingerprint_rounded,
      title: 'Absensi',
      child: absensi.isEmpty
          ? _emptyRow('Belum ada data absensi')
          : Column(
              children: [
                ...absensi.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: AppColors.textPrimary, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['jenis']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${a['waktu']} ${a['timezone']}',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                ),
                                if (a['lokasi'] != null &&
                                    a['lokasi'].toString().isNotEmpty)
                                  Text(
                                    a['lokasi'].toString(),
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[400]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (a['foto_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                a['foto_url'].toString(),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.broken_image_rounded,
                                      size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                if (jamKerja != null) ...[
                  Divider(height: 1, color: Colors.grey[100]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 15, color: AppColors.textPrimary),
                        const SizedBox(width: 7),
                        Text(
                          'Total: ${jamKerja['teks']} (${jamKerja['sesi_hadir']})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildKinerjaCard() {
    final kinerja = _data?['kinerja'];

    if (kinerja == null) {
      return _sectionCard(
        icon: Icons.work_outline_rounded,
        title: 'Kinerja',
        child: _emptyRow('Belum ada data kinerja'),
      );
    }

    return _sectionCard(
      icon: Icons.work_outline_rounded,
      title: 'Kinerja',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Kegiatan', kinerja['kegiatan']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text(
            'Uraian Kinerja',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              kinerja['uraian']?.toString() ?? '-',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          if (kinerja['link_output'] != null &&
              kinerja['link_output'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow('Link Output', kinerja['link_output'].toString()),
          ],
          if (kinerja['foto_url'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Foto Output',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                kinerja['foto_url'].toString(),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEfisiensiCard() {
    final list = (_data?['efisiensi'] as List?) ?? [];

    return _sectionCard(
      icon: Icons.trending_up_rounded,
      title: 'Efisiensi Kerja',
      child: Column(
        children: list.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF8C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                e['kategori']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4CAF8C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e['jenis']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e['uraian']?.toString() ?? '-',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
            .toList(),
      ),
    );
  }

  Widget _buildHambatanCard() {
    final list = (_data?['hambatan'] as List?) ?? [];

    return _sectionCard(
      icon: Icons.warning_amber_rounded,
      title: 'Hambatan Kerja',
      child: Column(
        children: list.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4A261),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5EE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                h['kategori']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFF4A261),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h['jenis']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          h['uraian']?.toString() ?? '-',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
            .toList(),
      ),
    );
  }

  Widget _buildAlamatCard() {
    final alamat = _data?['alamat'];
    if (alamat == null) return const SizedBox.shrink();

    return _sectionCard(
      icon: Icons.location_on_outlined,
      title: 'Lokasi WFA',
      child: Column(
        children: [
          _infoRow('Jalan', alamat['jalan']?.toString() ?? '-'),
          const SizedBox(height: 8),
          _infoRow('RT/RW', alamat['rtrw']?.toString() ?? '-'),
          const SizedBox(height: 8),
          _infoRow('Kelurahan', alamat['kelurahan']?.toString() ?? '-'),
          const SizedBox(height: 8),
          _infoRow('Kecamatan', alamat['kecamatan']?.toString() ?? '-'),
          const SizedBox(height: 8),
          _infoRow('Kab/Kota', alamat['kabkota']?.toString() ?? '-'),
        ],
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
          boxShadow: AppShadows.sm,
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
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.textPrimary, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _infoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(color: Colors.grey[400]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textDark),
            ),
          ),
        ],
      );

  Widget _emptyRow(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            msg,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ),
      );
}