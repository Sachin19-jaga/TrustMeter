import 'package:flutter/material.dart';
import 'app_theme.dart';

// Live badge with pulsing dot
class LiveBadge extends StatefulWidget {
  final Color color;
  final String label;
  const LiveBadge({super.key, this.color = AppColors.red, this.label = 'LIVE'});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _opacity,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(widget.label,
              style: TextStyle(color: widget.color, fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// Score progress bar
class ScoreBar extends StatelessWidget {
  final int score;
  final double height;
  const ScoreBar({super.key, required this.score, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final color = ScoringRules.scoreColor(score);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2035),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: score / 100.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

// Score circle widget
class ScoreCircle extends StatelessWidget {
  final int score;
  final double size;
  const ScoreCircle({super.key, required this.score, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final color = ScoringRules.scoreColor(score);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$score',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              )),
          Text('/100',
              style: TextStyle(
                fontSize: size * 0.11,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }
}

// Camera corner bracket widget
class CameraCorners extends StatelessWidget {
  final Color color;
  const CameraCorners({super.key, this.color = AppColors.cyan});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _corner(top: 10, left: 10, borderTop: true, borderLeft: true),
        _corner(top: 10, right: 10, borderTop: true, borderRight: true),
        _corner(bottom: 10, left: 10, borderBottom: true, borderLeft: true),
        _corner(bottom: 10, right: 10, borderBottom: true, borderRight: true),
      ],
    );
  }

  Widget _corner({
    double? top, double? left, double? right, double? bottom,
    bool borderTop = false, bool borderLeft = false,
    bool borderRight = false, bool borderBottom = false,
  }) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: borderTop ? BorderSide(color: color, width: 2) : BorderSide.none,
            left: borderLeft ? BorderSide(color: color, width: 2) : BorderSide.none,
            right: borderRight ? BorderSide(color: color, width: 2) : BorderSide.none,
            bottom: borderBottom ? BorderSide(color: color, width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// Flagged event row
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
  Widget build(BuildContext context) {
    final dotColor = deduction >= 30
        ? AppColors.red
        : deduction >= 20
            ? const Color(0xFFF39C12)
            : const Color(0xFFE67E22);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          Text('-$deduction → $scoreAfter',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.red)),
        ],
      ),
    );
  }
}
