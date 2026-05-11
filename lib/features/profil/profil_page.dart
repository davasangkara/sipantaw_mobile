import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import '../auth/auth_service.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _uploadingFoto = false;
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
      final res = await ApiClient.get(ApiConfig.profil);
      setState(() {
        _data = res.data['data'];
        _loading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat profil.';
      });
    }
  }

  Future<void> _uploadFoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _teal),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _teal),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() => _uploadingFoto = true);

    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await ApiClient.post('${ApiConfig.profil}/foto', data: {'foto': base64});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: _teal,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupload foto.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _uploadingFoto = false);
    }
  }

  Future<void> _hapusFoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Foto'),
        content: const Text('Yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _uploadingFoto = true);
    try {
      await ApiClient.delete('${ApiConfig.profil}/foto');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus.'),
            backgroundColor: _teal,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus foto.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _uploadingFoto = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await AuthService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
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
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Akun',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Profil Saya',
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
              GestureDetector(
                onTap: _logout,
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 14, color: AppColors.danger),
                      SizedBox(width: 5),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
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
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: 12),
                            _buildStatCard(),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.person_outline,
                              title: 'Informasi Pegawai',
                              items: [
                                _InfoItem(
                                    'NIP', _data?['pegawai']?['nip'] ?? '-'),
                                _InfoItem(
                                    'Nama', _data?['pegawai']?['nama'] ?? '-'),
                                _InfoItem('Jabatan',
                                    _data?['pegawai']?['jabatan'] ?? '-'),
                                _InfoItem(
                                    'Unit', _data?['pegawai']?['unit'] ?? '-'),
                                _InfoItem('Jenis Pegawai',
                                    _data?['pegawai']?['jenis_pegawai'] ?? '-'),
                                _InfoItem('Email',
                                    _data?['pegawai']?['email'] ?? '-'),
                                _InfoItem('Telepon',
                                    _data?['pegawai']?['telephone'] ?? '-'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCard(
                              icon: Icons.location_on_outlined,
                              title: 'Alamat',
                              items: [
                                _InfoItem('Jalan',
                                    _data?['alamat']?['jalan'] ?? '-'),
                                _InfoItem(
                                    'RT/RW', _data?['alamat']?['rtrw'] ?? '-'),
                                _InfoItem('Kelurahan',
                                    _data?['alamat']?['kelurahan'] ?? '-'),
                                _InfoItem('Kode Kel.',
                                    _data?['alamat']?['kode_kelurahan'] ?? '-'),
                                _InfoItem('Kecamatan',
                                    _data?['alamat']?['kecamatan'] ?? '-'),
                                _InfoItem('Kode Kec.',
                                    _data?['alamat']?['kode_kecamatan'] ?? '-'),
                                _InfoItem('Kab/Kota',
                                    _data?['alamat']?['kabkota'] ?? '-'),
                                _InfoItem('Provinsi',
                                    _data?['alamat']?['propinsi'] ?? '-'),
                              ],
                            ),
                            if (_data?['pegawai']?['photo_url'] != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _uploadingFoto ? null : _hapusFoto,
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  label: const Text('Hapus Foto Profil',
                                      style: TextStyle(color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final nama = _data?['pegawai']?['nama'] ?? '-';
    final jabatan = _data?['pegawai']?['jabatan'] ?? '-';
    final unit = _data?['pegawai']?['unit'] ?? '';
    final photoUrl = _data?['pegawai']?['photo_url'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FB0C2), Color(0xFF1C8A9C), Color(0xFF0B6E7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.tinted(AppColors.teal, opacity: 0.32),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
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
            left: -25,
            child: Container(
              width: 110,
              height: 110,
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
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl.toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(nama),
                            )
                          : _avatarFallback(nama),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _uploadingFoto ? null : _uploadFoto,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _teal, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: _uploadingFoto
                            ? const Padding(
                                padding: EdgeInsets.all(5),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _teal,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                size: 14, color: _teal),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CD6C1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'PEGAWAI AKTIF',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jabatan,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (unit.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          unit.toString(),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withOpacity(0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String nama) => Container(
        color: _tealLight,
        child: Center(
          child: Text(
            nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _teal,
            ),
          ),
        ),
      );

  Widget _buildStatCard() {
    final statistik = _data?['statistik'] ?? {};
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              Icons.description_outlined,
              statistik['total_laporan']?.toString() ?? '0',
              'Total Laporan',
              _teal,
              _tealLight,
            ),
          ),
          Container(width: 1, height: 48, color: Colors.grey[100]),
          Expanded(
            child: _statItem(
              Icons.calendar_today_rounded,
              statistik['laporan_bulan_ini']?.toString() ?? '0',
              'Bulan Ini',
              const Color(0xFF3F51B5),
              const Color(0xFFEEF0FB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    IconData icon,
    String value,
    String label,
    Color color,
    Color bg,
  ) =>
      Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      );

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<_InfoItem> items,
  }) =>
      Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _teal, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(
                      bottom: e.key < items.length - 1 ? 10 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          e.value.label,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ),
                      const Text(': ',
                          style: TextStyle(color: Colors.grey)),
                      Expanded(
                        child: Text(
                          e.value.value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
}

class _InfoItem {
  final String label, value;
  const _InfoItem(this.label, this.value);
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