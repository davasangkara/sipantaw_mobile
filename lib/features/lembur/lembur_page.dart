import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'lembur_form_page.dart';

/// Premium monochrome lembur page — matching dashboard design language.
/// All business logic preserved: pagination, delete, total hours summary.
class LemburPage extends StatefulWidget {
  const LemburPage({super.key});

  @override
  State<LemburPage> createState() => _LemburPageState();
}

class _LemburPageState extends State<LemburPage>
    with SingleTickerProviderStateMixin {
  List _lemburList = [];
  bool _loading = true;
  String? _error;
  double _totalJamBulanIni = 0;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
      _fadeCtrl.forward(from: 0);
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Hapus Pengajuan?'),
        content: const Text(
            'Pengajuan lembur akan dihapus permanen. Lanjutkan?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          PremiumButton(
            label: 'Batal',
            onTap: () => Navigator.pop(ctx, false),
            outlined: true,
            fullWidth: false,
            height: 44,
          ),
          const SizedBox(width: 10),
          PremiumButton(
            label: 'Hapus',
            onTap: () => Navigator.pop(ctx, true),
            background: AppColors.danger,
            fullWidth: false,
            height: 44,
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiClient.delete('${ApiConfig.lembur}/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembur berhasil dihapus.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Gagal menghapus. Lembur mungkin sudah disetujui.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
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
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 20, color: AppColors.black),
                ),
              ),
            ),
            title: Column(
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
                const Text(
                  'Lembur Saya',
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
                      PremiumPageRoute(page: const LemburFormPage()),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_rounded,
                            size: 16, color: AppColors.softLime),
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
            ? _buildLoadingState()
            : RefreshIndicator(
                color: AppColors.black,
                backgroundColor: AppColors.white,
                onRefresh: _loadData,
                child: _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        children: [_ErrorBanner(message: _error!)],
                      )
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: _lemburList.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(
                                    20, 8, 20, 32),
                                itemCount: _lemburList.length + 2,
                                itemBuilder: (context, i) {
                                  if (i == 0) return _buildSummaryCard();
                                  if (i == _lemburList.length + 1) {
                                    if (_currentPage < _lastPage) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12),
                                        child: PremiumButton(
                                          label: 'Muat lebih banyak',
                                          onTap: _loadingMore
                                              ? null
                                              : _loadMore,
                                          outlined: true,
                                          loading: _loadingMore,
                                          trailingIcon:
                                              Icons.expand_more_rounded,
                                        ),
                                      );
                                    }
                                    return const SizedBox(height: 20);
                                  }
                                  return _buildLemburCard(
                                          _lemburList[i - 1] as Map, i - 1)
                                      .animate(delay: (40 * (i - 1)).ms)
                                      .fadeIn(duration: 420.ms)
                                      .moveY(
                                          begin: 12,
                                          end: 0,
                                          duration: 420.ms,
                                          curve: Curves.easeOutCubic);
                                },
                              ),
                      ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        PremiumSkeleton(height: 120, radius: 28),
        SizedBox(height: 14),
        PremiumSkeleton(height: 140, radius: 28),
        SizedBox(height: 14),
        PremiumSkeleton(height: 140, radius: 28),
        SizedBox(height: 14),
        PremiumSkeleton(height: 140, radius: 28),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_time_rounded,
                  size: 44,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Belum ada pengajuan lembur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tekan tombol Ajukan untuk membuat\npengajuan lembur baru.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 220,
                child: PremiumButton(
                  label: 'Ajukan Lembur',
                  leadingIcon: Icons.add_rounded,
                  onTap: () async {
                    final refresh = await Navigator.push<bool>(
                      context,
                      PremiumPageRoute(page: const LemburFormPage()),
                    );
                    if (refresh == true) _loadData();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalStr = _totalJamBulanIni == _totalJamBulanIni.toInt()
        ? _totalJamBulanIni.toInt().toString()
        : _totalJamBulanIni.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.softLime.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.softLime,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: AppColors.black, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Total lembur\nbulan ini',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  AccentChip(
                    label: '${_lemburList.length} entri',
                    color: AppColors.softLime,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalStr,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'jam',
                      style: TextStyle(
                        color: AppColors.softLime,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .moveY(
            begin: 16,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _buildLemburCard(Map l, int index) {
    final approved = l['status_approve'] == true;
    final accent = approved ? AppColors.softLime : AppColors.neonCyan;
    final statusLabel = approved ? 'Disetujui' : 'Menunggu';
    final statusIcon =
        approved ? Icons.check_circle_rounded : Icons.schedule_rounded;

    final tanggal = l['tanggal']?.toString() ?? '-';
    final jamMulai = l['jam_mulai']?.toString() ?? '-';
    final jamSelesai = l['jam_selesai']?.toString() ?? '-';
    final jamTotal = l['jam_total']?.toString() ?? '0';
    final keterangan = l['keterangan']?.toString() ?? '-';

    return PremiumCard(
      padding: EdgeInsets.zero,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.more_time_rounded,
                    color: AppColors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanggal,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$jamMulai – $jamSelesai',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
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
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: approved
                        ? AppColors.black
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon,
                          size: 12,
                          color: approved
                              ? AppColors.softLime
                              : AppColors.textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: approved
                              ? AppColors.white
                              : AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.hourglass_bottom_rounded,
                      'Durasi',
                      '$jamTotal jam',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _infoItem(
                      Icons.notes_rounded,
                      'Keterangan',
                      keterangan,
                    ),
                  ),
                  if (!approved) ...[
                    const SizedBox(width: 8),
                    PressableScale(
                      onTap: () =>
                          _hapus(int.parse(l['id'].toString())),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
