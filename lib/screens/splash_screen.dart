import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(_pulseCtrl);

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07101E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value * _pulse.value,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00B4FF), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B4FF).withOpacity(0.3),
                          blurRadius: 30, spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 82, height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D1525),
                          border: Border.all(
                              color: const Color(0xFF1E3050), width: 1.5),
                        ),
                        child: const Center(
                          child: Text('TM', style: TextStyle(
                            fontFamily: 'Rajdhani', fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00B4FF),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Animated text
            AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _textSlide.value),
                  child: Column(children: [
                    const Text('TRUST METER', style: TextStyle(
                      fontFamily: 'Rajdhani', fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8F0FE), letterSpacing: 4,
                    )),
                    const SizedBox(height: 6),
                    const Text('AI EXAM INTEGRITY SYSTEM', style: TextStyle(
                      fontSize: 11, color: Color(0xFF4A6080), letterSpacing: 2,
                    )),
                    const SizedBox(height: 32),
                    // Loading dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00B4FF).withOpacity(
                              i == 0 ? 1.0 : i == 1 ? 0.6 : 0.3),
                        ),
                      )),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
