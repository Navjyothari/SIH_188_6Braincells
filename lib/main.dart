// lib/main.dart
// BorderDoc — AI-Powered Offline Border Document Screening Prototype (SIH26188)
// M3 Integration — Application Entry Point & Flow Orchestration
//
// Flow:
//   Step 1: DocumentCaptureScreen  ('/')
//           - Rear camera document photo capture
//           - Retains full-res JPEG as documentImagePath
//           - Generates initial OCR / rule results (OcrResult)
//   Step 2: LiveSelfieCaptureScreen ('/selfie')
//           - Front-facing camera live preview
//           - One-touch capture & freeze
//           - Calls face_verification platform channel
//           - Provides "Skip" option (sets NOT_RUN / skipped-by-officer)
//   Step 3: ScreeningEvidenceScreen ('/result')
//           - Independent OCR results + FaceVerificationResultCard
//           - Complete evidence summary with reset for next screening

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/screening_session.dart';
import 'modules/face_verification/face_verification_service.dart';
import 'screens/document_capture_screen.dart';
import 'screens/live_selfie_capture_screen.dart';
import 'screens/screening_evidence_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce portrait mode for reliable checkpoint device operation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Instantiate the face verification platform service bridge
  final faceService = FaceVerificationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScreeningSession()),
        Provider<FaceVerificationService>.value(value: faceService),
      ],
      child: BorderDocApp(faceService: faceService),
    ),
  );
}

class BorderDocApp extends StatelessWidget {
  final FaceVerificationService faceService;

  const BorderDocApp({super.key, required this.faceService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BorderDoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58A6FF),
          secondary: Color(0xFF238636),
          surface: Color(0xFF161B22),
          background: Color(0xFF0D1117),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DocumentCaptureScreen(),
        '/selfie': (context) => LiveSelfieCaptureScreen(faceService: faceService),
        '/result': (context) => const ScreeningEvidenceScreen(),
      },
    );
  }
}
