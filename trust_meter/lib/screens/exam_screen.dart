import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/score_service.dart';
import '../services/face_detection_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

class ExamScreen extends StatefulWidget {
  final String studentId;
  const ExamScreen({super.key, required this.studentId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  CameraDescription? _frontCamera; // store to access sensorOrientation
  final FaceDetectionService _faceService = FaceDetectionService();
  Timer? _examTimer;
  Timer? _warningTimer;

  int  _remainingSeconds = 60 * 60;
  bool _cameraReady      = false;
  bool _faceDetected     = false;
  int  _faceCount        = 1;

  String _activeWarning      = '';
  Color  _activeWarningColor = AppColors.red;

  bool _canDeductLookAway  = true;
  bool _canDeductHeadMove  = true;
  bool _canDeductLeftFrame = true;
  bool _canDeductMultiFace = true;

  static const int cooldownMs = 2000;

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceService.initialize();
    _setupFaceCallbacks();
    _initCamera();
    _startExamTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _examTimer?.cancel();
    _warningTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  void _showWarning(String message, Color color) {
    _warningTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _activeWarning      = message;
      _activeWarningColor = color;
    });
    _warningTimer = Timer(const Duration(seconds: 3),
        () { if (mounted) setState(() => _activeWarning = ''); });
  }

  // ── Camera init ───────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Pick front camera
      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      debugPrint('📷 Front camera sensor orientation: '
          '${_frontCamera!.sensorOrientation}°');

