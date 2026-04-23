import 'package:flutter/material.dart';

class AppColors {
  static const Color background  = Color(0xFF07101E);
  static const Color surface     = Color(0xFF0D1525);
  static const Color cyan        = Color(0xFF00B4FF);
  static const Color green       = Color(0xFF2ECC71);
  static const Color yellow      = Color(0xFFF39C12);
  static const Color red         = Color(0xFFE74C3C);
  static const Color border      = Color(0xFF1A2840);
  static const Color borderLight = Color(0xFF1E3050);
  static const Color textPrimary   = Color(0xFFE8F0FE);
  static const Color textSecondary = Color(0xFFB0C4DE);
  static const Color textMuted     = Color(0xFF4A6080);
}

class AppDecorations {
  static BoxDecoration card() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  );
}

class ScoringRules {
  static Color scoreColor(int score) {
    if (score >= 70) return AppColors.green;
    if (score >= 40) return AppColors.yellow;
    return AppColors.red;
  }

  static String trustLabel(int score) {
    if (score >= 70) return 'TRUSTED';
    if (score >= 40) return 'SUSPICIOUS';
    return 'HIGH RISK';
  }
}
