import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Premium monochrome splash — black typography, lime + cyan accents,
/// floating animated orbs, pill loader. Apple-level polish.
class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.canvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();

    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(widget.isLoggedIn ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Base canvas with very soft gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.gradientSplash,
            ),
          ),

          // Floating pastel orbs
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (context, _) {
              final t = _orbCtrl.value * 2 * math.pi;
              return Stack(
                children: [
                  Positioned(
                    top: -size.width * 0.32 + math.sin(t) * 22,
                    right: -size.width * 0.22 + math.cos(t) * 22,
                    child: _Orb(
                      size: size.width * 0.95,
                      color: AppColors.neonCyan.withOpacity(0.55),
                    ),
                  ),
                  Positioned(
                    bottom: -size.width * 0.42 + math.cos(t * 0.8) * 26,
                    left: -size.width * 0.28 + math.sin(t * 0.8) * 26,
                    child: _Orb(
                      size: size.width * 1.05,
                      color: AppColors.softLime.withOpacity(0.55),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.28,
                    left: size.width * 0.06,
                    child: _Orb(
                      size: 120,
                      color: AppColors.pastelBlue.withOpacity(0.45),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // Brand mark — black rounded square with lime dot
                  const _BrandMark()
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 40),

                  // Pill "tag"
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
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
                        ),
                        const SizedBox(width: 8),
                        const Text(
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
                  )
                      .animate(delay: 250.ms)
                      .fadeIn(duration: 500.ms)
                      .moveY(begin: 14, end: 0, duration: 500.ms),

                  const SizedBox(height: 22),

                  // Big editorial headline
                  Text(
                    'Kerja cerdas,\ndi mana pun.',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.6,
                          height: 1.05,
                        ),
                  )
                      .animate(delay: 420.ms)
                      .fadeIn(duration: 600.ms)
                      .moveY(begin: 18, end: 0, duration: 600.ms),

                  const SizedBox(height: 18),

                  Text(
                    'Sistem monitoring Work From Anywhere dengan pengalaman kelas dunia.',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                      .animate(delay: 560.ms)
                      .fadeIn(duration: 600.ms)
                      .moveY(begin: 14, end: 0, duration: 600.ms),

                  const Spacer(flex: 3),

                  // Loader pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _LoaderDots(),
                          SizedBox(width: 12),
                          Text(
                            'Memuat',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 750.ms)
                      .fadeIn(duration: 500.ms)
                      .moveY(begin: 12, end: 0, duration: 500.ms),

                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Brand mark ───────────────────────────────────────────────
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'S',
              style: TextStyle(
                color: AppColors.softLime,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
          ),
        ),
        // Floating lime accent dot
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.softLime,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.canvas, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.softLime.withOpacity(0.6),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
            )
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.1, 1.1),
              duration: 1400.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

// ─── Orb ──────────────────────────────────────────────────────
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
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─── Loader dots ──────────────────────────────────────────────
class _LoaderDots extends StatefulWidget {
  const _LoaderDots();

  @override
  State<_LoaderDots> createState() => _LoaderDotsState();
}

class _LoaderDotsState extends State<_LoaderDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 1100),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_c.value - delay) % 1.0 + 1.0) % 1.0;
            final scale = t < 0.5 ? 0.6 + t * 0.8 : 1.0 - (t - 0.5) * 0.8;
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Transform.scale(
                scale: scale.clamp(0.6, 1.2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == 1 ? AppColors.softLime : AppColors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
