import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final List<Student> _students = [
    Student(id: 'S001', name: 'Arun Kumar', score: 78, flagCount: 2),
    Student(id: 'S002', name: 'Priya R', score: 100, flagCount: 0),
    Student(id: 'S003', name: 'Mani Vel', score: 42, flagCount: 4),
    Student(id: 'S004', name: 'Deepa S', score: 90, flagCount: 1),
    Student(id: 'S005', name: 'Raj Kumar', score: 65, flagCount: 3),
    Student(id: 'S006', name: 'Anita M', score: 100, flagCount: 0),
  ];

  int get _flaggedCount => _students.where((s) => s.score < 70).length;
  int get _avgScore => _students.isEmpty
      ? 0
      : _students.map((s) => s.score).reduce((a, b) => a + b) ~/ _students.length;
  int get _trustedCount => _students.where((s) => s.score >= 70).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ADMIN DASHBOARD',
                      style: TextStyle(
                        fontFamily: 'Rajdhani', fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: 1,
                      )),
                  Row(children: [
                    const LiveBadge(color: AppColors.green, label: 'LIVE'),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8, mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: [
                        _statCard('ACTIVE', '${_students.length}', AppColors.cyan),
                        _statCard('FLAGGED', '$_flaggedCount', AppColors.red),
                        _statCard('AVG SCORE', '$_avgScore', AppColors.yellow),
                        _statCard('TRUSTED', '$_trustedCount', AppColors.green),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('LIVE STUDENT SCORES',
                        style: TextStyle(
                            fontSize: 9, color: AppColors.textMuted,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ..._students.map(_studentRow),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Rajdhani', fontSize: 24,
                    fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );

  Widget _studentRow(Student student) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppDecorations.card(),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withOpacity(0.1),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Text(student.initials,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: AppColors.cyan)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text('${student.flagCount} flags',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      width: 60, height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2035),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: student.score / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ScoringRules.scoreColor(student.score),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Text('${student.score}',
                style: TextStyle(
                  fontFamily: 'Rajdhani', fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ScoringRules.scoreColor(student.score),
                )),
          ],
        ),
      );
}
