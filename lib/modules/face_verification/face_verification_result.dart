// face_verification_result.dart
// M3 — Face Verification Module (optional, removable)
//
// Dart counterpart of the Kotlin FaceVerificationResult data class.
// All fields mirror the MethodChannel map returned by FaceVerificationModule.toMap().

/// Verification status enum — matches Kotlin status strings exactly.
///
/// NOT_RUN covers all cases where the module could not produce a verdict:
///   - module disabled by feature flag
///   - TFLite model failed to load
///   - no face detected in either image
///   - consent/licence conditions not met
///
/// IMPORTANT: The module NEVER returns a fake score or a hardcoded verdict.
/// If NOT_RUN, similarityScore and thresholdUsed are both null.
enum FaceVerificationStatus {
  /// Both faces matched above the THRESHOLD_MATCH threshold.
  match,

  /// Score was below THRESHOLD_UNCERTAIN — faces are different.
  noMatch,

  /// Score fell between THRESHOLD_UNCERTAIN and THRESHOLD_MATCH —
  /// inconclusive; human review recommended.
  uncertain,

  /// Module did not run or could not produce a result.
  notRun,
}

/// Structured result returned by the face verification pipeline.
///
/// OUTPUT CONTRACT:
/// ┌─────────────────────────────────────────────────────────────┐
/// │  status          : FaceVerificationStatus                   │
/// │  similarityScore : double? (cosine sim ∈ [−1, 1]) or null  │
/// │  thresholdUsed   : double? or null                          │
/// │  modelVersion    : String (always set)                      │
/// └─────────────────────────────────────────────────────────────┘
///
/// ⚠ similarityScore is a cosine SIMILARITY between two face embeddings.
///   It is NOT an authenticity score, a forgery probability, or any
///   signal about document genuineness.
class FaceVerificationResult {
  /// The outcome of the verification attempt
  final FaceVerificationStatus status;

  /// Cosine similarity ∈ [-1, 1]. Null if NOT_RUN.
  final double? similarityScore;

  /// The threshold value against which the score was evaluated
  final double? thresholdUsed;

  /// Version of the MobileFaceNet asset used
  final String modelVersion;

  /// Debug info string for detection failures
  final String? debugInfo;

  /// Absolute paths to the aligned crop images saved for debugging
  final String? liveCropPath;
  final String? refCropPath;

  const FaceVerificationResult({
    required this.status,
    this.similarityScore,
    this.thresholdUsed,
    required this.modelVersion,
    this.debugInfo,
    this.liveCropPath,
    this.refCropPath,
  });

  /// Returns a NOT_RUN result — used when the module is disabled or
  /// before any verification has been attempted.
  factory FaceVerificationResult.notRun() => const FaceVerificationResult(
        status:       FaceVerificationStatus.notRun,
        modelVersion: 'mobilefacenet-v1-192d-bsd3',
      );

  /// Returns a NOT_RUN result with the reason "skipped by officer".
  ///
  /// Per project rules, face verification is NEVER a mandatory gate.
  /// Officers may skip it at any point in the flow. This factory
  /// produces a clearly labelled NOT_RUN that surfaces the skip reason
  /// on the evidence screen, distinct from a detection failure.
  factory FaceVerificationResult.skippedByOfficer() => const FaceVerificationResult(
        status:       FaceVerificationStatus.notRun,
        modelVersion: 'not-run/skipped-by-officer',
      );

  /// Deserialises the Map returned over the MethodChannel.
  factory FaceVerificationResult.fromMap(Map<dynamic, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'NOT_RUN';
    final status = _parseStatus(statusStr);
    return FaceVerificationResult(
      status:          status,
      similarityScore: (map['similarityScore'] as num?)?.toDouble(),
      thresholdUsed:   (map['thresholdUsed']   as num?)?.toDouble(),
      modelVersion:    map['modelVersion'] as String? ?? 'unknown',
      debugInfo:       map['debugInfo'] as String?,
      liveCropPath:    map['liveCropPath'] as String?,
      refCropPath:     map['refCropPath'] as String?,
    );
  }

  static FaceVerificationStatus _parseStatus(String s) {
    switch (s) {
      case 'MATCH':     return FaceVerificationStatus.match;
      case 'NO_MATCH':  return FaceVerificationStatus.noMatch;
      case 'UNCERTAIN': return FaceVerificationStatus.uncertain;
      default:          return FaceVerificationStatus.notRun;
    }
  }

  /// Human-readable label for display only — NOT a claim of authenticity.
  String get displayLabel {
    switch (status) {
      case FaceVerificationStatus.match:     return 'Face match';
      case FaceVerificationStatus.noMatch:   return 'Face mismatch';
      case FaceVerificationStatus.uncertain: return 'Inconclusive';
      case FaceVerificationStatus.notRun:    return 'Not run';
    }
  }

  @override
  String toString() =>
      'FaceVerificationResult(status: $status, score: $similarityScore, '
      'threshold: $thresholdUsed, model: $modelVersion, liveCrop: $liveCropPath, refCrop: $refCropPath)';
}
