import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VigilBorderApp());
}

class VigilBorderApp extends StatelessWidget {
  const VigilBorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIGIL-BORDER // Document Tamper & Threat Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF0F172A),
          error: Color(0xFFEF4444),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}
