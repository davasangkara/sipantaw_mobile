import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show WriteBuffer;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// Hasil verifikasi wajah + deteksi mood otomatis
class FaceVerificationResult {
  final bool success;
  final String? fotoBase64;
  final String? errorMessage;
  final DetectedMood? mood;

  const FaceVerificationResult({
    required this.success,
    this.fotoBase64,
    this.errorMessage,
    this.mood,
  });
}

/// Mood hasil deteksi otomatis — tidak dipilih user
class DetectedMood {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final double smileScore; // 0.0 - 1.0

  const DetectedMood({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.smileScore,
  });

  static DetectedMood fromSmileProbability(double smile) {
    if (smile >= 0.75) {
      return DetectedMood(
        emoji: '😄',
        label: 'Sangat Senang',
        value: 'very_happy',
        color: const Color(0xFF34C759),
        bg: const Color(0xFFE8F8EE),
        smileScore: smile,
      );
    } else if (smile >= 0.4) {
      return DetectedMood(
        emoji: '🙂',
        label: 'Baik',
        value: 'good',
        color: const Color(0xFF007AFF),
        bg: const Color(0xFFE5F1FF),
        smileScore: smile,
      );
    } else if (smile >= 0.15) {
      return DetectedMood(
        emoji: '😐',
        label: 'Biasa',
        value: 'neutral',
        color: const Color(0xFFFF9500),
        bg: const Color(0xFFFFF3E0),
        smileScore: smile,
      );
    } else {
      return DetectedMood(
        emoji: '😔',
        label: 'Tidak Happy',
        value: 'unhappy',
        color: const Color(0xFFFF3B30),
        bg: const Color(0xFFFFECEB),
        smileScore: smile,
      );
    }
  }
}

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
  _FaceStatus _faceStatus = _FaceStatus.noFace;

  // Animasi
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;

  // Countdown
  int _countdown = 0;
  bool _countdownRunning = false;

  // Frame skip counter — proses tiap 3 frame saja
  int _frameCounter = 0;

  // Smile probability running average
  final List<double> _smileSamples = [];
  double _avgSmile = 0.0;

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
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // medium cukup untuk face detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // perlu untuk smile probability
          enableLandmarks: false,
          enableContours: false,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

      if (mounted) {
        setState(() => _isInitializing = false);
        _startFaceDetection();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _faceStatus = _FaceStatus.error;
        });
      }
    }
  }

  void _startFaceDetection() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCapturing || !mounted) return;

      // Throttle — proses tiap 3 frame
      _frameCounter++;
      if (_frameCounter % 3 != 0) return;

      _isProcessing = true;

      try {
        final faces = await _detectFaces(image);
        if (!mounted) {
          _isProcessing = false;
          return;
        }

        _FaceStatus newStatus;

        if (faces.isEmpty) {
          newStatus = _FaceStatus.noFace;
          _resetSmileSamples();
        } else if (faces.length > 1) {
          newStatus = _FaceStatus.multipleFaces;
          _resetSmileSamples();
        } else {
          final face = faces.first;
          final eyesOpen = (face.leftEyeOpenProbability ?? 1.0) > 0.5 &&
              (face.rightEyeOpenProbability ?? 1.0) > 0.5;

          if (!eyesOpen) {
            newStatus = _FaceStatus.eyesClosed;
            _resetSmileSamples();
          } else {
            newStatus = _FaceStatus.detected;
            // Kumpulkan sampel smile probability
            final smile = face.smilingProbability ?? 0.0;
            _smileSamples.add(smile);
            if (_smileSamples.length > 10) _smileSamples.removeAt(0);
            _avgSmile = _smileSamples.isEmpty
                ? 0.0
                : _smileSamples.reduce((a, b) => a + b) / _smileSamples.length;
          }
        }

        // HANYA setState saat status berubah — ini kunci fix flicker
        if (_faceStatus != newStatus) {
          if (mounted) {
            setState(() => _faceStatus = newStatus);
          }

          // Mulai countdown jika baru terdeteksi
          if (newStatus == _FaceStatus.detected && !_countdownRunning) {
            _startCountdown();
          }
        }
      } catch (_) {}

      _isProcessing = false;
    });
  }

  void _resetSmileSamples() {
    _smileSamples.clear();
    _avgSmile = 0.0;
    _countdownRunning = false;
    if (_countdown > 0 && mounted) {
      setState(() => _countdown = 0);
    }
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
    _countdownRunning = true;
    for (int i = 3; i >= 1; i--) {
      if (!mounted || _faceStatus != _FaceStatus.detected) {
        _countdownRunning = false;
        if (mounted && _countdown != 0) {
          setState(() => _countdown = 0);
        }
        return;
      }
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    _countdownRunning = false;
    if (mounted && _faceStatus == _FaceStatus.detected) {
      _capturePhoto();
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _cameraController == null) return;
    setState(() {
      _isCapturing = true;
      _faceStatus = _FaceStatus.capturing;
      _countdown = 0;
    });

    try {
      await _cameraController!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));

      final xFile = await _cameraController!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Deteksi mood dari average smile probability
      final mood = DetectedMood.fromSmileProbability(_avgSmile);

      await _successCtrl.forward();
      if (mounted) {
        setState(() => _faceStatus = _FaceStatus.success);
      }

      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        Navigator.pop(
          context,
          FaceVerificationResult(
            success: true,
            fotoBase64: base64Str,
            mood: mood,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _faceStatus = _FaceStatus.error;
        });
      }
      _startFaceDetection();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Color get _ringColor {
    return switch (_faceStatus) {
      _FaceStatus.detected ||
      _FaceStatus.capturing ||
      _FaceStatus.success =>
        AppColors.softLime,
      _FaceStatus.multipleFaces || _FaceStatus.eyesClosed => AppColors.blush,
      _FaceStatus.error => AppColors.danger,
      _ => Colors.white.withValues(alpha: 0.4),
    };
  }

  String get _statusMessage {
    if (_isInitializing) return 'Menginisialisasi kamera...';
    return switch (_faceStatus) {
      _FaceStatus.noFace => widget.subtitle,
      _FaceStatus.detected => _countdown > 0
          ? 'Tahan posisi...'
          : 'Wajah terdeteksi!',
      _FaceStatus.multipleFaces => 'Hanya 1 wajah yang diperbolehkan',
      _FaceStatus.eyesClosed => 'Buka mata Anda',
      _FaceStatus.capturing => 'Mengambil foto...',
      _FaceStatus.success => 'Verifikasi berhasil!',
      _FaceStatus.error => 'Gagal membuka kamera. Periksa izin kamera.',
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
          // Kamera preview
          if (!_isInitializing && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

          // Overlay oval
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

          // Pulse ring saat terdeteksi
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

          // Countdown
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
              )
                  .animate(key: ValueKey(_countdown))
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 200.ms),
            ),

          // Success checkmark
          if (_faceStatus == _FaceStatus.success)
            Center(
              child: AnimatedBuilder(
                animation: _successAnim,
                builder: (_, __) => Transform.scale(
                  scale: _successAnim.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
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

          // Header
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
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status bar bawah — pakai AnimatedSwitcher untuk smooth transition
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
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _StatusIcon(status: _faceStatus),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _statusMessage,
                              key: ValueKey(_statusMessage),
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
                    if (!_isInitializing &&
                        _faceStatus != _FaceStatus.success) ...[
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TipItem(
                              icon: Icons.light_mode_rounded,
                              label: 'Cahaya cukup'),
                          _TipItem(
                              icon: Icons.face_rounded, label: '1 wajah saja'),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDetected ? 3.5 : 2.0;
    canvas.drawOval(ovalRect, ringPaint);

    final accentPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const arcLen = 0.35;
    final positions = [0.0, 1.57, 3.14, 4.71];
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
