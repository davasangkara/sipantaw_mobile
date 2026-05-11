import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import '../auth/auth_service.dart';
import '../laporan/laporan_form_page.dart';
import '../riwayat/riwayat_page.dart';
import '../profil/profil_page.dart';
import '../cuti/cuti_page.dart';
import '../lembur/lembur_page.dart';
import '../skp/skp_page.dart';
import 'package:sipantaw_mobile/features/chat/chat_page.dart';
import '../absensi/absensi_foto_page.dart';

/// Premium monochrome dashboard — black & white, neon pastel accents,
/// floating pill navbar, large rounded cards, smooth animations.
/// All business logic / routes preserved.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  Map<String, String?> _pegawaiLocal = {};
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int _selectedMenuIndex = 0;
  int _bottomNavIndex = 0;
  String _chartRange = '1W';
  DateTime _calendarFocus = DateTime.now();
  DateTime? _calendarSelected;

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _sidebarWidth = 280.0;
  static const _breakpoint = 860.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _pegawaiLocal = await TokenStorage.getPegawai();
      final res = await ApiClient.get(ApiConfig.dashboard);
      setState(() {
        _data = res.data['data'];
        _loading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat data. Tarik ke bawah untuk coba lagi.';
      });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Keluar dari akun?'),
        content: const Text(
            'Anda akan keluar dan perlu masuk kembali dengan NIP.'),
        actionsPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            label: 'Logout',
            onTap: () => Navigator.pop(ctx, true),
            fullWidth: false,
            height: 44,
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await AuthService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  Map<String, dynamic> get _statistik => _data?['statistik'] ?? {};
  Map<String, dynamic> get _statusAbsensi => _data?['status_absensi'] ?? {};
  Map<String, dynamic> get _cuti => _data?['cuti'] ?? {};
  List get _notifikasi => _data?['notifikasi'] ?? [];
  List get _laporanTerbaru => _data?['laporan_terbaru'] ?? [];
  List get _aktivitas => _data?['aktivitas'] ?? [];

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= _breakpoint;

  List<FlSpot> _getChartSpots() {
    List<num> raw;
    switch (_chartRange) {
      case '1D':
        raw = _asNumList(_statistik['wfa_per_jam']) ??
            [0, 1, 0, 1, 1, 0, 1, 1];
        break;
      case '1W':
        raw = _asNumList(_statistik['wfa_per_hari']) ??
            [0, 1, 1, 0, 1, 1, 0];
        break;
      case '1M':
        raw = _asNumList(_statistik['wfa_per_minggu']) ??
            [3, 5, 4, 6];
        break;
      case '1Y':
        raw = _asNumList(_statistik['wfa_per_bulan']) ??
            List.generate(
                12, (i) => 8 + (math.sin(i.toDouble()) * 4).abs().round());
        break;
      default:
        raw = [];
    }
    return raw
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
  }

  List<num>? _asNumList(dynamic v) {
    if (v is List && v.isNotEmpty) {
      return v.map((e) => (e as num)).toList();
    }
    return null;
  }

  List<String> _getChartLabels() {
    switch (_chartRange) {
      case '1D':
        return ['06', '08', '10', '12', '14', '16', '18', '20'];
      case '1W':
        return ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      case '1M':
        return ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4'];
      case '1Y':
        return [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);
    final nama = _data?['pegawai']?['nama'] ?? _pegawaiLocal['nama'] ?? '-';
    final nip = _data?['pegawai']?['nip'] ?? _pegawaiLocal['nip'] ?? '-';
    final jabatan =
        _data?['pegawai']?['jabatan'] ?? _pegawaiLocal['jabatan'] ?? '-';
    final unit = _data?['pegawai']?['unit'] ?? _pegawaiLocal['unit'] ?? '-';

    if (wide) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          body: Row(
            children: [
              _buildSidebar(nama, nip, jabatan, unit),
              Expanded(
                child: _buildMainContent(
                    context, nama, nip, jabatan, unit,
                    wide: true),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        drawer: Drawer(
          width: _sidebarWidth,
          backgroundColor: AppColors.canvas,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
          ),
          child: _buildSidebar(nama, nip, jabatan, unit),
        ),
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(),
        body: _buildMainContent(context, nama, nip, jabatan, unit,
            wide: false),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION — floating pill with animated active tab
  // ════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    final items = [
      _NavData(Icons.grid_view_rounded, 'Beranda'),
      _NavData(Icons.receipt_long_rounded, 'Laporan'),
      _NavData(null, 'Buat'), // center FAB
      _NavData(Icons.forum_rounded, 'Chat'),
      _NavData(Icons.person_outline_rounded, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.26),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = _bottomNavIndex == i;

              // Center "add" button — signature lime FAB
              if (i == 2) {
                return Hero(
                  tag: 'fab-create',
                  child: PressableScale(
                    onTap: () async {
                      final refresh = await Navigator.push<bool>(
                        context,
                        PremiumPageRoute(page: const LaporanFormPage()),
                      );
                      if (refresh == true) _loadData();
                    },
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.softLime,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softLime.withOpacity(0.55),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.black, size: 28),
                    ),
                  ),
                );
              }

              return Expanded(
                child: PressableScale(
                  onTap: () => _onNavTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: EdgeInsets.symmetric(
                        horizontal: selected ? 14 : 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.softLime
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: selected
                                ? AppColors.black
                                : Colors.white.withOpacity(0.7),
                          ),
                        ),
                        ClipRect(
                          child: AnimatedAlign(
                            alignment: Alignment.centerLeft,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            widthFactor: selected ? 1.0 : 0.0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: AnimatedOpacity(
                                duration:
                                    const Duration(milliseconds: 220),
                                opacity: selected ? 1 : 0,
                                curve: Curves.easeOut,
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _onNavTap(int i) {
    setState(() => _bottomNavIndex = i);
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.push(context,
            PremiumPageRoute(page: const RiwayatPage()));
        break;
      case 3:
        Navigator.push(context, PremiumPageRoute(page: const ChatPage()));
        break;
      case 4:
        Navigator.push(context, PremiumPageRoute(page: const ProfilPage()));
        break;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SIDEBAR (wide / drawer)
  // ════════════════════════════════════════════════════════════
  Widget _buildSidebar(String nama, String nip, String jabatan, String unit) {
    final menus = _menuItems();

    return Container(
      width: _sidebarWidth,
      color: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: AppColors.softLime,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SIPANTAW',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Profile card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                color: AppColors.black,
                shadow: const [],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AvatarWidget(name: nama, radius: 22, dark: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                jabatan,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'NIP $nip',
                        style: const TextStyle(
                          color: AppColors.softLime,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'NAVIGASI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: menus.length,
                itemBuilder: (context, i) {
                  final m = menus[i];
                  final selected = _selectedMenuIndex == i;
                  return _SidebarTile(
                    item: m,
                    selected: selected,
                    onTap: () => _handleMenuTap(m, i),
                  ).animate(delay: (40 * i).ms).fadeIn(duration: 400.ms).moveX(
                      begin: -8, end: 0, duration: 400.ms,
                      curve: Curves.easeOutCubic);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PremiumButton(
                label: 'Logout',
                leadingIcon: Icons.logout_rounded,
                onTap: _logout,
                outlined: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuTap(_MenuItem m, int index) async {
    setState(() => _selectedMenuIndex = index);
    // Close drawer on narrow layout
    if (!_isWide(context) && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (m.route == '/laporan') {
      final refresh = await Navigator.push<bool>(
        context,
        PremiumPageRoute(page: const LaporanFormPage()),
      );
      if (refresh == true) _loadData();
    } else if (m.route == '/absensi') {
      await Navigator.push(
          context, PremiumPageRoute(page: const AbsensiFotoPage()));
      _loadData();
    } else if (m.route == '/riwayat') {
      await Navigator.push(
          context, PremiumPageRoute(page: const RiwayatPage()));
    } else if (m.route == '/profil') {
      await Navigator.push(
          context, PremiumPageRoute(page: const ProfilPage()));
    } else if (m.route == '/cuti') {
      await Navigator.push(
          context, PremiumPageRoute(page: const CutiPage()));
      _loadData();
    } else if (m.route == '/lembur') {
      await Navigator.push(
          context, PremiumPageRoute(page: const LemburPage()));
    } else if (m.route == '/skp-target') {
      await Navigator.push(
          context, PremiumPageRoute(page: const SkpPage()));
    } else if (m.route == '/chat') {
      await Navigator.push(
          context, PremiumPageRoute(page: const ChatPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Halaman ${m.label} belum tersedia.'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ════════════════════════════════════════════════════════════
  Widget _buildMainContent(
    BuildContext context,
    String nama,
    String nip,
    String jabatan,
    String unit, {
    required bool wide,
  }) {
    return RefreshIndicator(
      color: AppColors.black,
      backgroundColor: AppColors.white,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.canvas,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Row(
              children: [
                if (!wide)
                  Builder(
                    builder: (ctx) => PressableScale(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppShadows.xs,
                        ),
                        child: const Icon(Icons.menu_rounded,
                            size: 20, color: AppColors.black),
                      ),
                    ),
                  ),
                if (!wide) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Halo, ${nama.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('EEEE, d MMM yyyy', 'id_ID')
                            .format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PressableScale(
                onTap: () => _showSearchSheet(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadows.xs,
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: AppColors.black, size: 20),
                ),
              ),
              PressableScale(
                onTap: () => _showNotifSheet(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadows.xs,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          color: AppColors.black, size: 20),
                      if (_notifikasi.isNotEmpty)
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.softLime,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _loading
                ? _buildLoadingState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBody(context, wide: wide, nama: nama),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          PremiumSkeleton(height: 180, radius: 28),
          SizedBox(height: 16),
          Row(children: [
            Expanded(child: PremiumSkeleton(height: 120, radius: 28)),
            SizedBox(width: 12),
            Expanded(child: PremiumSkeleton(height: 120, radius: 28)),
          ]),
          SizedBox(height: 16),
          PremiumSkeleton(height: 240, radius: 28),
          SizedBox(height: 16),
          PremiumSkeleton(height: 160, radius: 28),
        ],
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchSheet(
        controller: _searchController,
        laporanTerbaru: _laporanTerbaru,
        aktivitas: _aktivitas,
        onTapResult: () {
          Navigator.pop(ctx);
          Navigator.push(context,
              PremiumPageRoute(page: const RiwayatPage()));
        },
      ),
    );
  }

  void _showNotifSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotifSheet(notifikasi: _notifikasi),
    );
  }

  Widget _buildBody(BuildContext context,
      {required bool wide, required String nama}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = wide ? screenWidth - _sidebarWidth : screenWidth;
    final pad = contentWidth >= 700 ? 28.0 : 20.0;

    final sections = <Widget>[
      if (_error != null) _ErrorBanner(message: _error!),
      _buildHeroHeader(nama),
      _buildStatCards(contentWidth),
      _buildWfaChart(),
      _buildStatusAbsensiCard(),
      if (!wide) ...[
        const PremiumSectionHeader(title: 'Menu Utama'),
        _buildMenuGrid(),
      ],
      _buildCalendarCard(),
      if (_aktivitas.isNotEmpty) ...[
        PremiumSectionHeader(
          title: 'Aktivitas',
          action: 'Lihat Semua',
          onAction: () => Navigator.push(context,
              PremiumPageRoute(page: const RiwayatPage())),
        ),
        _buildAktivitas(),
      ],
      if (_laporanTerbaru.isNotEmpty) ...[
        PremiumSectionHeader(
          title: 'Laporan Terbaru',
          action: 'Lihat Semua',
          onAction: () => Navigator.push(context,
              PremiumPageRoute(page: const RiwayatPage())),
        ),
        _buildLaporanTerbaru(),
      ],
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 8, pad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            sections[i].premiumEntrance(index: i),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }

  // ── Hero header — big editorial black card ──────────────────
  Widget _buildHeroHeader(String nama) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 19
                ? 'Selamat Sore'
                : 'Selamat Malam';

    final totalLaporan =
        num.tryParse(_statistik['total_laporan']?.toString() ?? '') ?? 0;
    final totalWfa =
        num.tryParse(_statistik['total_hari_WFA']?.toString() ?? '') ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ambient glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.softLime.withOpacity(0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonCyan.withOpacity(0.18),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.softLime,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(
                                onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.4, 1.4),
                              duration: 900.ms,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(width: 8),
                        const Text(
                          'WFA Aktif',
                          style: TextStyle(
                            color: AppColors.softLime,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.waves_rounded,
                        color: AppColors.softLime, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$greeting,',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nama.split(' ').first,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 22),
              // Mini metrics pills
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: 'Laporan',
                      value: totalLaporan.toString(),
                      accent: AppColors.softLime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Hari WFA',
                      value: totalWfa.toString(),
                      accent: AppColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat cards — pastel accent tiles ────────────────────────
  Widget _buildStatCards(double contentWidth) {
    final isTablet = contentWidth >= 700;
    final wfaTotal = num.tryParse(_statistik['total_hari_WFA'].toString()) ?? 0;
    final laporanTotal =
        num.tryParse(_statistik['total_laporan'].toString()) ?? 0;
    final jamKerja =
        num.tryParse(_statistik['jam_kerja_rata'].toString()) ?? 0;
    final sisaCuti = num.tryParse(_cuti['sisa'].toString()) ?? 0;

    final stats = [
      _StatData(
        label: 'Hari WFA',
        value: wfaTotal.toString(),
        sub: 'Bulan ini',
        icon: Icons.home_work_rounded,
        background: AppColors.neonCyan,
        trend: '+4.5%',
        up: true,
      ),
      _StatData(
        label: 'Laporan',
        value: laporanTotal.toString(),
        sub: 'Diselesaikan',
        icon: Icons.article_rounded,
        background: AppColors.softLime,
        trend: '+2.1%',
        up: true,
      ),
      _StatData(
        label: 'Jam Kerja',
        value: jamKerja == jamKerja.toInt() ? '${jamKerja.toInt()}j' : '${jamKerja}j',
        sub: 'Rata-rata/hari',
        icon: Icons.timer_rounded,
        background: AppColors.pastelBlue,
        trend: '-0.8%',
        up: false,
      ),
      _StatData(
        label: 'Sisa Cuti',
        value: sisaCuti.toString(),
        sub: 'Hari tersisa',
        icon: Icons.event_available_rounded,
        background: AppColors.blush,
        trend: 'Stabil',
        up: true,
      ),
    ];

    return GridView.count(
      crossAxisCount: isTablet ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isTablet ? 1.1 : 1.0,
      children: [
        for (int i = 0; i < stats.length; i++)
          _StatCard(stat: stats[i])
              .animate(delay: (80 * i).ms)
              .fadeIn(duration: 500.ms)
              .moveY(
                  begin: 14,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic),
      ],
    );
  }

  // ── Chart card — clean monochrome line with accent fill ─────
  Widget _buildWfaChart() {
    final spots = _getChartSpots();
    final labels = _getChartLabels();
    final ranges = ['1D', '1W', '1M', '1Y'];

    double maxY = spots.fold<double>(0, (prev, s) => s.y > prev ? s.y : prev);
    maxY = (maxY * 1.4).ceilToDouble();
    if (maxY < 2) maxY = 2;

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tren WFA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _chartRange == '1D'
                        ? 'Status WFA per jam hari ini'
                        : _chartRange == '1W'
                            ? '7 hari terakhir'
                            : _chartRange == '1M'
                                ? 'Per minggu bulan ini'
                                : 'Per bulan tahun ini',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Range pills
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: ranges.map((r) {
                final active = _chartRange == r;
                return Expanded(
                  child: PressableScale(
                    onTap: () => setState(() => _chartRange = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.black : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Center(
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? AppColors.white
                                : AppColors.textSecondary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 180,
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (maxY / 4).clamp(0.5, double.infinity),
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border.withOpacity(0.7),
                          strokeWidth: 1,
                          dashArray: const [4, 6],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              final skip = labels.length > 8 ? 2 : 1;
                              if (i % skip != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.black,
                          tooltipRoundedRadius: 10,
                          getTooltipItems: (touched) => touched
                              .map((s) => LineTooltipItem(
                                    s.y.toStringAsFixed(0),
                                    const TextStyle(
                                      color: AppColors.softLime,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.38,
                          color: AppColors.black,
                          barWidth: 2.8,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter:
                                (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.softLime,
                              strokeWidth: 2.5,
                              strokeColor: AppColors.black,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.neonCyan.withOpacity(0.45),
                                AppColors.neonCyan.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: maxY,
                    ),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Status absensi ──────────────────────────────────────────
  Widget _buildStatusAbsensiCard() {
    final isHariKerja = _statusAbsensi['hari_kerja'] ?? true;
    final items = [
      _AbsenItem(
        label: 'Pagi',
        done: _statusAbsensi['pagi'] ?? false,
        icon: Icons.wb_twilight_rounded,
        color: AppColors.neonCyan,
      ),
      _AbsenItem(
        label: 'Siang',
        done: _statusAbsensi['siang'] ?? false,
        icon: Icons.wb_sunny_rounded,
        color: AppColors.softLime,
      ),
      _AbsenItem(
        label: 'Sore',
        done: _statusAbsensi['sore'] ?? false,
        icon: Icons.nights_stay_rounded,
        color: AppColors.pastelBlue,
      ),
      _AbsenItem(
        label: 'Laporan',
        done: _statusAbsensi['laporan'] ?? false,
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.blush,
      ),
    ];
    final doneCount = items.where((e) => e.done).length;

    return PremiumCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Hari Ini',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              AccentChip(
                label: '$doneCount / ${items.length}',
                color: AppColors.softLime,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!isHariKerja)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Text(
                  'Hari ini bukan hari kerja',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                return _AbsenBadge(item: entry.value)
                    .animate(delay: (60 * entry.key).ms)
                    .fadeIn(duration: 380.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 380.ms,
                      curve: Curves.easeOutCubic,
                    );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ── Menu grid (mobile) ──────────────────────────────────────
  Widget _buildMenuGrid() {
    final menus = _menuItems();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: List.generate(menus.length, (i) {
        final m = menus[i];
        return PressableScale(
          onTap: () => _handleMenuTap(m, i),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: m.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(m.icon, color: AppColors.black, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  m.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
            .animate(delay: (50 * i).ms)
            .fadeIn(duration: 400.ms)
            .moveY(
                begin: 10,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic);
      }),
    );
  }

  // ── Calendar card ───────────────────────────────────────────
  Widget _buildCalendarCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_calendarFocus),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  _IconBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => setState(() {
                      _calendarFocus = DateTime(
                          _calendarFocus.year, _calendarFocus.month - 1, 1);
                    }),
                  ),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => setState(() {
                      _calendarFocus = DateTime(
                          _calendarFocus.year, _calendarFocus.month + 1, 1);
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildCalendarGrid(),
          if (_aktivitas.isNotEmpty) ...[
            const SizedBox(height: 18),
            Divider(height: 1, color: AppColors.border.withOpacity(0.6)),
            const SizedBox(height: 16),
            const Text(
              'Agenda Terdekat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            _buildScheduleItems(),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final now = DateTime.now();
    final firstDay = DateTime(_calendarFocus.year, _calendarFocus.month, 1);
    final lastDay = DateTime(_calendarFocus.year, _calendarFocus.month + 1, 0);
    final startOffset = firstDay.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayNames
              .map((d) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 2,
          ),
          itemCount: startOffset + lastDay.day,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final date = DateTime(
                _calendarFocus.year, _calendarFocus.month, day);
            final isToday = day == now.day &&
                _calendarFocus.month == now.month &&
                _calendarFocus.year == now.year;
            final isSelected = _calendarSelected != null &&
                _calendarSelected!.year == date.year &&
                _calendarSelected!.month == date.month &&
                _calendarSelected!.day == date.day;
            final weekday = date.weekday;
            final isWeekend =
                weekday == DateTime.saturday || weekday == DateTime.sunday;

            return Center(
              child: PressableScale(
                onTap: () =>
                    setState(() => _calendarSelected = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonCyan
                        : (isToday
                            ? AppColors.black
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? null
                        : (isSelected
                            ? null
                            : Border.all(
                                color: Colors.transparent, width: 1)),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isToday
                            ? AppColors.softLime
                            : isSelected
                                ? AppColors.black
                                : isWeekend
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScheduleItems() {
    final palette = [
      AppColors.softLime,
      AppColors.neonCyan,
      AppColors.pastelBlue,
      AppColors.blush,
    ];
    return Column(
      children: _aktivitas.take(3).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value as Map;
        final c = palette[i % palette.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['text']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['time']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Aktivitas timeline ──────────────────────────────────────
  Widget _buildAktivitas() {
    return PremiumCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: _aktivitas.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value as Map;
          final isLast = i == _aktivitas.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded,
                          color: AppColors.softLime, size: 18),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['text']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a['time']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
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

  // ── Laporan terbaru ─────────────────────────────────────────
  Widget _buildLaporanTerbaru() {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: _laporanTerbaru.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value as Map;
          final isLast = i == _laporanTerbaru.length - 1;
          final status = l['status']?.toString() ?? '-';
          final statusMap = <String, Color>{
            'Disetujui': AppColors.softLime,
            'Ditolak': AppColors.blush,
            'Pending': AppColors.neonCyan,
          };
          final chipColor = statusMap[status] ?? AppColors.surfaceMuted;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.article_rounded,
                          color: AppColors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l['kegiatan']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l['tanggal']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AccentChip(label: status, color: chipColor),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: AppColors.border.withOpacity(0.7)),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<_MenuItem> _menuItems() => const [
        _MenuItem('Absensi', Icons.fingerprint_rounded,
            AppColors.neonCyan, '/absensi'),
        _MenuItem('Laporan', Icons.edit_note_rounded,
            AppColors.softLime, '/laporan'),
        _MenuItem('Riwayat', Icons.manage_history_rounded,
            AppColors.pastelBlue, '/riwayat'),
        _MenuItem('Cuti', Icons.luggage_rounded, AppColors.blush, '/cuti'),
        _MenuItem('Lembur', Icons.more_time_rounded,
            AppColors.softLime, '/lembur'),
        _MenuItem('SKP', Icons.military_tech_rounded,
            AppColors.pastelBlue, '/skp-target'),
        _MenuItem('Profil', Icons.manage_accounts_rounded,
            AppColors.blush, '/profil'),
        _MenuItem('Chat', Icons.forum_rounded, AppColors.neonCyan, '/chat'),
      ];
}

// ══════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════
class _NavData {
  final IconData? icon;
  final String label;
  _NavData(this.icon, this.label);
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label, value, sub, trend;
  final IconData icon;
  final Color background;
  final bool up;

  const _StatData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.background,
    required this.trend,
    required this.up,
  });
}

class _StatCard extends StatefulWidget {
  final _StatData stat;
  const _StatCard({required this.stat});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: widget.stat.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: _hover ? AppShadows.md : AppShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.stat.icon,
                    color: widget.stat.background,
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.stat.up
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 11,
                        color: AppColors.black,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.stat.trend,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.stat.value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.stat.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.stat.sub,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AbsenItem {
  final String label;
  final bool done;
  final IconData icon;
  final Color color;

  const _AbsenItem({
    required this.label,
    required this.done,
    required this.icon,
    required this.color,
  });
}

class _AbsenBadge extends StatelessWidget {
  final _AbsenItem item;
  const _AbsenBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: item.done ? AppColors.black : item.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: item.done
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            item.done ? Icons.check_rounded : item.icon,
            color: item.done ? item.color : AppColors.black,
            size: 26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: item.done
                ? AppColors.textPrimary
                : AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String name;
  final double radius;
  final bool dark;

  const _AvatarWidget({
    required this.name,
    required this.radius,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: dark ? AppColors.softLime : AppColors.black,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.w900,
            color: dark ? AppColors.black : AppColors.softLime,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? item.accent : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: AppColors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.softLime,
              ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.black),
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

class _MenuItem {
  final String label, route;
  final IconData icon;
  final Color accent;
  const _MenuItem(this.label, this.icon, this.accent, this.route);
}

// ══════════════════════════════════════════════════════════════
// SEARCH SHEET
// ══════════════════════════════════════════════════════════════
class _SearchSheet extends StatefulWidget {
  final TextEditingController controller;
  final List laporanTerbaru;
  final List aktivitas;
  final VoidCallback onTapResult;

  const _SearchSheet({
    required this.controller,
    required this.laporanTerbaru,
    required this.aktivitas,
    required this.onTapResult,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.laporanTerbaru.where((l) {
      final kegiatan =
          (l as Map)['kegiatan']?.toString().toLowerCase() ?? '';
      return _query.isEmpty || kegiatan.contains(_query.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: PremiumInput(
                controller: widget.controller,
                hint: 'Cari laporan, aktivitas...',
                icon: Icons.search_rounded,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.search_off_rounded,
                                size: 32,
                                color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _query.isEmpty
                                ? 'Mulai ketik untuk mencari'
                                : 'Tidak ada hasil',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(
                        height: 10,
                      ),
                      itemBuilder: (context, i) {
                        final l = filtered[i] as Map;
                        final status = l['status']?.toString() ?? '-';
                        final statusMap = <String, Color>{
                          'Disetujui': AppColors.softLime,
                          'Ditolak': AppColors.blush,
                          'Pending': AppColors.neonCyan,
                        };
                        final c =
                            statusMap[status] ?? AppColors.surfaceMuted;

                        return PressableScale(
                          onTap: widget.onTapResult,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.article_rounded,
                                      color: AppColors.black,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l['kegiatan']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l['tanggal']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AccentChip(label: status, color: c),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// NOTIFICATION SHEET
// ══════════════════════════════════════════════════════════════
class _NotifSheet extends StatelessWidget {
  final List notifikasi;
  const _NotifSheet({required this.notifikasi});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: notifikasi.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.notifications_off_rounded,
                                size: 32,
                                color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Belum ada notifikasi',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: notifikasi.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final n = notifikasi[i] as Map;
                        final level =
                            n['level']?.toString() ?? 'info';
                        final accent = switch (level) {
                          'warning' => AppColors.softLime,
                          'danger' => AppColors.blush,
                          'success' => AppColors.softLime,
                          _ => AppColors.neonCyan,
                        };
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(
                                AppRadius.md),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.campaign_rounded,
                                    color: AppColors.black,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['judul']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['pesan']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
