import 'dart:convert';
import 'package:flutter/material.dart';

// ── ScoreEvent ────────────────────────────────────────────────────────────────
class ScoreEvent {
  final String label;
  final int deduction;
  final int scoreAfter;
  final DateTime time;

  ScoreEvent({
    required this.label,
    required this.deduction,
    required this.scoreAfter,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'deduction': deduction,
        'scoreAfter': scoreAfter,
        'time': time.toIso8601String(),
      };

  factory ScoreEvent.fromJson(Map<String, dynamic> json) => ScoreEvent(
        label: json['label'],
        deduction: json['deduction'],
        scoreAfter: json['scoreAfter'],
        time: DateTime.parse(json['time']),
      );
}

// ── ExamResult ────────────────────────────────────────────────────────────────
// Stores a completed exam session — saved to SharedPreferences
class ExamResult {
  final String studentId;
  final String studentName;
  final int finalScore;
  final DateTime examDate;
  final int durationSeconds;
  final List<ScoreEvent> events;

  ExamResult({
    required this.studentId,
    required this.studentName,
    required this.finalScore,
    required this.examDate,
    required this.durationSeconds,
    required this.events,
  });

  String get trustLabel {
    if (finalScore >= 70) return 'TRUSTED';
    if (finalScore >= 40) return 'SUSPICIOUS';
    return 'HIGH RISK';
  }

  Color get scoreColor {
    if (finalScore >= 70) return const Color(0xFF2ECC71);
    if (finalScore >= 40) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String get initials {
    final parts = studentName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return studentName.isNotEmpty
        ? studentName.substring(0, studentName.length.clamp(0, 2)).toUpperCase()
        : 'S';
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'finalScore': finalScore,
        'examDate': examDate.toIso8601String(),
        'durationSeconds': durationSeconds,
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        studentId: json['studentId'],
        studentName: json['studentName'] ?? json['studentId'],
        finalScore: json['finalScore'],
        examDate: DateTime.parse(json['examDate']),
        durationSeconds: json['durationSeconds'] ?? 0,
        events: (json['events'] as List? ?? [])
            .map((e) => ScoreEvent.fromJson(e))
            .toList(),
      );

  static String encodeList(List<ExamResult> results) =>
      jsonEncode(results.map((r) => r.toJson()).toList());

  static List<ExamResult> decodeList(String source) {
    try {
      return (jsonDecode(source) as List)
          .map((r) => ExamResult.fromJson(r))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ── Student (kept for compatibility) ─────────────────────────────────────────
class Student {
  final String id;
  final String name;
  int score;
  int flagCount;
  bool isOnline;

  Student({
    required this.id,
    required this.name,
    this.score = 100,
    this.flagCount = 0,
    this.isOnline = true,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  Color get scoreColor {
    if (score >= 70) return const Color(0xFF2ECC71);
    if (score >= 40) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String get trustLabel {
    if (score >= 70) return 'TRUSTED';
    if (score >= 40) return 'SUSPICIOUS';
    return 'HIGH RISK';
  }
}
