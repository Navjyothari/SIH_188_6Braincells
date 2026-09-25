enum FaceVerificationStatus { match, noMatch, uncertain, notRun, recapture }

/// Experimental similarity result. No embeddings or image paths cross this boundary.
class FaceVerificationResult {
  final FaceVerificationStatus status;
  final double? similarityScore;
  final double? thresholdUsed;
  final String modelVersion;
  final String reasonCode;
  final String? thresholdVersion;
  final String? detectorVersion;
  final String? alignmentVersion;
  final String? qualityVersion;
  final Map<String, num> timingMs;

  const FaceVerificationResult(
      {required this.status,
      this.similarityScore,
      this.thresholdUsed,
      required this.modelVersion,
      this.reasonCode = 'UNAVAILABLE',
      this.thresholdVersion,
      this.detectorVersion,
      this.alignmentVersion,
      this.qualityVersion,
      this.timingMs = const {}});

  factory FaceVerificationResult.notRun() => const FaceVerificationResult(
      status: FaceVerificationStatus.notRun,
      modelVersion: 'edgeface-s-gamma-05/pending');
  factory FaceVerificationResult.skippedByOfficer() =>
      const FaceVerificationResult(
          status: FaceVerificationStatus.notRun,
          modelVersion: 'not-run/skipped-by-officer',
          reasonCode: 'SKIPPED');

  factory FaceVerificationResult.fromMap(Map<dynamic, dynamic> map) {
    try {
      final status = switch (map['status']) {
        'MATCH' => FaceVerificationStatus.match,
        'NO_MATCH' => FaceVerificationStatus.noMatch,
        'UNCERTAIN' => FaceVerificationStatus.uncertain,
        'RECAPTURE' => FaceVerificationStatus.recapture,
        _ => FaceVerificationStatus.notRun,
      };
      final scored = {
        FaceVerificationStatus.match,
        FaceVerificationStatus.noMatch,
        FaceVerificationStatus.uncertain
      }.contains(status);
      final score = (map['similarityScore'] as num?)?.toDouble();
      final threshold = (map['thresholdUsed'] as num?)?.toDouble();
      final version = map['thresholdVersion'] as String?;
      if (scored &&
          (map['reasonCode'] != 'COMPLETED' ||
              [
                'modelVersion',
                'detectorVersion',
                'alignmentVersion',
                'qualityVersion'
              ].any((key) =>
                  map[key] is! String || (map[key] as String).isEmpty))) {
        return FaceVerificationResult.notRun();
      }
      if (scored &&
          (score == null ||
              !score.isFinite ||
              score < -1 ||
              score > 1 ||
              threshold == null ||
              !threshold.isFinite ||
              threshold < -1 ||
              threshold > 1 ||
              version == null ||
              version.isEmpty ||
              (status == FaceVerificationStatus.match && score < threshold))) {
        return FaceVerificationResult.notRun();
      }
      return FaceVerificationResult(
          status: status,
          similarityScore: scored ? score : null,
          thresholdUsed: scored ? threshold : null,
          modelVersion: map['modelVersion'] as String? ?? 'unknown',
          reasonCode: map['reasonCode'] as String? ?? 'UNAVAILABLE',
          thresholdVersion: scored ? version : null,
          detectorVersion: map['detectorVersion'] as String?,
          alignmentVersion: map['alignmentVersion'] as String?,
          qualityVersion: map['qualityVersion'] as String?,
          timingMs: Map<String, num>.from(map['timingMs'] as Map? ?? {}));
    } catch (_) {
      return FaceVerificationResult.notRun();
    }
  }

  String get displayLabel => switch (status) {
        FaceVerificationStatus.match => 'Similarity threshold met',
        FaceVerificationStatus.noMatch => 'Low face similarity',
        FaceVerificationStatus.uncertain => 'Inconclusive',
        FaceVerificationStatus.notRun => 'Not run',
        FaceVerificationStatus.recapture => 'Retake selfie',
      };

  String get explanation {
    if (reasonCode == 'EVALUATION_PENDING')
      return 'Face comparison is awaiting validation. Continue with manual review.';
    if (reasonCode == 'MODEL_UNAVAILABLE')
      return 'Face comparison is unavailable. Continue with manual review.';
    if (reasonCode == 'DOCUMENT_REQUIRED')
      return 'Capture the document portrait first.';
    if (reasonCode == 'SKIPPED') return 'Face comparison was skipped.';
    if (reasonCode.contains('GLARE'))
      return 'Retake the document photo without glare on the portrait.';
    if (reasonCode.contains('TOO_SMALL'))
      return 'Move closer so the portrait is clear and large enough.';
    if (reasonCode.contains('PORTRAIT_LAYOUT'))
      return 'The main portrait could not be located automatically in this document layout. Continue with manual review.';
    if (reasonCode.contains('MULTIPLE_FACES'))
      return 'Include exactly one face in the image.';
    if (reasonCode.contains('BLUR'))
      return 'Hold the camera steady and retake a sharp photo.';
    if (reasonCode.contains('POSE'))
      return 'Use a frontal portrait and look straight at the selfie camera.';
    if (reasonCode.contains('EXPOSURE'))
      return 'Retake the photo in even lighting.';
    if (reasonCode.startsWith('DOCUMENT_'))
      return 'No usable portrait could be read from this document photo.';
    if (status == FaceVerificationStatus.recapture)
      return 'Retake a clear, frontal selfie with your face unobstructed.';
    if (reasonCode == 'BUSY')
      return 'A comparison is already running. Try again shortly.';
    return 'Face comparison did not run. Other screening checks are unaffected.';
  }
}
