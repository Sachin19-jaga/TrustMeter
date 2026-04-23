import 'package:flutter/material.dart';
import '../models/models.dart';

class ScoreService extends ChangeNotifier {
  int _score = 100;
  final List<ScoreEvent> _events = [];
  bool _examActive = false;
  int _secondsElapsed = 0;

  static const int deductMultipleFaces = 30;
  static const int deductLookAway = 10;
  static const int deductLeftFrame = 20;
  static const int deductHeadMovement = 10;

  int get score => _score;
  List<ScoreEvent> get events => List.unmodifiable(_events);
  bool get examActive => _examActive;
  int get secondsElapsed => _secondsElapsed;

  Color get scoreColor {
    if (_score >= 70) return const Color(0xFF2ECC71);
    if (_score >= 40) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String get trustLabel {
    if (_score >= 70) return 'TRUSTED';
    if (_score >= 40) return 'SUSPICIOUS';
    return 'HIGH RISK';
  }

  void startExam() {
    _score = 100;
    _events.clear();
    _examActive = true;
    _secondsElapsed = 0;
    notifyListeners();
  }

  void endExam() {
    _examActive = false;
    notifyListeners();
  }

  void deductScore(String label, int amount) {
    if (!_examActive || _score <= 0) return;
    _score = (_score - amount).clamp(0, 100);
    _events.add(ScoreEvent(
      label: label,
      deduction: amount,
      scoreAfter: _score,
      time: DateTime.now(),
    ));
    notifyListeners();
  }

  void onMultipleFacesDetected() => deductScore('Multiple faces detected', deductMultipleFaces);
  void onLookingAway() => deductScore('Looking away frequently', deductLookAway);
  void onLeftFrame() => deductScore('Candidate left frame', deductLeftFrame);
  void onExcessiveHeadMovement() => deductScore('Excessive head movement', deductHeadMovement);

  void tickTimer() {
    _secondsElapsed++;
    notifyListeners();
  }

  void reset() {
    _score = 100;
    _events.clear();
    _examActive = false;
    _secondsElapsed = 0;
    notifyListeners();
  }
}
