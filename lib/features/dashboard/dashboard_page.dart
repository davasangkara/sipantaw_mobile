import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_service.dart';
import '../laporan/laporan_form_page.dart';
import '../absensi/absensi_page.dart';
import '../riwayat/riwayat_page.dart';
import '../profil/profil_page.dart';
import '../cuti/cuti_page.dart';
import '../lembur/lembur_page.dart';
import '../skp/skp_page.dart';
import 'package:sipantaw_mobile/features/cuti/cuti_form_page.dart';
import 'package:sipantaw_mobile/features/chat/chat_page.dart';
import '../absensi/absensi_foto_page.dart';

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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;
  static const _sidebarWidth = 260.0;
  static const _breakpoint = 800.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Logout',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textDark)),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
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
    switch (_chartRange) {
      case '1D':
        final raw = _statistik['wfa_per_jam'];
        if (raw is List && raw.isNotEmpty) {
          return raw
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble()))
              .toList();
        }
        return [0, 1, 0, 1, 1, 0, 1, 1]
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

      case '1W':
        final raw = _statistik['wfa_per_hari'];
        if (raw is List && raw.isNotEmpty) {
          return raw
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble()))
              .toList();
        }
        return [0, 1, 1, 0, 1, 1, 0]
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

      case '1M':
        final raw = _statistik['wfa_per_minggu'];
        if (raw is List && raw.isNotEmpty) {
          return raw
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble()))
              .toList();
        }
        final total = (_statistik['total_hari_WFA'] ?? 12) as num;
        final d = total.toDouble();
        return [d * 0.2, d * 0.3, d * 0.25, d * 0.25]
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();

      case '1Y':
        final raw = _statistik['wfa_per_bulan'];
        if (raw is List && raw.isNotEmpty) {
          return raw
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble()))
              .toList();
        }
        final total = (_statistik['total_hari_WFA'] ?? 12) as num;
        return List.generate(12, (i) {
          final v = total.toDouble() * (0.5 + 0.1 * ((i % 3) - 1));
          return FlSpot(i.toDouble(), v.clamp(0, double.infinity));
        });

      default:
        return [];
    }
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
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agt',
          'Sep',
          'Okt',
          'Nov',
          'Des'
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
      return Scaffold(
        backgroundColor: _bg,
        body: Row(
          children: [
            _buildSidebar(nama, nip, jabatan, unit),
            Expanded(
              child: _buildMainContent(context, nama, nip, jabatan, unit,
                  wide: true),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      drawer: Drawer(
        width: _sidebarWidth,
        child: _buildSidebar(nama, nip, jabatan, unit),
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: _buildMainContent(context, nama, nip, jabatan, unit, wide: false),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.04), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(
                  icon: Icons.grid_view_rounded,
                  label: 'Beranda',
                  selected: _bottomNavIndex == 0,
                  onTap: () => setState(() => _bottomNavIndex = 0),
                ),
                _NavBtn(
                  icon: Icons.folder_copy_rounded,
                  label: 'Laporan',
                  selected: _bottomNavIndex == 1,
                  onTap: () {
                    setState(() => _bottomNavIndex = 1);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RiwayatPage()));
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final refresh = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LaporanFormPage()),
                    );
                    if (refresh == true) _loadData();
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2FB0C2), Color(0xFF0B6E7F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _teal.withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
                _NavBtn(
                  icon: Icons.forum_rounded,
                  label: 'Chat',
                  selected: _bottomNavIndex == 2,
                  onTap: () {
                    setState(() => _bottomNavIndex = 2);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ChatPage()));
                  },
                ),
                _NavBtn(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  selected: _bottomNavIndex == 3,
                  onTap: () {
                    setState(() => _bottomNavIndex = 3);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfilPage()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(String nama, String nip, String jabatan, String unit) {
    final menus = _menuItems();

    return Container(
      width: _sidebarWidth,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2FB0C2), Color(0xFF0B6E7F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: AppShadows.tinted(AppColors.teal,
                          opacity: 0.3),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SiPantaw',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2FB0C2), Color(0xFF1C8A9C), Color(0xFF0B6E7F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.55, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.tinted(AppColors.teal, opacity: 0.28),
                ),
                child: Row(
                  children: [
                    _AvatarWidget(name: nama, radius: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            jabatan,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.82)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'NIP: $nip',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'NAVIGASI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[400],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: _logout,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppColors.danger, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuTap(_MenuItem m, int index) async {
    setState(() => _selectedMenuIndex = index);
    if (m.route == '/laporan') {
      final refresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LaporanFormPage()),
      );
      if (refresh == true) _loadData();
    } else if (m.route == '/absensi') {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AbsensiFotoPage())); // ← ganti AbsensiPage
      _loadData();
    } else if (m.route == '/riwayat') {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const RiwayatPage()));
    } else if (m.route == '/profil') {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfilPage()));
    } else if (m.route == '/cuti') {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CutiPage()));
      _loadData();
    } else if (m.route == '/lembur') {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LemburPage()));
    } else if (m.route == '/skp-target') {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SkpPage()));
    } else if (m.route == '/chat') {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ChatPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Halaman ${m.label} belum tersedia.'),
        duration: const Duration(seconds: 2),
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    String nama,
    String nip,
    String jabatan,
    String unit, {
    required bool wide,
  }) {
    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: !wide,
            iconTheme: const IconThemeData(color: _textDark),
            toolbarHeight: 64,
            title: wide
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        nama.split(' ').first,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
            actions: [
              GestureDetector(
                onTap: () => _showSearchSheet(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: _textDark, size: 20),
                ),
              ),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: _AvatarWidget(name: nama, radius: 18),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.withOpacity(0.08)),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: _teal, strokeWidth: 2.5),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBody(context, wide: wide, nama: nama),
                  ),
          ),
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
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const RiwayatPage()));
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context,
      {required bool wide, required String nama}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = wide ? screenWidth - _sidebarWidth : screenWidth;
    final pad = contentWidth >= 700 ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          if (_notifikasi.isNotEmpty) ...[
            ..._notifikasi.map((n) => _NotifBanner(data: n as Map)),
            const SizedBox(height: 8),
          ],
          _buildWelcomeHeader(nama),
          const SizedBox(height: 20),
          _buildStatCards(contentWidth),
          const SizedBox(height: 24),
          _buildWfaChart(),
          const SizedBox(height: 24),
          _buildStatusAbsensiCard(),
          const SizedBox(height: 24),
          if (!wide) ...[
            _SectionHeader(title: 'Menu Utama'),
            const SizedBox(height: 12),
            _buildMenuGrid(),
            const SizedBox(height: 24),
          ],
          _buildCalendarCard(),
          const SizedBox(height: 24),
          if (_aktivitas.isNotEmpty) ...[
            _SectionHeader(
              title: 'Aktivitas Hari Ini',
              action: 'Lihat Semua',
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RiwayatPage())),
            ),
            const SizedBox(height: 12),
            _buildAktivitas(),
            const SizedBox(height: 24),
          ],
          if (_laporanTerbaru.isNotEmpty) ...[
            _SectionHeader(
              title: 'Laporan Terbaru',
              action: 'Lihat Semua',
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RiwayatPage())),
            ),
            const SizedBox(height: 12),
            _buildLaporanTerbaru(),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String nama) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 19
                ? 'Selamat Sore'
                : 'Selamat Malam';
    final dateLabel = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(now);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FB0C2), Color(0xFF1C8A9C), Color(0xFF0B6E7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.tinted(_teal, opacity: 0.32),
      ),
      child: Stack(
        children: [
          // Decorative orb
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4CD6C1).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CD6C1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'WFA Aktif',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$greeting,',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nama.split(' ').first,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: Colors.white, size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(double contentWidth) {
    final isTablet = contentWidth >= 600;
    final wfaTotal = num.tryParse(_statistik['total_hari_WFA'].toString()) ?? 0;

    final laporanTotal =
        num.tryParse(_statistik['total_laporan'].toString()) ?? 0;

    final jamKerja = num.tryParse(_statistik['jam_kerja_rata'].toString()) ?? 0;

    final sisaCuti = num.tryParse(_cuti['sisa'].toString()) ?? 0;

    final stats = [
      _StatData(
          label: 'Hari WFA',
          value: wfaTotal.toString(),
          sub: 'Bulan ini',
          icon: Icons.home_work_rounded,
          color: _teal,
          trend: '+4.5%',
          up: true),
      _StatData(
          label: 'Total Laporan',
          value: laporanTotal.toString(),
          sub: 'Diselesaikan',
          icon: Icons.article_rounded,
          color: AppColors.indigo,
          trend: '+2.1%',
          up: true),
      _StatData(
          label: 'Rata Jam Kerja',
          value: '${jamKerja}j',
          sub: 'Per hari',
          icon: Icons.timer_rounded,
          color: AppColors.amber,
          trend: '-0.8%',
          up: false),
      _StatData(
          label: 'Sisa Cuti',
          value: sisaCuti.toString(),
          sub: 'Hari tersisa',
          icon: Icons.event_available_rounded,
          color: AppColors.success,
          trend: 'Stabil',
          up: true),
    ];

    return GridView.count(
      crossAxisCount: isTablet ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isTablet ? 1.3 : 1.1,
      children: stats.map((s) => _StatCard(stat: s)).toList(),
    );
  }

  Widget _buildWfaChart() {
    final spots = _getChartSpots();
    final labels = _getChartLabels();
    final ranges = ['1D', '1W', '1M', '1Y'];

    double maxY = spots.fold(0, (prev, s) => s.y > prev ? s.y : prev);
    maxY = (maxY * 1.4).ceilToDouble();
    if (maxY < 2) maxY = 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Tren WFA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: ranges.map((r) {
                    final active = _chartRange == r;
                    return GestureDetector(
                      onTap: () => setState(() => _chartRange = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? AppColors.teal
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _chartRange == '1D'
                ? 'Status WFA per jam hari ini'
                : _chartRange == '1W'
                    ? 'Hari WFA dalam 7 hari terakhir'
                    : _chartRange == '1M'
                        ? 'Hari WFA per minggu bulan ini'
                        : 'Hari WFA per bulan tahun ini',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: spots.isEmpty
                ? Center(
                    child: Text('Tidak ada data',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (maxY / 4).clamp(0.5, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.08),
                          strokeWidth: 1,
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
                              if (i < 0 || i >= labels.length)
                                return const SizedBox.shrink();
                              final skip = labels.length > 8 ? 2 : 1;
                              if (i % skip != 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
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
                          getTooltipColor: (_) => _textDark,
                          getTooltipItems: (touchedSpots) => touchedSpots
                              .map((s) => LineTooltipItem(
                                    s.y.toStringAsFixed(0),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: _teal,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 3.5,
                              color: Colors.white,
                              strokeWidth: 2.5,
                              strokeColor: _teal,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                _teal.withOpacity(0.15),
                                _teal.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: maxY,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAbsensiCard() {
    final isHariKerja = _statusAbsensi['hari_kerja'] ?? true;
    final items = [
      _AbsenItem(
          label: 'Pagi',
          done: _statusAbsensi['pagi'] ?? false,
          icon: Icons.wb_twilight_rounded,
          color: const Color(0xFFF4A261)),
      _AbsenItem(
          label: 'Siang',
          done: _statusAbsensi['siang'] ?? false,
          icon: Icons.wb_sunny_rounded,
          color: const Color(0xFFFFD600)),
      _AbsenItem(
          label: 'Sore',
          done: _statusAbsensi['sore'] ?? false,
          icon: Icons.nights_stay_rounded,
          color: const Color(0xFF5C6BC0)),
      _AbsenItem(
          label: 'Laporan',
          done: _statusAbsensi['laporan'] ?? false,
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF4CAF8C)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Status Hari Ini'),
          const SizedBox(height: 16),
          if (!isHariKerja)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Hari ini bukan hari kerja',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) => _AbsenBadge(item: item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menus = _menuItems();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.88,
      children: menus.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;

        return GestureDetector(
          onTap: () => _handleMenuTap(m, i),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: m.color.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        m.color.withOpacity(0.22),
                        m.color.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: m.color.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(m.icon, color: m.color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  m.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_calendarFocus),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
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
                  const SizedBox(width: 4),
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
          const SizedBox(height: 14),
          _buildCalendarGrid(),
          if (_aktivitas.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 14),
            Text(
              'Agenda',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
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
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
          ),
          itemCount: startOffset + lastDay.day,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final isToday = day == now.day &&
                _calendarFocus.month == now.month &&
                _calendarFocus.year == now.year;

            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isToday ? _teal : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                      color: isToday ? Colors.white : _textDark,
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
    final colorMap = <String, Color>{
      'orange': const Color(0xFFF4A261),
      'green': const Color(0xFF4CAF8C),
      'blue': const Color(0xFF5C6BC0),
      'purple': const Color(0xFF9C6BC0),
      'red': Colors.red,
    };

    return Column(
      children: _aktivitas.take(3).map((a) {
        final aMap = a as Map;
        final color = colorMap[aMap['color']] ?? Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aMap['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      aMap['time'] ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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

  Widget _buildAktivitas() {
    final colorMap = <String, Color>{
      'orange': AppColors.amber,
      'green': AppColors.success,
      'blue': AppColors.indigo,
      'purple': AppColors.violet,
      'red': AppColors.danger,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: _aktivitas.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value as Map;
          final isLast = i == _aktivitas.length - 1;
          final color = colorMap[a['color']] ?? Colors.grey;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 24, color: Colors.grey[100]),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a['time'] ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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

  Widget _buildLaporanTerbaru() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: _laporanTerbaru.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value as Map;
          final isLast = i == _laporanTerbaru.length - 1;
          final status = l['status']?.toString() ?? '-';
          final statusMap = <String, List<Color>>{
            'Disetujui': [const Color(0xFF4CAF8C), const Color(0xFFE8F8F2)],
            'Ditolak': [Colors.red, const Color(0xFFFFEEEE)],
            'Pending': [const Color(0xFFF4A261), const Color(0xFFFFF5EE)],
          };
          final c = statusMap[status] ?? [Colors.grey, Colors.grey[100]!];

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _tealLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.article_rounded,
                          color: _teal, size: 20),
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
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            l['tanggal']?.toString() ?? '-',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c[1],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: c[0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 16,
                    color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<_MenuItem> _menuItems() => const [
        _MenuItem('Absensi', Icons.fingerprint_rounded, AppColors.teal,
            '/absensi'),
        _MenuItem('Laporan', Icons.edit_note_rounded, AppColors.indigo,
            '/laporan'),
        _MenuItem('Riwayat', Icons.manage_history_rounded,
            AppColors.mint, '/riwayat'),
        _MenuItem('Cuti', Icons.luggage_rounded, AppColors.success, '/cuti'),
        _MenuItem('Lembur', Icons.more_time_rounded, AppColors.amber,
            '/lembur'),
        _MenuItem('SKP', Icons.military_tech_rounded, AppColors.violet,
            '/skp-target'),
        _MenuItem('Profil', Icons.manage_accounts_rounded,
            Color(0xFF64748B), '/profil'),
        _MenuItem('Chat', Icons.forum_rounded, AppColors.coral, '/chat'),
      ];
}

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

  static const _teal = AppColors.teal;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.laporanTerbaru.where((l) {
      final kegiatan = (l as Map)['kegiatan']?.toString().toLowerCase() ?? '';
      return _query.isEmpty || kegiatan.contains(_query.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: widget.controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari laporan, aktivitas...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: _teal),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            widget.controller.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(Icons.close_rounded,
                              color: Colors.grey[400]),
                        )
                      : null,
                  filled: true,
                  fillColor: _bg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty
                                ? 'Mulai ketik untuk mencari'
                                : 'Tidak ada hasil',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (context, i) {
                        final l = filtered[i] as Map;
                        final status = l['status']?.toString() ?? '-';
                        final statusMap = <String, List<Color>>{
                          'Disetujui': [
                            const Color(0xFF4CAF8C),
                            const Color(0xFFE8F8F2)
                          ],
                          'Ditolak': [Colors.red, const Color(0xFFFFEEEE)],
                          'Pending': [
                            const Color(0xFFF4A261),
                            const Color(0xFFFFF5EE)
                          ],
                        };
                        final c = statusMap[status] ??
                            [Colors.grey, Colors.grey[100]!];

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F5F8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.article_rounded,
                                color: _teal, size: 18),
                          ),
                          title: Text(
                            l['kegiatan']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          subtitle: Text(
                            l['tanggal']?.toString() ?? '-',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c[1],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: c[0],
                              ),
                            ),
                          ),
                          onTap: widget.onTapResult,
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

class _AvatarWidget extends StatelessWidget {
  final String name;
  final double radius;

  const _AvatarWidget({required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A9DAE), Color(0xFF1A7A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          item.color.withOpacity(0.22),
                          item.color.withOpacity(0.10),
                        ],
                      )
                    : null,
                color: selected ? null : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                item.icon,
                color: selected ? item.color : AppColors.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.teal
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppColors.teal : AppColors.textMuted,
                size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.teal : AppColors.textMuted,
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4A5568)),
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
          duration: const Duration(milliseconds: 320),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: item.done
                ? const LinearGradient(
                    colors: [Color(0xFF2FB0C2), Color(0xFF0B6E7F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: item.done ? null : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: item.done
                ? [
                    BoxShadow(
                      color: AppColors.teal.withOpacity(0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            item.done ? Icons.check_rounded : item.icon,
            color: item.done ? Colors.white : item.color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: item.done ? AppColors.teal : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.mint, AppColors.teal],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: const [
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.teal),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatData {
  final String label, value, sub, trend;
  final IconData icon;
  final Color color;
  final bool up;

  const _StatData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.trend,
    required this.up,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stat.color.withOpacity(0.18),
                      stat.color.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: stat.color.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: stat.up
                      ? AppColors.successSoft
                      : AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stat.up
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 10,
                      color:
                          stat.up ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      stat.trend,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color:
                            stat.up ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            stat.sub,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
              style: TextStyle(color: Colors.red[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifBanner extends StatelessWidget {
  final Map data;

  const _NotifBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final level = data['level'] ?? 'info';
    final scheme = <String, List<Color>>{
      'warning': [Colors.orange[50]!, Colors.orange[200]!, Colors.orange[700]!],
      'danger': [Colors.red[50]!, Colors.red[200]!, Colors.red[700]!],
      'success': [
        const Color(0xFFE8F8F2),
        const Color(0xFF4CAF8C),
        const Color(0xFF2D7A5F)
      ],
      'info': [Colors.blue[50]!, Colors.blue[200]!, Colors.blue[700]!],
    };
    final c = scheme[level] ?? scheme['info']!;
    final icons = <String, IconData>{
      'warning': Icons.warning_amber_rounded,
      'danger': Icons.error_outline_rounded,
      'success': Icons.check_circle_outline_rounded,
      'info': Icons.info_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c[1].withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icons[level] ?? Icons.info_outline_rounded,
              color: c[2], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['judul'] ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: c[2], fontSize: 13),
                ),
                Text(
                  data['pesan'] ?? '',
                  style: TextStyle(color: c[2].withOpacity(0.8), fontSize: 12),
                ),
              ],
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
  final Color color;

  const _MenuItem(this.label, this.icon, this.color, this.route);
}
