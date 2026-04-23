import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  late FaceDetector _faceDetector;
  bool _isProcessing = false;

  // ── Frame skip: only process every Nth frame ───────────────
  int _frameCount = 0;
  static const int frameSkip = 5; // process 1 out of every 5 frames

  // ── Callbacks ──────────────────────────────────────────────
  Function(int faceCount)? onFaceCountChanged;
  Function(double headYaw, double headPitch)? onHeadMovement;
  Function(bool isLookingAway)? onGazeUpdate;

  // ── Thresholds ─────────────────────────────────────────────
  static const double eyeOpenThreshold   = 0.6;
  static const double gazeYawThreshold   = 15.0;
  static const double headYawThreshold   = 22.0;
  static const double headPitchThreshold = 22.0;

  int _gazeAwayFrameCount = 0;
  static const int gazeAwayFrameLimit = 4;

  int _noFaceFrameCount = 0;
  static const int noFaceFrameLimit = 10;

  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: false,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> processFrame(
      CameraImage image, InputImageRotation rotation) async {
    // ── Skip frames to reduce CPU load ────────────────────────
    _frameCount++;
    if (_frameCount % frameSkip != 0) return;

    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, rotation);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _noFaceFrameCount++;
        _gazeAwayFrameCount = 0;
        if (_noFaceFrameCount >= noFaceFrameLimit) {
          onFaceCountChanged?.call(0);
          _noFaceFrameCount = 0;
        }
        return;
      }

      _noFaceFrameCount = 0;
      onFaceCountChanged?.call(faces.length);

      final face = faces.first;
      final yaw   = face.headEulerAngleY ?? 0.0;
      final pitch = face.headEulerAngleX ?? 0.0;
      onHeadMovement?.call(yaw, pitch);

      final leftEye  = face.leftEyeOpenProbability  ?? 1.0;
      final rightEye = face.rightEyeOpenProbability ?? 1.0;

      final eyesLookingAway   = leftEye  < eyeOpenThreshold ||
                                rightEye < eyeOpenThreshold;
      final headTurnedForGaze = yaw.abs() > gazeYawThreshold;
      final lookingAway       = eyesLookingAway || headTurnedForGaze;

      if (lookingAway) {
        _gazeAwayFrameCount++;
        if (_gazeAwayFrameCount >= gazeAwayFrameLimit) {
          onGazeUpdate?.call(true);
          _gazeAwayFrameCount = 0;
        }
      } else {
        _gazeAwayFrameCount = 0;
        onGazeUpdate?.call(false);
      }

    } catch (e) {
      debugPrint('FaceDetection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  bool isExcessiveHeadMovement(double yaw, double pitch) {
    return yaw.abs()   > headYawThreshold ||
           pitch.abs() > headPitchThreshold;
  }

  InputImage? _buildInputImage(
      CameraImage image, InputImageRotation rotation) {
    try {
      final allBytes = <int>[];
      for (final plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      return InputImage.fromBytes(
        bytes: Uint8List.fromList(allBytes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('InputImage build error: $e');
      return null;
    }
  }

  void dispose() => _faceDetector.close();
}
