import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/score_service.dart';
import '../services/face_detection_service.dart';
import '../services/noise_detection_service.dart';
import '../services/screenshot_detection_service.dart';
import '../models/questions.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

class ExamScreen extends StatefulWidget {
  final String studentId;
  const ExamScreen({super.key, required this.studentId});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  final FaceDetectionService       _faceService       = FaceDetectionService();
  final NoiseDetectionService      _noiseService      = NoiseDetectionService();
  final ScreenshotDetectionService _screenshotService = ScreenshotDetectionService();

  Timer? _examTimer;
  Timer? _warningTimer;

  // Shake animation for score
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  int _lastScore = 100;

  int  _remainingSeconds = 60 * 60;
  bool _cameraReady      = false;
  bool _faceDetected     = false;
  int  _faceCount        = 1;

  String _activeWarning      = '';
  Color  _activeWarningColor = AppColors.red;

  bool _canDeductLookAway   = true;
  bool _canDeductHeadMove   = true;
  bool _canDeductLeftFrame  = true;
  bool _canDeductMultiFace  = true;
  bool _canDeductAppSwitch  = true;
  bool _canDeductNoise      = true;
  bool _canDeductScreenshot = true;

  int _currentQuestion = 0;
  final Map<int, int> _answers = {};
  bool _showQuestions = true;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    WidgetsBinding.instance.addObserver(this);
    _faceService.initialize();
    _setupFaceCallbacks();
    _setupNoiseDetection();
    _setupScreenshotDetection();
    _initCamera();
    _startExamTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _examTimer?.cancel();
    _warningTimer?.cancel();
    _shakeCtrl.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceService.dispose();
    _noiseService.dispose();
    _screenshotService.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!mounted || !_canDeductAppSwitch) return;
      _canDeductAppSwitch = false;
      context.read<ScoreService>().deductScore('App switched during exam', 20);
      _showWarning('APP SWITCHED DETECTED', AppColors.red);
      Future.delayed(const Duration(seconds: 5), () { if (mounted) _canDeductAppSwitch = true; });
    }
  }

  void _setupNoiseDetection() {
    _noiseService.onNoiseDetected = () {
      if (!mounted || !_canDeductNoise) return;
      _canDeductNoise = false;
      context.read<ScoreService>().deductScore('Suspicious noise detected', 10);
      _showWarning('SUSPICIOUS NOISE DETECTED', AppColors.yellow);
      Future.delayed(const Duration(seconds: 8), () { if (mounted) _canDeductNoise = true; });
    };
    _noiseService.start();
  }

  void _setupScreenshotDetection() {
    _screenshotService.onScreenshotDetected = () {
      if (!mounted || !_canDeductScreenshot) return;
      _canDeductScreenshot = false;
      context.read<ScoreService>().deductScore('Screenshot taken during exam', 30);
      _showWarning('SCREENSHOT DETECTED! -30', AppColors.red);
      Future.delayed(const Duration(seconds: 10), () { if (mounted) _canDeductScreenshot = true; });
    };
    _screenshotService.start();
  }

  void _showWarning(String message, Color color) {
    _warningTimer?.cancel();
    if (!mounted) return;
    setState(() { _activeWarning = message; _activeWarningColor = color; });
    _warningTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _activeWarning = '');
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(frontCam, ResolutionPreset.medium,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
      final rotation = _getRotation(frontCam.sensorOrientation);
      _cameraController!.startImageStream((image) => _faceService.processFrame(image, rotation));
    } catch (e) { debugPrint('Camera init error: $e'); }
  }

  InputImageRotation _getRotation(int s) {
    switch (s) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  void _setupFaceCallbacks() {
    _faceService.onFaceCountChanged = (count) {
      if (!mounted) return;
      setState(() { _faceCount = count; _faceDetected = count > 0; });
      final svc = context.read<ScoreService>();
      if (count == 0) {
        _showWarning('CANDIDATE LEFT FRAME', AppColors.red);
        if (!_canDeductLeftFrame) return;
        svc.onLeftFrame(); _canDeductLeftFrame = false;
        Future.delayed(const Duration(seconds: 8), () { if (mounted) _canDeductLeftFrame = true; });
      } else if (count > 1) {
        _showWarning('MULTIPLE FACES DETECTED', AppColors.red);
        if (!_canDeductMultiFace) return;
        svc.onMultipleFacesDetected(); _canDeductMultiFace = false;
        Future.delayed(const Duration(seconds: 10), () { if (mounted) _canDeductMultiFace = true; });
      }
    };
    _faceService.onGazeUpdate = (isLookingAway) {
      if (!mounted) return;
      if (isLookingAway) {
        _showWarning('GAZE DIVERTED', AppColors.yellow);
        if (!_canDeductLookAway) return;
        context.read<ScoreService>().onLookingAway(); _canDeductLookAway = false;
        Future.delayed(const Duration(seconds: 6), () { if (mounted) _canDeductLookAway = true; });
      }
    };
    _faceService.onHeadMovement = (yaw, pitch) {
      if (!mounted) return;
      if (_faceService.isExcessiveHeadMovement(yaw, pitch)) {
        _showWarning('EXCESSIVE HEAD MOVEMENT', AppColors.yellow);
        if (!_canDeductHeadMove) return;
        context.read<ScoreService>().onExcessiveHeadMovement(); _canDeductHeadMove = false;
        Future.delayed(const Duration(seconds: 8), () { if (mounted) _canDeductHeadMove = true; });
      }
    };
  }

  void _startExamTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { if (_remainingSeconds > 0) { _remainingSeconds--; } else { _submitExam(); } });
      context.read<ScoreService>().tickTimer();
    });
  }

  String get _timerDisplay {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 600) return AppColors.red;
    if (_remainingSeconds <= 1800) return AppColors.yellow;
    return const Color(0xFFB0C4DE);
  }

  void _submitExam() async {
    _examTimer?.cancel();
    _noiseService.stop();
    _screenshotService.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await context.read<ScoreService>().endExam();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ResultScreen(studentId: widget.studentId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ScoreService>(
          builder: (_, svc, __) => Column(
            children: [
              _buildHeader(),
              _buildCameraFrame(),
              const SizedBox(height: 8),
              _buildScoreRow(svc),
              const SizedBox(height: 8),
              _buildTabBar(),
              const SizedBox(height: 8),
              Expanded(child: _showQuestions ? _buildQuestionPanel() : _buildEventLog(svc)),
              _buildSubmitButton(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('EXAM MONITOR', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
          fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 1)),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: AppColors.yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.yellow.withOpacity(0.4))),
          child: Row(children: [
            const Icon(Icons.mic, color: AppColors.yellow, size: 10),
            const SizedBox(width: 3),
            const Text('LISTENING', style: TextStyle(color: AppColors.yellow,
                fontSize: 8, fontWeight: FontWeight.w600)),
          ]),
        ),
        const LiveBadge(color: AppColors.red, label: 'RECORDING'),
      ]),
    ]),
  );

  Widget _buildCameraFrame() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        Container(height: 190, width: double.infinity, color: AppColors.surface,
          child: _cameraReady && _cameraController != null
              ? CameraPreview(_cameraController!)
              : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
                    SizedBox(height: 10),
                    Text('Initializing camera...', style: TextStyle(fontSize: 11, color: AppColors.textMuted))]))),
        if (_activeWarning.isNotEmpty)
          Positioned.fill(child: Container(decoration: BoxDecoration(
              border: Border.all(color: _activeWarningColor, width: 3),
              borderRadius: BorderRadius.circular(16)))),
        const _ScanLine(),
        const Positioned.fill(child: CameraCorners()),
        if (_activeWarning.isNotEmpty)
          Positioned(bottom: 28, left: 10, right: 10,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _activeWarningColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_activeWarning, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)))),
        Positioned(top: 8, right: 10, child: _faceBadge()),
        const Positioned(bottom: 8, left: 10,
          child: Text('FRONT CAM · AI MONITORING',
              style: TextStyle(fontSize: 9, color: AppColors.cyan, letterSpacing: 1))),
        const Positioned(top: 8, left: 10, child: LiveBadge(color: AppColors.red, label: 'LIVE')),
        // Student ID watermark on camera
        Positioned(bottom: 8, right: 10,
          child: Text('ID: ${widget.studentId}',
              style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w600))),
      ]),
    ),
  );

  Widget _faceBadge() {
    Color color; String text;
    if (!_faceDetected) { color = AppColors.red; text = 'NO FACE'; }
    else if (_faceCount > 1) { color = AppColors.red; text = 'MULTIPLE FACES'; }
    else { color = AppColors.green; text = 'FACE DETECTED'; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500)));
  }

  Widget _buildScoreRow(ScoreService svc) {
    // Trigger shake when score drops
    if (svc.score < _lastScore) {
      _lastScore = svc.score;
      _shakeCtrl.forward(from: 0);
    }
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(children: [
      Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(12),
        decoration: AppDecorations.card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('INTEGRITY SCORE', style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(sin(_shakeAnim.value * pi * 6) * 6, 0),
              child: child,
            ),
            child: Text('${svc.score}', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 26,
                fontWeight: FontWeight.w700, color: ScoringRules.scoreColor(svc.score), height: 1)),
          ),
          const SizedBox(height: 4),
          ScoreBar(score: svc.score),
        ]))),
      const SizedBox(width: 8),
      Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: AppDecorations.card(),
        child: Column(children: [
          const Text('TIME LEFT', style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(_timerDisplay, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
              fontWeight: FontWeight.w600, color: _timerColor, letterSpacing: 1)),
          if (_remainingSeconds <= 600)
            const Text('TIME RUNNING OUT!', style: TextStyle(fontSize: 7, color: AppColors.red)),
        ]))),
      const SizedBox(width: 8),
      Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: AppDecorations.card(),
        child: Column(children: [
          const Text('PROGRESS', style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('${_answers.length}/${examQuestions.length}',
              style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
                  fontWeight: FontWeight.w600, color: AppColors.cyan)),
          const Text('answered', style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
        ]))),
    ]),
  );
  }

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(decoration: AppDecorations.card(),
      child: Row(children: [_tab('QUESTIONS', true), _tab('FLAGGED EVENTS', false)])),
  );

  Widget _tab(String label, bool isQ) {
    final active = _showQuestions == isQ;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _showQuestions = isQ),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: active ? AppColors.cyan.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active ? Border.all(color: AppColors.cyan.withOpacity(0.4)) : null),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10,
                color: active ? AppColors.cyan : AppColors.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                letterSpacing: 0.5))),
    ));
  }

  Widget _buildQuestionPanel() {
    final q = examQuestions[_currentQuestion];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(padding: const EdgeInsets.all(14), decoration: AppDecorations.card(),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Q${q.number} of ${examQuestions.length}',
                style: const TextStyle(fontSize: 10, color: AppColors.cyan, letterSpacing: 0.5)),
            Row(children: [
              if (_currentQuestion > 0) GestureDetector(
                onTap: () => setState(() => _currentQuestion--),
                child: const Icon(Icons.arrow_back_ios, color: AppColors.textMuted, size: 16)),
              const SizedBox(width: 12),
              if (_currentQuestion < examQuestions.length - 1) GestureDetector(
                onTap: () => setState(() => _currentQuestion++),
                child: const Icon(Icons.arrow_forward_ios, color: AppColors.cyan, size: 16)),
            ]),
          ]),

          // ── Progress dots ──────────────────────────────────
          const SizedBox(height: 10),
          SizedBox(
            height: 10,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: examQuestions.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _currentQuestion = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _currentQuestion ? 18 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: i == _currentQuestion
                        ? AppColors.cyan
                        : _answers.containsKey(i)
                            ? AppColors.green
                            : AppColors.border,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Anti-copy: use AbsorbPointer on long press
          GestureDetector(
            onLongPress: () {},  // absorb long press — prevents copy
            child: Text(q.question, style: const TextStyle(fontSize: 13,
                color: AppColors.textPrimary, fontWeight: FontWeight.w500, height: 1.4),
              // disable text selection
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(q.options.length, (i) {
            final selected = _answers[_currentQuestion] == i;
            return GestureDetector(
              onTap: () => setState(() => _answers[_currentQuestion] = i),
              child: Container(margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: selected ? AppColors.cyan.withOpacity(0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? AppColors.cyan : AppColors.border)),
                child: Row(children: [
                  Container(width: 20, height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: selected ? AppColors.cyan : Colors.transparent,
                        border: Border.all(color: selected ? AppColors.cyan : AppColors.textMuted)),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 12) : null),
                  const SizedBox(width: 10),
                  Expanded(child: Text(q.options[i],
                      style: TextStyle(fontSize: 12,
                          color: selected ? AppColors.cyan : AppColors.textSecondary))),
                ])),
            );
          }),
        ]))));
  }

  Widget _buildEventLog(ScoreService svc) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(padding: const EdgeInsets.all(14), decoration: AppDecorations.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FLAGGED EVENTS', style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        if (svc.events.isEmpty)
          const Text('No suspicious activity detected', style: TextStyle(fontSize: 11, color: AppColors.textMuted))
        else
          ...svc.events.reversed.take(6).map((e) => EventRow(label: e.label,
              deduction: e.deduction, scoreAfter: e.scoreAfter)),
      ])));

  Widget _buildSubmitButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: SizedBox(width: double.infinity, height: 44,
      child: ElevatedButton(
        onPressed: () => showDialog(context: context,
          builder: (_) => AlertDialog(backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Submit Exam?', style: TextStyle(fontFamily: 'Rajdhani',
                fontSize: 20, color: AppColors.textPrimary)),
            content: Text('Answered ${_answers.length}/${examQuestions.length} questions.\nThis cannot be undone.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); _submitExam(); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                child: const Text('Submit', style: TextStyle(color: Colors.white))),
            ])),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('SUBMIT EXAM', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14,
            fontWeight: FontWeight.w700, letterSpacing: 1.5)))));
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}
class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pos;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pos = Tween(begin: 0.15, end: 0.85).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _pos,
    builder: (_, __) => Positioned(top: 190 * _pos.value, left: 0, right: 0,
      child: Container(height: 1.5, color: AppColors.cyan.withOpacity(0.4))));
}
