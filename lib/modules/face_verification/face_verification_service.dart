// face_verification_service.dart
// M3 — Face Verification Module (optional, removable)
//
// Flutter-side platform channel bridge. This is the ONLY file that
// communicates with the Kotlin FaceVerificationModule. All other Flutter
// code imports this service, never the channel directly.

import 'package:flutter/services.dart';
import 'face_verification_result.dart';

/// FaceVerificationService — Flutter ↔ Kotlin platform channel bridge.
///
/// Usage:
/// ```dart
/// final service = FaceVerificationService();
/// if (!await service.isModuleAvailable()) return;
///
/// final result = await service.verifyFace(
///   liveImagePath: '/data/.../captured_face.jpg',
/// );
/// ```
///
/// TOGGLE BEHAVIOUR:
///   Set [enabled] to false (or read from a feature-flag store) to disable
///   the module without modifying any other file. verifyFace() returns
///   FaceVerificationResult.notRun() immediately when disabled.
///
/// PRIVACY:
///   This service passes only file paths over the channel — no pixel data,
///   no embedding vectors. The Kotlin side discards all intermediates after
///   computing the final result.
class FaceVerificationService {
  // Channel name must match FACE_CHANNEL in MainActivity.kt exactly.
  static const _channel = MethodChannel('com.sih188.borderdoc/face_verification');

  /// Feature flag — set to false to disable the module globally.
  /// When false, [verifyFace] returns NOT_RUN immediately.
  bool enabled;

  FaceVerificationService({this.enabled = true});

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Checks whether the TFLite model loaded successfully on the native side.
  ///
  /// Returns false if the module is disabled, or if the Kotlin side is
  /// unavailable (e.g. running on iOS or a simulator without TFLite).
  Future<bool> isModuleAvailable() async {
    if (!enabled) return false;
    try {
      return await _channel.invokeMethod<bool>('isModuleAvailable') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Runs face verification on [liveImagePath] against [referenceImagePath].
  ///
  /// Parameters:
  ///   [liveImagePath]      — absolute path to the live-captured face JPEG.
  ///   [referenceImagePath] — absolute path to the reference face JPEG, or
  ///                          null to use the bundled synthetic reference.
  ///
  /// Returns a [FaceVerificationResult] whose status is one of:
  ///   MATCH | NO_MATCH | UNCERTAIN | NOT_RUN
  ///
  /// Never throws — all errors surface as NOT_RUN.
  Future<FaceVerificationResult> verifyFace({
    required String liveImagePath,
    String? referenceImagePath,
  }) async {
    // Guard: module disabled
    if (!enabled) {
      return FaceVerificationResult.notRun();
    }

    try {
      final raw = await _channel.invokeMapMethod<dynamic, dynamic>(
        'verifyFace',
        {
          'liveImagePath':      liveImagePath,
          'referenceImagePath': referenceImagePath,
        },
      );

      if (raw == null) return FaceVerificationResult.notRun();
      return FaceVerificationResult.fromMap(raw);

    } on PlatformException catch (e) {
      // Log but do NOT rethrow — the module must fail silently.
      // Replace with your app's logger if available.
      assert(() {
        // ignore: avoid_print
        print('[FaceVerification] PlatformException: ${e.message}');
        return true;
      }());
      return FaceVerificationResult.notRun();
    } catch (_) {
      return FaceVerificationResult.notRun();
    }
  }
}
