import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import '../../core/services/biometric_service.dart';
import '../../core/storage/token_storage.dart';
import 'auth_service.dart';

/// Halaman login dengan Face ID — muncul setelah logout jika biometric aktif.
/// User tidak perlu ketik NIP lagi, cukup verifikasi wajah/sidik jari.
class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({super.key});

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

class _BiometricLoginPageState extends State<BiometricLoginPage>
    with TickerProviderStateMixin {
  bool _loading = false;
  bool _authenticated = false;
  String? _error;
  String? _savedNama;
  String? _savedNip;
  bool _hasFaceId = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final pegawai = await TokenStorage.getPegawai();
    final hasFace = await BiometricService.hasFaceId();
    final nip = await BiometricService.getSavedNip();
    if (mounted) {
      setState(() {
        _savedNama = pegawai['nama'];
        _savedNip = nip;
        _hasFaceId = hasFace;
      });
      // Auto-trigger biometric saat halaman terbuka
      Future.delayed(const Duration(milliseconds: 600), _authenticate);
    }
  }

  Future<void> _authenticate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Verifikasi biometrik (Face ID / fingerprint)
      final ok = await BiometricService.authenticate(
        reason: 'Verifikasi identitas untuk masuk ke SIPANTAW WFA',
      );

      if (!ok) {
        setState(() {
          _error = 'Verifikasi gagal. Coba lagi atau gunakan NIP.';
          _loading = false;
        });
        return;
      }

      // Step 2: Restore session dari biometric token
      final success = await AuthService.loginWithBiometric();

      if (!success) {
        setState(() {
          _error = 'Sesi tidak ditemukan. Silakan login dengan NIP.';
          _loading = false;
        });
        return;
      }

      // Step 3: Animasi sukses → navigasi ke dashboard
      setState(() {
        _authenticated = true;
        _loading = false;
      });
      await _successCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan. Coba lagi.';
        _loading = false;
      });
    }
  }

  void _goToNipLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            // Ambient orbs
            Positioned(
              top: -120,
              right: -80,
              child: _Orb(
                size: 280,
                color: AppColors.neonCyan.withOpacity(0.35),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _Orb(
                size: 260,
                color: AppColors.softLime.withOpacity(0.35),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  color: AppColors.softLime, size: 7),
                              SizedBox(width: 7),
                              Text(
                                'SIPANTAW',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Gunakan NIP
                        PressableScale(
                          onTap: _goToNipLogin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'Gunakan NIP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Greeting
                    if (_savedNama != null)
                      Column(
                        children: [
                          Text(
                            'Selamat datang kembali,',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                          const SizedBox(height: 6),
                          Text(
                            _savedNama!.split(' ').first,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -1.4,
                              height: 1.05,
                            ),
                          )
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 400.ms)
                              .moveY(begin: 10, end: 0, duration: 400.ms),
                        ],
                      ),

                    const SizedBox(height: 52),

                    // Face ID button — besar, iOS style
                    _buildFaceIdButton(),

                    const SizedBox(height: 28),

                    // Status / error
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _error != null
                          ? _buildErrorBox(_error!)
                          : _loading && !_authenticated
                              ? const _LoadingStatus()
                              : _authenticated
                                  ? const _SuccessStatus()
                                  : _buildHintText(),
                    ),

                    const Spacer(flex: 3),

                    // Footer
                    const Text(
                      'Diproteksi dengan enkripsi end-to-end',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceIdButton() {
    return PressableScale(
      onTap: (_loading || _authenticated) ? () {} : _authenticate,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _loading ? 1.0 : _pulseAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: _authenticated
                ? AppColors.softLime
                : _loading
                    ? AppColors.surfaceMuted
                    : AppColors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_authenticated
                        ? AppColors.softLime
                        : AppColors.black)
                    .withOpacity(0.28),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: _loading && !_authenticated
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 3,
                    ),
                  )
                : _authenticated
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.black,
                        size: 60,
                      )
                    : Icon(
                        _hasFaceId
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                        color: AppColors.softLime,
                        size: 64,
                      ),
          ),
        ),
      ),
    )
        .animate(delay: 400.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildHintText() {
    return Column(
      key: const ValueKey('hint'),
      children: [
        Text(
          _hasFaceId ? 'Ketuk untuk Face ID' : 'Ketuk untuk sidik jari',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _savedNip != null ? 'NIP: ${_maskNip(_savedNip!)}' : '',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      key: const ValueKey('error'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: _authenticate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'Coba lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).shake(
        hz: 4, offset: const Offset(3, 0), duration: 260.ms);
  }

  String _maskNip(String nip) {
    if (nip.length <= 6) return nip;
    return '${nip.substring(0, 4)}••••${nip.substring(nip.length - 4)}';
  }
}

// ── Loading status ────────────────────────────────────────────
class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            color: AppColors.textMuted,
            strokeWidth: 2,
          ),
        ),
        SizedBox(width: 10),
        Text(
          'Memverifikasi...',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Success status ────────────────────────────────────────────
class _SuccessStatus extends StatelessWidget {
  const _SuccessStatus();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded,
            color: Color(0xFF4CAF8C), size: 18),
        SizedBox(width: 8),
        Text(
          'Berhasil! Membuka dashboard...',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF4CAF8C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Orb ──────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}
