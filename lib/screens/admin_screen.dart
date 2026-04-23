import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<ExamResult> _results = [];
  bool _loading = true;
  ExamResult? _expanded;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _loading = true);
    final results = await StorageService.getAllResults();
    results.sort((a, b) => b.examDate.compareTo(a.examDate)); // newest first
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _exportCSV() async {
    if (_results.isEmpty) return;

    // Build CSV content
    final buffer = StringBuffer();
    buffer.writeln('Student Name,Student ID,Final Score,Trust Level,Violations,Duration (sec),Exam Date');
    for (final r in _results) {
      final violations = r.events.map((e) => '${e.label}(-${e.deduction})').join(' | ');
      buffer.writeln(
        '"${r.studentName}",'
        '"${r.studentId}",'
        '${r.finalScore},'
        '"${r.trustLabel}",'
        '"$violations",'
        '${r.durationSeconds},'
        '"${r.examDate.toLocal().toString().substring(0, 16)}"'
      );
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/trust_meter_results.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Trust Meter Exam Results',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'),
            backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Results?',
            style: TextStyle(fontFamily: 'Rajdhani',
                fontSize: 20, color: AppColors.textPrimary)),
        content: const Text('This permanently deletes all exam records.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('Clear', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.clearAll();
      setState(() { _results = []; _expanded = null; });
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _statsGrid() {
    final avg = _results.isEmpty
        ? 0
        : _results.map((r) => r.finalScore).reduce((a, b) => a + b) ~/
            _results.length;
    final flagged  = _results.where((r) => r.finalScore < 70).length;
    final trusted  = _results.where((r) => r.finalScore >= 70).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _statCard('TOTAL',   '${_results.length}', AppColors.cyan),
        _statCard('FLAGGED', '$flagged',            AppColors.red),
        _statCard('AVG SCORE','$avg',               AppColors.yellow),
        _statCard('TRUSTED', '$trusted',            AppColors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) => Container(
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

  // ── Student row ────────────────────────────────────────────────────────────
  Widget _studentRow(ExamResult r) {
    final color = r.scoreColor;
    final isOpen = _expanded?.studentId == r.studentId &&
        _expanded?.examDate == r.examDate;

    return GestureDetector(
      onTap: () => setState(() => _expanded = isOpen ? null : r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen ? color.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Center(
                      child: Text(r.initials,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.studentName,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text('ID: ${r.studentId}',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Text(_timeAgo(r.examDate),
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Text('${r.events.length} flag(s)',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: r.events.isEmpty
                                      ? AppColors.green
                                      : AppColors.red)),
                        ]),
                      ],
                    ),
                  ),
                  // Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${r.finalScore}',
                          style: TextStyle(
                              fontFamily: 'Rajdhani', fontSize: 22,
                              fontWeight: FontWeight.w700, color: color)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(r.trustLabel,
                            style: TextStyle(
                                color: color, fontSize: 8,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted, size: 18),
                ],
              ),
            ),

            // Expanded detail panel
            if (isOpen) _detailPanel(r),
          ],
        ),
      ),
    );
  }

  Widget _detailPanel(ExamResult r) {
    final mins = r.durationSeconds ~/ 60;
    final secs = r.durationSeconds % 60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.border, height: 12),
          Row(children: [
            _chip(Icons.timer, 'Duration: ${mins}m ${secs}s'),
            const SizedBox(width: 8),
            _chip(Icons.bar_chart, 'Score: ${r.finalScore}/100'),
          ]),
          if (r.events.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('VIOLATIONS',
                style: TextStyle(fontSize: 9,
                    color: AppColors.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            ...r.events.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.remove_circle,
                            color: AppColors.red, size: 13),
                        const SizedBox(width: 6),
                        Text(e.label,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                      Text('-${e.deduction}',
                          style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ],
                  ),
                )),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('✅ No violations recorded',
                  style: TextStyle(color: AppColors.green, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.borderLight.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.textMuted, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
    ]),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    // Refresh button
                    GestureDetector(
                      onTap: _loadResults,
                      child: const Icon(Icons.refresh,
                          color: AppColors.textMuted, size: 20),
                    ),
                    const SizedBox(width: 8),
                    // Export CSV button
                    if (_results.isNotEmpty)
                      GestureDetector(
                        onTap: _exportCSV,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.green.withOpacity(0.4)),
                          ),
                          child: Row(children: const [
                            Icon(Icons.download,
                                color: AppColors.green, size: 13),
                            SizedBox(width: 4),
                            Text('CSV', style: TextStyle(
                                color: AppColors.green, fontSize: 10,
                                fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Clear button
                    if (_results.isNotEmpty)
                      GestureDetector(
                        onTap: _confirmClear,
                        child: const Icon(Icons.delete_outline,
                            color: AppColors.red, size: 20),
                      ),
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

            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.cyan))
                  : _results.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _loadResults,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statsGrid(),
                                const SizedBox(height: 14),
                                const Text('EXAM RESULTS',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textMuted,
                                        letterSpacing: 0.8)),
                                const SizedBox(height: 8),
                                ..._results.map(_studentRow),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 56),
        const SizedBox(height: 16),
        const Text('No exams recorded yet',
            style: TextStyle(fontFamily: 'Rajdhani',
                fontSize: 18, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text('Results will appear here after\nstudents complete their exams',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _loadResults,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cyan),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('REFRESH',
                style: TextStyle(color: AppColors.cyan,
                    fontFamily: 'Rajdhani', letterSpacing: 1)),
          ),
        ),
      ],
    ),
  );
}
