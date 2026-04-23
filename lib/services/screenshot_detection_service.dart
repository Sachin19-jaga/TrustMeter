import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ScreenshotDetectionService {
  static const _channel = EventChannel('trust_meter/screenshot');
  StreamSubscription? _subscription;

  Function()? onScreenshotDetected;

  void start() {
    try {
      _subscription = _channel.receiveBroadcastStream().listen(
        (_) {
          debugPrint('📸 Screenshot detected!');
          onScreenshotDetected?.call();
        },
        onError: (e) => debugPrint('Screenshot detection error: $e'),
      );
    } catch (e) {
      debugPrint('Screenshot service start error: $e');
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() => stop();
}
