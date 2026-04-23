import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class NoiseDetectionService {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _subscription;
  bool _isRunning = false;

  // Callback when suspicious noise detected
  Function()? onNoiseDetected;

  // Noise threshold in decibels — normal speech is ~60dB
  static const double noiseThreshold = 60.0;

  // Cooldown so it doesn't fire repeatedly
  bool _canDetect = true;
  static const int cooldownSeconds = 8;

  Future<void> start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone permission denied');
      return;
    }
    try {
      _noiseMeter = NoiseMeter();
      _isRunning = true;
      _subscription = _noiseMeter!.noise.listen(
        _onNoise,
        onError: (e) => debugPrint('Noise error: $e'),
      );
    } catch (e) {
      debugPrint('Noise detection start error: $e');
    }
  }

  void _onNoise(NoiseReading reading) {
    if (!_isRunning || !_canDetect) return;
    final db = reading.meanDecibel;
    debugPrint('🎙 Noise: ${db.toStringAsFixed(1)} dB');
    if (db >= noiseThreshold) {
      _canDetect = false;
      onNoiseDetected?.call();
      Future.delayed(Duration(seconds: cooldownSeconds), () {
        _canDetect = true;
      });
    }
  }

  void stop() {
    _isRunning = false;
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() => stop();
}
