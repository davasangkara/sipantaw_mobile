import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import '../../core/services/biometric_service.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _nipController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());
  final _phoneController = TextEditingController();

  String? _tempKey;
  String? _maskedPhone;
  bool _loading = false;
  bool _showOtp = false;
  bool _showPhone = false;
  String? _error;

 
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;
  String? _savedNip;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final nip = await BiometricService.getSavedNip();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _savedNip = nip;
      });
    }
  }

  Future<void> _loginWithBiometric() async {
    if (_savedNip == null) return;
    setState(() {
      _biometricLoading = true;
      _error = null;
    });
    try {
      final authenticated = await BiometricService.authenticate(
        reason: 'Gunakan Face ID atau sidik jari untuk masuk ke SIPANTAW',
      );
      if (!authenticated) {
        setState(() => _error = 'Autentikasi biometrik gagal. Coba lagi.');
        return;
      }
      // Restore session dari biometric token — langsung ke dashboard tanpa OTP
      final success = await AuthService.loginWithBiometric();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _error = 'Sesi tidak ditemukan. Silakan login dengan NIP.');
      }
    } catch (e) {
      setState(() => _error = 'Gagal autentikasi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  @override
  void dispose() {
    _nipController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _checkNip() async {
    if (_nipController.text.trim().isEmpty) {
      setState(() => _error = 'NIP wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AuthService.checkNip(_nipController.text.trim());
      _tempKey = res['temp_key'];

      if (res['status'] == 'has_phone') {
        setState(() {
          _maskedPhone = res['masked_phone'];
          _showOtp = true;
          _showPhone = false;
        });
      } else {
        setState(() {
          _showPhone = true;
          _showOtp = false;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Nomor WhatsApp wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AuthService.sendOtp(
          _tempKey!, _phoneController.text.trim());
      setState(() {
        _maskedPhone = res['masked_phone'];
        _showOtp = true;
        _showPhone = false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _error = 'Masukkan 6 digit OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.verifyOtp(
        _tempKey!,
        otp,
        nip: _nipController.text.trim(), // Simpan NIP untuk biometric
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _step => _showOtp ? 2 : (_showPhone ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Ambient pastel orbs
            Positioned(
              top: -140,
              right: -100,
              child: _Orb(
                size: 320,
                color: AppColors.neonCyan.withOpacity(0.45),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -90,
              child: _Orb(
                size: 300,
                color: AppColors.softLime.withOpacity(0.45),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (ctx, cons) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: cons.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          _buildTopBar(),
                          const SizedBox(height: 36),
                          _buildHeader().animate().fadeIn(duration: 550.ms).moveY(
                              begin: 16, end: 0, duration: 550.ms,
                              curve: Curves.easeOutCubic),
                          const SizedBox(height: 28),
                          _buildCard()
                              .animate(delay: 180.ms)
                              .fadeIn(duration: 550.ms)
                              .moveY(
                                  begin: 18,
                                  end: 0,
                                  duration: 550.ms,
                                  curve: Curves.easeOutCubic),
                          const SizedBox(height: 28),
                          _buildFooter().animate(delay: 380.ms).fadeIn(
                              duration: 500.ms),
                          const SizedBox(height: 24),
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

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // SIPANTAW wordmark
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.circle, color: AppColors.softLime, size: 7),
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
        // Step indicator
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Row(
            key: ValueKey(_step),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Step ${_step + 1}/3',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(3, (i) {
                final active = i <= _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.only(left: 4),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.black : AppColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final title = _showOtp
        ? 'Masukkan\nKode OTP.'
        : _showPhone
            ? 'Daftar Nomor\nWhatsApp.'
            : 'Selamat Datang\ndi SIPANTAW.';
    final subtitle = _showOtp
        ? 'Kode 6 digit telah kami kirim ke ${_maskedPhone ?? "nomor Anda"}.'
        : _showPhone
            ? 'Nomor aktif untuk menerima kode OTP verifikasi.'
            : 'Masuk aman menggunakan NIP pegawai Anda.';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(_step),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.4,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      radius: 32,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.06, 0), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(_step),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                _buildErrorBox(_error!),
                const SizedBox(height: 18),
              ],
              if (!_showOtp && !_showPhone) ...[
                PremiumInput(
                  controller: _nipController,
                  label: 'NIP Pegawai',
                  hint: 'Contoh: 199101012015011001',
                  icon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  label: 'Lanjut Verifikasi',
                  loading: _loading,
                  onTap: _loading ? null : _checkNip,
                  trailingIcon: Icons.arrow_forward_rounded,
                ),
                // Face ID / Biometric button
                if (_biometricAvailable && _biometricEnabled && _savedNip != null) ...[
                  const SizedBox(height: 16),
                  _buildBiometricDivider(),
                  const SizedBox(height: 16),
                  _buildBiometricButton(),
                ],
              ],
              if (_showPhone) ...[
                PremiumInput(
                  controller: _phoneController,
                  label: 'Nomor WhatsApp',
                  hint: '08123456789',
                  icon: Icons.chat_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  label: 'Kirim Kode OTP',
                  loading: _loading,
                  onTap: _loading ? null : _sendOtp,
                  trailingIcon: Icons.send_rounded,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showPhone = false;
                      _showOtp = false;
                      _error = null;
                    }),
                    child: const Text('Kembali'),
                  ),
                ),
              ],
              if (_showOtp) ...[
                const Text(
                  'Kode OTP',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 14),
                _buildOtpRow(),
                const SizedBox(height: 22),
                PremiumButton(
                  label: 'Verifikasi & Masuk',
                  loading: _loading,
                  onTap: _loading ? null : _verifyOtp,
                  trailingIcon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _showOtp = false;
                      _showPhone = false;
                      _error = null;
                      for (final c in _otpControllers) {
                        c.clear();
                      }
                    }),
                    child: const Text('Kembali'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).shake(
        hz: 4, offset: const Offset(3, 0), duration: 260.ms);
  }

  Widget _buildOtpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return _OtpBox(
          controller: _otpControllers[i],
          focusNode: _otpFocus[i],
          onChanged: (val) {
            if (val.isNotEmpty && i < 5) {
              _otpFocus[i + 1].requestFocus();
            } else if (val.isEmpty && i > 0) {
              _otpFocus[i - 1].requestFocus();
            }
          },
        );
      }),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 12, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'Secured by SIPANTAW · v1.0.0',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau masuk dengan',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return PressableScale(
      onTap: _biometricLoading ? () {} : _loginWithBiometric,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: _biometricLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.black,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BiometricIcon(),
                  const SizedBox(width: 10),
                  const Text(
                    'Masuk dengan Face ID',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Single OTP box with focus glow ───────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;
  bool get _filled => widget.controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: _filled
            ? AppColors.black
            : (_focused ? AppColors.white : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: _focused && !_filled
            ? Border.all(color: AppColors.black, width: 1.6)
            : null,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _filled ? AppColors.white : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          decoration: const InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

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

/// Animated biometric icon — Face ID style
class _BiometricIcon extends StatefulWidget {
  const _BiometricIcon();

  @override
  State<_BiometricIcon> createState() => _BiometricIconState();
}

class _BiometricIconState extends State<_BiometricIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.face_rounded,
          color: AppColors.softLime,
          size: 20,
        ),
      ),
    );
  }
}
