import 'package:flutter/material.dart';
import 'app_theme.dart';

// ── Live Badge ────────────────────────────────────────────────────────────────
class LiveBadge extends StatefulWidget {
  final Color color;
  final String label;
  const LiveBadge({super.key, required this.color, required this.label});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.4 + 0.6 * _ctrl.value),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(widget.label,
              style: TextStyle(
                  fontSize: 9,
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
        ],
      );
}

// ── Score Bar ─────────────────────────────────────────────────────────────────
class ScoreBar extends StatelessWidget {
  final int score;
  final double height;
  const ScoreBar({super.key, required this.score, this.height = 5});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: score / 100,
          minHeight: height,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(
              ScoringRules.scoreColor(score)),
        ),
      );
}

// ── Event Row ─────────────────────────────────────────────────────────────────
class EventRow extends StatelessWidget {
  final String label;
  final int deduction;
  final int scoreAfter;
  const EventRow({
    super.key,
    required this.label,
    required this.deduction,
    required this.scoreAfter,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.red, size: 12),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
            Row(children: [
              Text('-$deduction',
                  style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('→ $scoreAfter',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10)),
            ]),
          ],
        ),
      );
}

// ── Camera Corners ────────────────────────────────────────────────────────────
class CameraCorners extends StatelessWidget {
  const CameraCorners({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CornerPainter());
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const len = 20.0;
    const r   = 6.0;

    // Top-left
    canvas.drawLine(const Offset(r, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width - r, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height - r), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
