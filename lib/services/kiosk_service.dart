import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class KioskService {
  static Future<void> startKioskMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    } catch (e) {
      debugPrint('Immersive mode error: $e');
    }
  }

  static Future<void> stopKioskMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    } catch (e) {
      debugPrint('Immersive stop error: $e');
    }
  }
}
