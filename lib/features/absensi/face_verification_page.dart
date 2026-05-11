import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Hasil verifikasi wajah
class FaceVerificationResult {
  final bool success;
  final String? fotoBase64;
  final String? errorMessage;

  const FaceVerificationResult({
    required this.success,
    this.fotoBase64,
    this.errorMessage,
  });
}

/// Halaman verifikasi wajah real-time menggunakan kamera depan.
/// Mendeteksi wajah, memastikan hanya 1 wajah, lalu capture foto.
class FaceVerificationPage extends StatefulWidget {
  final String title;
  final String subtitle;

  const FaceVerificationPage({
    super.key,
    this.title = 'Verifikasi Wajah',
    this.subtitle = 'Posisikan wajah Anda di dalam lingkaran',
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _isCapturing = false;
  String _statusMessage = 'Menginisialisasi kamera...';
  _FaceStatus _faceStatus = _FaceStatus.noFace;

  // Animasi lingkaran
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;

  // Countdown sebelum capture
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeOutBack),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // Pilih kamera depan
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      // Inisialisasi face detector
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: false,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = widget.subtitle;
        });
        _startFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Gagal membuka kamera. Periksa izin kamera.';
          _faceStatus = _FaceStatus.error;
        });
      }
    }
  }

  void _startFaceDetection() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCapturing || !mounted) return;
      _isProcessing = true;

      try {
        final faces = await _detectFaces(image);
        if (!mounted) {
          _isProcessing = false;
          return;
        }

        if (faces.isEmpty) {
          setState(() {
            _faceStatus = _FaceStatus.noFace;
            _statusMessage = 'Tidak ada wajah terdeteksi';
            _countdown = 0;
          });
        } else if (faces.length > 1) {
          setState(() {
            _faceStatus = _FaceStatus.multipleFaces;
            _statusMessage = 'Hanya 1 wajah yang diperbolehkan';
            _countdown = 0;
          });
        } else {
          final face = faces.first;
          final eyesOpen = (face.leftEyeOpenProbability ?? 1.0) > 0.5 &&
              (face.rightEyeOpenProbability ?? 1.0) > 0.5;

          if (!eyesOpen) {
            setState(() {
              _faceStatus = _FaceStatus.eyesClosed;
              _statusMessage = 'Buka mata Anda';
              _countdown = 0;
            });
          } else {
            // Wajah valid — mulai countdown
            if (_faceStatus != _FaceStatus.detected) {
              setState(() {
                _faceStatus = _FaceStatus.detected;
                _statusMessage = 'Wajah terdeteksi! Tahan sebentar...';
                _countdown = 3;
              });
              _startCountdown();
            }
          }
        }
      } catch (_) {}

      _isProcessing = false;
    });
  }

  Future<List<Face>> _detectFaces(CameraImage image) async {
    if (_faceDetector == null) return [];

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    return _faceDetector!.processImage(inputImage);
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted || _faceStatus != _FaceStatus.detected) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted && _faceStatus == _FaceStatus.detected) {
      _capturePhoto();
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _cameraController == null) return;
    setState(() {
      _isCapturing = true;
      _faceStatus = _FaceStatus.capturing;
      _statusMessage = 'Mengambil foto...';
      _countdown = 0;
    });

    try {
      await _cameraController!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));

      final xFile = await _cameraController!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Animasi sukses
      await _successCtrl.forward();
      setState(() {
        _faceStatus = _FaceStatus.success;
        _statusMessage = 'Verifikasi berhasil!';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pop(
          context,
          FaceVerificationResult(success: true, fotoBase64: base64Str),
        );
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _faceStatus = _FaceStatus.error;
        _statusMessage = 'Gagal mengambil foto. Coba lagi.';
      });
      // Restart stream
      _startFaceDetection();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Color get _ringColor {
    return switch (_faceStatus) {
      _FaceStatus.detected || _FaceStatus.capturing => AppColors.softLime,
      _FaceStatus.success => AppColors.softLime,
      _FaceStatus.multipleFaces || _FaceStatus.eyesClosed => AppColors.blush,
      _FaceStatus.error => AppColors.danger,
      _ => Colors.white.withValues(alpha: 0.4),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ovalSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // ── Kamera preview ──────────────────────────────────
          if (!_isInitializing && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

          // ── Overlay gelap dengan lubang oval ───────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _OvalOverlayPainter(
                ovalSize: ovalSize,
                ringColor: _ringColor,
                isDetected: _faceStatus == _FaceStatus.detected ||
                    _faceStatus == _FaceStatus.capturing ||
                    _faceStatus == _FaceStatus.success,
              ),
            ),
          ),

          // ── Animasi pulse ring ──────────────────────────────
          if (_faceStatus == _FaceStatus.detected)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: ovalSize + 16,
                    height: ovalSize * 1.25 + 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ovalSize / 2),
                      border: Border.all(
                        color: AppColors.softLime.withValues(alpha: 0.35),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Countdown ──────────────────────────────────────
          if (_countdown > 0)
            Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: AppColors.softLime,
                  letterSpacing: -4,
                ),
              ).animate().scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),

          // ── Success checkmark ───────────────────────────────
          if (_faceStatus == _FaceStatus.success)
            Center(
              child: AnimatedBuilder(
                animation: _successAnim,
                builder: (_, __) => Transform.scale(
                  scale: _successAnim.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.softLime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.black,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),

          // ── Header ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(
                      context,
                      const FaceVerificationResult(success: false),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Status bar bawah ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status icon + text
                    Row(
                      children: [
                        _StatusIcon(status: _faceStatus),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              key: ValueKey(_statusMessage),
                              _statusMessage,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _faceStatus == _FaceStatus.detected ||
                                        _faceStatus == _FaceStatus.success
                                    ? AppColors.softLime
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isInitializing) ...[
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.white12,
                        color: AppColors.softLime,
                      ),
                    ],
                    // Tips
                    if (!_isInitializing &&
                        _faceStatus != _FaceStatus.success) ...[
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _TipItem(
                              icon: Icons.light_mode_rounded,
                              label: 'Cahaya cukup'),
                          _TipItem(
                              icon: Icons.face_rounded,
                              label: '1 wajah saja'),
                          _TipItem(
                              icon: Icons.remove_red_eye_rounded,
                              label: 'Mata terbuka'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status icon ───────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final _FaceStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      _FaceStatus.detected => (Icons.face_rounded, AppColors.softLime),
      _FaceStatus.success => (Icons.check_circle_rounded, AppColors.softLime),
      _FaceStatus.multipleFaces => (Icons.group_rounded, AppColors.blush),
      _FaceStatus.eyesClosed => (Icons.visibility_off_rounded, AppColors.blush),
      _FaceStatus.error => (Icons.error_rounded, AppColors.danger),
      _FaceStatus.capturing => (Icons.camera_rounded, AppColors.softLime),
      _ => (Icons.face_outlined, Colors.white54),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ── Tip item ──────────────────────────────────────────────────
class _TipItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TipItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Oval overlay painter ──────────────────────────────────────
class _OvalOverlayPainter extends CustomPainter {
  final double ovalSize;
  final Color ringColor;
  final bool isDetected;

  const _OvalOverlayPainter({
    required this.ovalSize,
    required this.ringColor,
    required this.isDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalSize,
      height: ovalSize * 1.25,
    );

    // Overlay gelap
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Ring oval
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDetected ? 3.5 : 2.0;
    canvas.drawOval(ovalRect, ringPaint);

    // Corner accents (4 sudut)
    final accentPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const arcLen = 0.35; // radian
    final positions = [0.0, 1.57, 3.14, 4.71]; // top, right, bottom, left
    for (final angle in positions) {
      canvas.drawArc(ovalRect, angle - arcLen / 2, arcLen, false, accentPaint);
    }
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter old) =>
      old.ringColor != ringColor || old.isDetected != isDetected;
}

// ── Face status enum ──────────────────────────────────────────
enum _FaceStatus {
  noFace,
  detected,
  multipleFaces,
  eyesClosed,
  capturing,
  success,
  error,
}
