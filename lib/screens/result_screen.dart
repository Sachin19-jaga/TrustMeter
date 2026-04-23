import 'dart:math';
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
    final svc    = context.watch<ScoreService>();
    final score  = svc.score;
    final color  = ScoringRules.scoreColor(score);
    final label  = ScoringRules.trustLabel(score);
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
                  const Text('EXAM RESULTS', style: TextStyle(
                    fontFamily: 'Rajdhani', fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: 1,
                  )),
                  Text('ID: $studentId', style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Final score hero ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Column(children: [
                  const Text('FINAL INTEGRITY SCORE', style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5,
                  )),
                  const SizedBox(height: 10),
                  Text('$score', style: TextStyle(
                    fontFamily: 'Rajdhani', fontSize: 72,
                    fontWeight: FontWeight.w700, color: color, height: 1,
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color),
                    ),
                    child: Text(label, style: TextStyle(
                      color: color, fontSize: 11,
                      fontWeight: FontWeight.w500, letterSpacing: 1,
                    )),
                  ),
                  const SizedBox(height: 16),
                  ScoreBar(score: score, height: 8),
                ]),
              ),
              const SizedBox(height: 12),

              // ── Score Timeline Graph ──────────────────────
              if (events.isNotEmpty)
                _card('SCORE TIMELINE',
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      painter: _TimelinePainter(events: events),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              if (events.isNotEmpty) const SizedBox(height: 10),

              // ── Score breakdown ───────────────────────────
              _card('SCORE BREAKDOWN',
                Column(children: [
                  _row('Initial Score', '100', color: AppColors.green),
                  ...events.map((e) =>
                      _row(e.label, '-${e.deduction}', color: AppColors.red)),
                  const Divider(color: Color(0xFF1A2840), height: 12),
                  _row('Final Score', '$score', color: color, bold: true),
                ])),
              const SizedBox(height: 10),

              // ── Summary ───────────────────────────────────
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
                  child: const Text('VIEW ADMIN DASHBOARD', style: TextStyle(
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
                    Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('NEW EXAM SESSION', style: TextStyle(
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
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
          fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.8)),
      const SizedBox(height: 10),
      child,
    ]),
  );

  Widget _row(String label, String value,
      {Color color = AppColors.textSecondary, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(
                fontSize: 11,
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w500 : FontWeight.normal)),
            Text(value, style: TextStyle(
                fontSize: bold ? 14 : 11,
                color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

// ── Score Timeline Painter ────────────────────────────────────────────────────
class _TimelinePainter extends CustomPainter {
  final List events;
  const _TimelinePainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty) return;

    // Build score points: start at 100, drop at each event
    final points = <Offset>[];
    double score = 100;
    points.add(Offset(0, _y(score, size.height)));

    for (int i = 0; i < events.length; i++) {
      final x = size.width * (i + 1) / (events.length + 1);
      score = (score - events[i].deduction).clamp(0, 100).toDouble();
      points.add(Offset(x, _y(score, size.height)));
    }
    points.add(Offset(size.width, _y(score, size.height)));

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A2840)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw filled area under line
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00B4FF).withOpacity(0.3),
          const Color(0xFF00B4FF).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF00B4FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw dots at event points
    for (int i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 4, Paint()
        ..color = const Color(0xFFE74C3C));
      canvas.drawCircle(points[i], 2, Paint()
        ..color = Colors.white);
    }

    // Labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final label in ['100', '75', '50', '25']) {
      final y = size.height * (100 - double.parse(label)) / 100;
      tp.text = TextSpan(text: label,
          style: const TextStyle(color: Color(0xFF4A6080), fontSize: 8));
      tp.layout();
      tp.paint(canvas, Offset(2, y - 5));
    }
  }

  double _y(double score, double height) =>
      height - (score / 100) * height * 0.85 - height * 0.05;

  @override
  bool shouldRepaint(_) => false;
}
