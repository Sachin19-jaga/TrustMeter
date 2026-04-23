import 'package:flutter/material.dart';

// Represents a single suspicious behavior event
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
}

// models/student.dart
// Represents a student in admin dashboard

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
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
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