      _cameraController = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);

      _cameraController!.startImageStream((img) {
        _faceService.processFrame(
          img,
          _frontCamera!.sensorOrientation,
          true, // isFrontCamera = true
        );
      });
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  // ── Callbacks ─────────────────────────────────────────────
  void _setupFaceCallbacks() {

    _faceService.onFaceCountChanged = (count) {
      if (!mounted) return;
      setState(() {
        _faceCount    = count;
        _faceDetected = count > 0;
      });

      final svc = context.read<ScoreService>();

      if (count == 0) {
        if (!_canDeductLeftFrame) return;
        _canDeductLeftFrame = false;
        svc.onLeftFrame();
        _showWarning('⚠ CANDIDATE LEFT FRAME  -20', AppColors.red);
        Future.delayed(Duration(milliseconds: cooldownMs),
            () { if (mounted) _canDeductLeftFrame = true; });

      } else if (count > 1) {
        if (!_canDeductMultiFace) return;
        _canDeductMultiFace = false;
        svc.onMultipleFacesDetected();
        _showWarning('⚠ MULTIPLE FACES DETECTED  -30', AppColors.red);
        Future.delayed(Duration(milliseconds: cooldownMs),
            () { if (mounted) _canDeductMultiFace = true; });
      }
    };

    _faceService.onGazeUpdate = (isLookingAway) {
      if (!mounted || !isLookingAway || !_canDeductLookAway) return;
      _canDeductLookAway = false;
      context.read<ScoreService>().onLookingAway();
      _showWarning('👁 GAZE DIVERTED  -10', AppColors.yellow);
      Future.delayed(Duration(milliseconds: cooldownMs),
          () { if (mounted) _canDeductLookAway = true; });
    };

    _faceService.onHeadMovement = (yaw, pitch) {
      if (!mounted || !_canDeductHeadMove) return;
      _canDeductHeadMove = false;
      context.read<ScoreService>().onExcessiveHeadMovement();
      _showWarning('⚠ EXCESSIVE HEAD MOVEMENT  -10', AppColors.yellow);
      Future.delayed(Duration(milliseconds: cooldownMs),
          () { if (mounted) _canDeductHeadMove = true; });
    };
  }

  // ── Timer ─────────────────────────────────────────────────
  void _startExamTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
        else _submitExam();
      });
      context.read<ScoreService>().tickTimer();
    });
  }

  String get _timerDisplay {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _submitExam() {
    _examTimer?.cancel();
    context.read<ScoreService>().endExam();
    Navigator.pushReplacement(context,
        MaterialPageRoute(
            builder: (_) => ResultScreen(studentId: widget.studentId)));
  }

  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ScoreService>(
          builder: (_, svc, __) => Column(
            children: [
              _buildHeader(),
              _buildCameraFrame(),
              const SizedBox(height: 10),
              _buildScoreRow(svc),
              const SizedBox(height: 8),
              _buildEventLog(svc),
              const Spacer(),
              _buildSubmitButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('EXAM MONITOR',
            style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: 1,
            )),
        LiveBadge(color: AppColors.red, label: 'RECORDING'),
      ],
    ),
  );

  Widget _buildCameraFrame() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        // Camera preview
        Container(
          height: 260, width: double.infinity,
          color: AppColors.surface,
          child: _cameraReady && _cameraController != null
              ? CameraPreview(_cameraController!)
              : const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: AppColors.cyan, strokeWidth: 2),
                    SizedBox(height: 10),
                    Text('Initializing camera...',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ])),
        ),

        // Border flash
        if (_activeWarning.isNotEmpty)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _activeWarningColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

        const _ScanLine(),
        const Positioned.fill(child: CameraCorners()),

        // Warning banner
        if (_activeWarning.isNotEmpty)
          Positioned(
            bottom: 36, left: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _activeWarningColor.withOpacity(0.88),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_activeWarning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 0.8,
                  )),
            ),
          ),

        Positioned(top: 8, right: 10, child: _faceBadge()),

        const Positioned(
          bottom: 8, left: 10,
          child: Text('FRONT CAM · AI MONITORING',
              style: TextStyle(
                  fontSize: 9, color: AppColors.cyan, letterSpacing: 1)),
        ),

        const Positioned(
          top: 8, left: 10,
          child: LiveBadge(color: AppColors.red, label: 'LIVE'),
        ),
      ]),
    ),
  );

  Widget _faceBadge() {
    final Color color;
    final String text;
    if (!_faceDetected) {
      color = AppColors.red; text = 'NO FACE';
    } else if (_faceCount > 1) {
      color = AppColors.red; text = 'MULTIPLE FACES';
    } else {
      color = AppColors.green; text = 'FACE DETECTED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildScoreRow(ScoreService svc) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(children: [
      Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INTEGRITY SCORE',
                  style: TextStyle(fontSize: 9,
                      color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('${svc.score}',
                  style: TextStyle(
                    fontFamily: 'Rajdhani', fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: ScoringRules.scoreColor(svc.score), height: 1,
                  )),
              const SizedBox(height: 6),
              ScoreBar(score: svc.score),
            ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.card(),
          child: Column(children: [
            const Text('TIME LEFT',
                style: TextStyle(fontSize: 9,
                    color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(_timerDisplay,
                style: const TextStyle(
                  fontFamily: 'Rajdhani', fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB0C4DE), letterSpacing: 1,
                )),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildEventLog(ScoreService svc) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FLAGGED EVENTS',
              style: TextStyle(fontSize: 9,
                  color: AppColors.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          if (svc.events.isEmpty)
            const Text('No suspicious activity detected',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted))
          else
            ...svc.events.reversed.take(4).map((e) => EventRow(
                label: e.label,
                deduction: e.deduction,
                scoreAfter: e.scoreAfter)),
        ]),
    ),
  );

  Widget _buildSubmitButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Submit Exam?',
                style: TextStyle(fontFamily: 'Rajdhani',
                    fontSize: 20, color: AppColors.textPrimary)),
            content: const Text('Are you sure? This cannot be undone.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); _submitExam(); },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red),
                child: const Text('Submit',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('SUBMIT EXAM',
            style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 15,
              fontWeight: FontWeight.w700, letterSpacing: 1.5,
            )),
      ),
    ),
  );
}

// ── Scan line ──────────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pos;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pos = Tween(begin: 0.15, end: 0.85).animate(_ctrl);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pos,
    builder: (_, __) => Positioned(
      top: 260 * _pos.value, left: 0, right: 0,
      child: Container(height: 1.5,
          color: AppColors.cyan.withOpacity(0.4)),
    ),
  );
}
