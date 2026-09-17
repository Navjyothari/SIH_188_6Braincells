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
  final FaceVerificationStatus status;

  /// Cosine similarity ∈ [−1, 1], or null when status == notRun.
  final double? similarityScore;

  /// The THRESHOLD_MATCH constant used, or null when status == notRun.
  final double? thresholdUsed;

  /// Model identifier, e.g. "mobilefacenet-v1-apache2".
  final String modelVersion;

  const FaceVerificationResult({
    required this.status,
    required this.modelVersion,
    this.similarityScore,
    this.thresholdUsed,
  });

  /// Deserialises the Map returned over the MethodChannel.
  factory FaceVerificationResult.fromMap(Map<dynamic, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'NOT_RUN';
    final status = _parseStatus(statusStr);
    return FaceVerificationResult(
      status:          status,
      similarityScore: (map['similarityScore'] as num?)?.toDouble(),
      thresholdUsed:   (map['thresholdUsed']   as num?)?.toDouble(),
      modelVersion:    map['modelVersion'] as String? ?? 'unknown',
    );
  }

  /// Returns a NOT_RUN result — used when the module is disabled or
  /// before any verification has been attempted.
  factory FaceVerificationResult.notRun() => const FaceVerificationResult(
    status:       FaceVerificationStatus.notRun,
    modelVersion: 'mobilefacenet-v1-apache2',
  );

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
      'threshold: $thresholdUsed, model: $modelVersion)';
}
