import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/score_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ScoreService(),
      child: const TrustMeterApp(),
    ),
  );
}

class TrustMeterApp extends StatelessWidget {
  const TrustMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trust Meter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07101E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00B4FF),
          secondary: Color(0xFF2ECC71),
          surface: Color(0xFF0D1525),
          error: Color(0xFFE74C3C),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07101E),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
