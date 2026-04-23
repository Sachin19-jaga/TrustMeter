import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF07101E);
  static const surface = Color(0xFF0D1525);
  static const border = Color(0xFF1A2840);
  static const borderLight = Color(0xFF1E3A5F);

  static const cyan = Color(0xFF00B4FF);
  static const green = Color(0xFF2ECC71);
  static const yellow = Color(0xFFF39C12);
  static const red = Color(0xFFE74C3C);

  static const textPrimary = Color(0xFFD0E8FF);
  static const textSecondary = Color(0xFF8899BB);
  static const textMuted = Color(0xFF445566);
}

class AppTextStyles {
  static TextStyle rajdhani({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      fontFamily: 'Rajdhani',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle label({
    double size = 10,
    Color color = AppColors.textMuted,
    double letterSpacing = 0.8,
  }) {
    return TextStyle(
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle body({
    double size = 12,
    Color color = AppColors.textSecondary,
  }) {
    return TextStyle(fontSize: size, color: color);
  }
}

class AppDecorations {
  static BoxDecoration card({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
      );

  static BoxDecoration outerCard() => BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.border, width: 2),
      );
}

// Scoring constants
class ScoringRules {
  static const int multipleFaces = 30;
  static const int lookingAway = 10;
  static const int leftFrame = 20;
  static const int excessiveHeadMovement = 10;

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
