import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  late FaceDetector _faceDetector;
  bool _isProcessing = false;

  // ── Callbacks ──────────────────────────────────────────────
  Function(int faceCount)? onFaceCountChanged;
  Function(double headYaw, double headPitch)? onHeadMovement;
  Function(bool isLookingAway)? onGazeUpdate;

  // ── Thresholds ─────────────────────────────────────────────
  static const double eyeOpenThreshold   = 0.6;
  static const double gazeYawThreshold   = 15.0;
  static const double headYawThreshold   = 30.0;
  static const double headPitchThreshold = 30.0;

  // ── Frame smoothing counters ───────────────────────────────
  int _gazeAwayFrameCount  = 0;
  int _noFaceFrameCount    = 0;
  int _multiFaceFrameCount = 0;
  int _headMoveFrameCount  = 0;

  static const int gazeAwayFrameLimit  = 8;
  static const int noFaceFrameLimit    = 25;
  static const int multiFaceFrameLimit = 15;
  static const int headMoveFrameLimit  = 12;

  int _lastFaceCount = -1;

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

  Future<void> processFrame(CameraImage image, int sensorOrientation,
      bool isFrontCamera) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage =
          _buildInputImage(image, sensorOrientation, isFrontCamera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      debugPrint('🔍 Faces found: ${faces.length} | sensor: $sensorOrientation');

      // ── No face ────────────────────────────────────────────
      if (faces.isEmpty) {
        _noFaceFrameCount++;
        _multiFaceFrameCount = 0;
        _gazeAwayFrameCount  = 0;
        _headMoveFrameCount  = 0;
        if (_noFaceFrameCount >= noFaceFrameLimit) {
          if (_lastFaceCount != 0) {
            _lastFaceCount = 0;
            onFaceCountChanged?.call(0);
          }
          _noFaceFrameCount = 0;
        }
        return;
      }

      // ── Face(s) found ──────────────────────────────────────
      _noFaceFrameCount = 0;
      final count = faces.length;

      if (count == 1) {
        _multiFaceFrameCount = 0;
        if (_lastFaceCount != 1) {
          _lastFaceCount = 1;
          onFaceCountChanged?.call(1);
        }
      } else {
        // Multiple faces — confirm after sustained frames
        _multiFaceFrameCount++;
        debugPrint('👥 Multi-face frames: $_multiFaceFrameCount/$multiFaceFrameLimit');
        if (_multiFaceFrameCount >= multiFaceFrameLimit) {
          if (_lastFaceCount != count) {
            _lastFaceCount = count;
            onFaceCountChanged?.call(count);
          }
          _multiFaceFrameCount = 0;
        }
      }

      final face = faces.first;
      final yaw   = face.headEulerAngleY ?? 0.0;
      final pitch = face.headEulerAngleX ?? 0.0;

      // ── Head movement ──────────────────────────────────────
      if (isExcessiveHeadMovement(yaw, pitch)) {
        _headMoveFrameCount++;
        if (_headMoveFrameCount >= headMoveFrameLimit) {
          onHeadMovement?.call(yaw, pitch);
          _headMoveFrameCount = 0;
        }
      } else {
        _headMoveFrameCount = 0;
      }

      // ── Gaze ───────────────────────────────────────────────
      final leftEye  = face.leftEyeOpenProbability  ?? 1.0;
      final rightEye = face.rightEyeOpenProbability ?? 1.0;
      final lookingAway = leftEye  < eyeOpenThreshold ||
                          rightEye < eyeOpenThreshold ||
                          yaw.abs() > gazeYawThreshold;

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

  bool isExcessiveHeadMovement(double yaw, double pitch) =>
      yaw.abs() > headYawThreshold || pitch.abs() > headPitchThreshold;

  // ── Correct rotation for Android front camera ──────────────
  InputImage? _buildInputImage(
      CameraImage image, int sensorOrientation, bool isFrontCamera) {
    try {
      // Concatenate all plane bytes
      final allBytes = <int>[];
      for (final plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }

      // Calculate correct rotation for ML Kit
      // Android front cameras are typically 270°
      final rotation = _getInputImageRotation(sensorOrientation, isFrontCamera);

      debugPrint('📷 Rotation used: $rotation | sensor: $sensorOrientation');

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

  InputImageRotation _getInputImageRotation(
      int sensorOrientation, bool isFrontCamera) {
    // On Android, front camera rotation needs to be compensated
    if (Platform.isAndroid) {
      // Front camera on Android is mirrored, rotation is different
      switch (sensorOrientation) {
        case 0:   return InputImageRotation.rotation0deg;
        case 90:  return isFrontCamera
            ? InputImageRotation.rotation270deg
            : InputImageRotation.rotation90deg;
        case 180: return InputImageRotation.rotation180deg;
        case 270: return isFrontCamera
            ? InputImageRotation.rotation90deg
            : InputImageRotation.rotation270deg;
        default:  return InputImageRotation.rotation270deg; // most Android front cams
      }
    }
    // iOS
    switch (sensorOrientation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  void dispose() => _faceDetector.close();
}
