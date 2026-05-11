import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';

/// Halaman onboarding permission — muncul sekali saat pertama install.
/// Meminta izin kamera, lokasi, dan notifikasi secara berurutan dengan UI iOS-style.
class PermissionPage extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionPage({super.key, required this.onDone});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _requesting = false;

  final _permissions = [
    _PermissionItem(
      icon: Icons.location_on_rounded,
      color: const Color(0xFF34C759), // iOS green
      title: 'Lokasi',
      subtitle: 'Untuk mengisi alamat WFA otomatis\ndan mencatat lokasi absensi',
      detail: 'Digunakan saat absen dan membuat laporan',
    ),
    _PermissionItem(
      icon: Icons.camera_alt_rounded,
      color: const Color(0xFF007AFF), // iOS blue
      title: 'Kamera',
      subtitle: 'Untuk foto absensi dan\nverifikasi wajah Face ID',
      detail: 'Digunakan saat absen WFA',
    ),
    _PermissionItem(
      icon: Icons.notifications_rounded,
      color: const Color(0xFFFF9500), // iOS orange
      title: 'Notifikasi',
      subtitle: 'Untuk pengingat absensi\ndan update status laporan',
      detail: 'Opsional — bisa diaktifkan nanti',
    ),
  ];

  Future<void> _requestCurrent() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    try {
      switch (_currentStep) {
        case 0: // Lokasi
          var locStatus = await Permission.location.status;
          if (locStatus.isDenied) {
            locStatus = await Permission.location.request();
          }
          if (locStatus.isGranted) {
            await Geolocator.requestPermission();
          }
          break;

        case 1: // Kamera
          var camStatus = await Permission.camera.status;
          if (camStatus.isDenied) {
            camStatus = await Permission.camera.request();
          }
          break;

        case 2: // Notifikasi
          var notifStatus = await Permission.notification.status;
          if (notifStatus.isDenied) {
            notifStatus = await Permission.notification.request();
          }
          break;
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (_currentStep < _permissions.length - 1) {
        setState(() {
          _currentStep++;
          _requesting = false;
        });
      } else {
        // Semua selesai
        setState(() => _requesting = false);
        await Future.delayed(const Duration(milliseconds: 400));
        widget.onDone();
      }
    } catch (_) {
      setState(() => _requesting = false);
      if (_currentStep < _permissions.length - 1) {
        setState(() => _currentStep++);
      } else {
        widget.onDone();
      }
    }
  }

  void _skipCurrent() {
    if (_currentStep < _permissions.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _permissions[_currentStep];
    final isLast = _currentStep == _permissions.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Progress dots
                Row(
                  children: List.generate(_permissions.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _currentStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentStep
                            ? AppColors.black
                            : i < _currentStep
                                ? AppColors.textMuted
                                : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const Spacer(flex: 2),

                // Icon besar
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Container(
                    key: ValueKey(_currentStep),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(item.icon, color: item.color, size: 52),
                  ),
                )
                    .animate(key: ValueKey('icon_$_currentStep'))
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 36),

                // Title
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    key: ValueKey('title_$_currentStep'),
                    'Izinkan\nAkses ${item.title}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                )
                    .animate(key: ValueKey('title_anim_$_currentStep'),
                        delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .moveY(begin: 12, end: 0, duration: 400.ms),

                const SizedBox(height: 16),

                // Subtitle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    key: ValueKey('sub_$_currentStep'),
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                    .animate(
                        key: ValueKey('sub_anim_$_currentStep'), delay: 180.ms)
                    .fadeIn(duration: 400.ms)
                    .moveY(begin: 10, end: 0, duration: 400.ms),

                const SizedBox(height: 20),

                // Detail chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: item.color.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: item.color),
                      const SizedBox(width: 8),
                      Text(
                        item.detail,
                        style: TextStyle(
                          fontSize: 12,
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(
                        key: ValueKey('detail_$_currentStep'), delay: 260.ms)
                    .fadeIn(duration: 400.ms),

                const Spacer(flex: 3),

                // Tombol izinkan
                PremiumButton(
                  label: _requesting
                      ? 'Meminta izin...'
                      : isLast
                          ? 'Izinkan & Mulai'
                          : 'Izinkan Akses ${item.title}',
                  loading: _requesting,
                  onTap: _requesting ? null : _requestCurrent,
                  trailingIcon: isLast ? Icons.arrow_forward_rounded : null,
                ),

                const SizedBox(height: 12),

                // Skip (hanya untuk notifikasi / opsional)
                if (_currentStep == 2)
                  Center(
                    child: TextButton(
                      onPressed: _skipCurrent,
                      child: const Text(
                        'Lewati untuk sekarang',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;

  const _PermissionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
  });
}
