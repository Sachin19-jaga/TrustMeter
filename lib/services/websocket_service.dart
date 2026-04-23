import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _connected = false;
  StreamSubscription? _subscription;

  static const String wsUrl = 'ws://your-backend-server:8000/ws/exam';

  bool get connected => _connected;

  Future<void> connect(String studentId) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/$studentId'));
      _connected = true;
      notifyListeners();
      _subscription = _channel!.stream.listen(
        (data) => debugPrint('WS: $data'),
        onError: (_) => _onDisconnect(),
        onDone: () => _onDisconnect(),
      );
    } catch (e) {
      debugPrint('WebSocket failed: $e');
      _connected = false;
      notifyListeners();
    }
  }

  void sendScoreUpdate({required String studentId, required int score,
      required String? lastEvent, required int deduction}) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'score_update',
      'studentId': studentId,
      'score': score,
      'lastEvent': lastEvent,
      'deduction': deduction,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  void sendExamComplete({required String studentId, required int finalScore}) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'exam_complete',
      'studentId': studentId,
      'finalScore': finalScore,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  void _onDisconnect() {
    _connected = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
