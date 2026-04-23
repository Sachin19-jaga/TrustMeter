import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/score_service.dart';
import '../widgets/app_theme.dart';
import 'exam_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController   = TextEditingController();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

  void _startExam() async {
    if (_idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Student ID')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    context.read<ScoreService>().startExam(
      studentId:   _idController.text.trim(),
      studentName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : _idController.text.trim(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExamScreen(studentId: _idController.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cyan, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Text('TM', style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.cyan,
                      )),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('TRUST METER', style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 26, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, letterSpacing: 3,
              )),
              const SizedBox(height: 4),
              const Text('AI EXAM INTEGRITY SYSTEM', style: TextStyle(
                fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.5,
              )),
              const SizedBox(height: 48),

              _buildField(_nameController, 'Full Name', Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildField(_idController, 'Student ID / Email', Icons.person_outline),
              const SizedBox(height: 12),
              _buildField(_passController, 'Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.videocam_outlined, color: AppColors.cyan, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Front camera access is required for exam monitoring.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _startExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.background))
                      : const Text('START EXAM', style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 16, fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        )),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Your session will be monitored and recorded.',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
