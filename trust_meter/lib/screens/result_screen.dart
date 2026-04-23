import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/score_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class ResultScreen extends StatelessWidget {
  final String studentId;
  const ResultScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ScoreService>();
    final score = svc.score;
    final color = ScoringRules.scoreColor(score);
    final label = ScoringRules.trustLabel(score);
    final events = svc.events;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EXAM RESULTS',
                      style: TextStyle(
                        fontFamily: 'Rajdhani', fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: 1,
                      )),
                  Text('ID: $studentId',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 24),

              // Final score hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Text('FINAL INTEGRITY SCORE',
                        style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted,
                          letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 10),
                    Text('$score',
                        style: TextStyle(
                          fontFamily: 'Rajdhani', fontSize: 72,
                          fontWeight: FontWeight.w700,
                          color: color, height: 1,
                        )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color),
                      ),
                      child: Text(label,
                          style: TextStyle(
                            color: color, fontSize: 11,
                            fontWeight: FontWeight.w500, letterSpacing: 1,
                          )),
                    ),
                    const SizedBox(height: 16),
                    ScoreBar(score: score, height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Breakdown
              _card('SCORE BREAKDOWN',
                Column(children: [
                  _row('Initial Score', '100', color: AppColors.green),
                  ...events.map((e) =>
                      _row(e.label, '-${e.deduction}', color: AppColors.red)),
                  const Divider(color: Color(0xFF1A2840), height: 12),
                  _row('Final Score', '$score', color: color, bold: true),
                ])),
              const SizedBox(height: 10),

              // Summary
              _card('EXAM SUMMARY',
                Column(children: [
                  _row('Student ID', studentId, color: AppColors.textSecondary),
                  _row('Total Flags', '${events.length}',
                      color: events.isEmpty ? AppColors.green : AppColors.yellow),
                  _row('Face Detection', '98% of session', color: AppColors.green),
                  _row('Duration', '60 minutes', color: AppColors.textSecondary),
                ])),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('VIEW ADMIN DASHBOARD',
                      style: TextStyle(
                        fontFamily: 'Rajdhani', fontSize: 14,
                        fontWeight: FontWeight.w700, letterSpacing: 1,
                      )),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    svc.reset();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('NEW EXAM SESSION',
                      style: TextStyle(
                          fontFamily: 'Rajdhani', fontSize: 13, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _row(String label, String value,
      {Color color = AppColors.textSecondary, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: bold ? FontWeight.w500 : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 14 : 11,
                    color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
