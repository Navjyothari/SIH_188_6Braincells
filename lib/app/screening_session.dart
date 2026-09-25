// lib/app/screening_session.dart
// M3 — Face Verification Module / Session State
//
// ScreeningSession is the single source of truth for one complete
// checkpoint screening event: document capture → OCR → live selfie →
// face verification → combined evidence display.
//
// All screens that need to read or write session data access this via
// Provider.of<ScreeningSession>(context) or context.read<ScreeningSession>().
//
// Lifecycle:
//   - Created once at app start (via ChangeNotifierProvider in main.dart).
//   - reset() is called when "New Screening" is tapped on the result screen.
//   - The session never persists to disk — evidence persistence is the
//     responsibility of a separate storage layer (not yet implemented here).
//
// Privacy:
//   - documentImagePath and selfieImagePath point to JPEG files in the
//     device's temp directory. These are transient captures; they are NOT
//     retained in permanent storage by this session object.
//   - faceResult contains only status + score + threshold + model version;
//     no face image or embedding vector is stored here.

import 'package:flutter/foundation.dart';
import '../modules/face_verification/face_verification_result.dart';

/// Stub for OCR field extraction result.
/// Replace with the real OCR result type when the OCR module is wired in.
class OcrResult {
  final bool isAvailable;
  final String? documentType;
  final Map<String, String> extractedFields;
  final List<String> flaggedRules;
  final String
      state; // 'NO_INCONSISTENCY_DETECTED' | 'REVIEW_REQUIRED' | 'UNSUPPORTED' | 'RECAPTURE'

  const OcrResult({
    required this.isAvailable,
    this.documentType,
    this.extractedFields = const {},
    this.flaggedRules = const [],
    required this.state,
  });

  /// Placeholder shown before OCR runs.
  factory OcrResult.pending() => const OcrResult(
        isAvailable: false,
        state: 'PENDING',
        extractedFields: {},
        flaggedRules: [],
      );

  /// Stub result used during development before OCR is wired in.
  factory OcrResult.developmentStub() => const OcrResult(
        isAvailable: true,
        documentType: 'Fictional Passport (TD3)',
        state: 'REVIEW_REQUIRED',
        extractedFields: {
          'Surname': 'SPECIMEN',
          'Given Names': 'JOHN FICTIONAL',
          'Nationality': 'ZZZ',
          'Date of Birth': '01 JAN 1990',
          'Expiry Date': '01 JAN 2030',
          'Document Number': 'A1234567',
          'MRZ Line 1': 'P<ZZZSPECIMEN<<JOHN<FICTIONAL',
          'MRZ Line 2': 'A12345670ZZZ9001016M3001010',
        },
        flaggedRules: [
          'Date of Birth field and MRZ DOB differ by 1 day',
        ],
      );
}

/// ScreeningSession — ChangeNotifier holding state for one complete screening.
///
/// Screens read from and write to this object via Provider:
///   - DocumentCaptureScreen  → writes documentImagePath, ocrResult
///   - LiveSelfieCaptureScreen → writes selfieImagePath, faceResult (or skips)
///   - ScreeningEvidenceScreen → reads all fields
///
/// Face verification is OPTIONAL (fail-closed):
///   - If skipped: faceResult = FaceVerificationResult.skipped()
///   - If not run: faceResult = FaceVerificationResult.notRun()
///   - The OCR result and evidence screen display regardless of faceResult.
class ScreeningSession extends ChangeNotifier {
  // -------------------------------------------------------------------------
  // State fields
  // -------------------------------------------------------------------------

  /// Absolute path to the document JPEG saved during document capture.
  /// This is passed as `referenceImagePath` to the face verification channel.
  /// Retained at full resolution for the Kotlin ML Kit detector.
  String? documentImagePath;

  /// Absolute path to the selfie JPEG captured by LiveSelfieCaptureScreen.
  /// Passed as `liveImagePath` to the face verification channel.
  String? selfieImagePath;

  /// Result of the OCR + rules pass over the document image.
  /// Starts as OcrResult.pending(); set by DocumentCaptureScreen after capture.
  OcrResult ocrResult = OcrResult.pending();

  /// Result of face verification. Null means verification has not been attempted.
  /// NOT_RUN means it was attempted but could not produce a verdict.
  /// 'skipped' reason is surfaced via the result's modelVersion field.
  FaceVerificationResult? faceResult;

  /// True while the face verification channel call is in-flight.
  bool isFaceVerifying = false;

  // -------------------------------------------------------------------------
  // Write methods (called by screens)
  // -------------------------------------------------------------------------

  /// Called by DocumentCaptureScreen after rear-camera capture.
  /// [path] must be a full-resolution JPEG path readable by BitmapFactory.
  void setDocumentImage(String path) {
    documentImagePath = path;
    // Reset downstream state whenever a new document is captured.
    selfieImagePath = null;
    faceResult = null;
    ocrResult = OcrResult.developmentStub(); // Replace with real OCR call.
    notifyListeners();
  }

  /// Called by LiveSelfieCaptureScreen after front-camera capture + confirmation.
  void setSelfieImage(String path) {
    selfieImagePath = path;
    notifyListeners();
  }

  /// Called after the face verification channel call completes.
  void setFaceResult(FaceVerificationResult result) {
    faceResult = result;
    isFaceVerifying = false;
    notifyListeners();
  }

  /// Called when face verification is starting (shows loading indicator).
  void setFaceVerifying() {
    isFaceVerifying = true;
    faceResult = null;
    notifyListeners();
  }

  /// Called when the officer taps "Skip face verification".
  /// Sets status NOT_RUN so the evidence screen shows it clearly,
  /// with a human-readable reason. Face check is never a blocking gate.
  void skipFaceVerification() {
    faceResult = FaceVerificationResult.skippedByOfficer();
    isFaceVerifying = false;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  /// Resets the session to its initial state for a new screening.
  /// Called when "New Screening" is tapped on the evidence screen.
  void reset() {
    documentImagePath = null;
    selfieImagePath = null;
    ocrResult = OcrResult.pending();
    faceResult = null;
    isFaceVerifying = false;
    notifyListeners();
  }
}
