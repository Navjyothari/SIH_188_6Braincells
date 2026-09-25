import 'package:flutter_test/flutter_test.dart';
import 'package:borderdoc/modules/face_verification/face_verification_result.dart';
import 'package:borderdoc/modules/face_verification/face_verification_service.dart';

void main() {
  test('Malformed green results fail closed', () {
    for (final score in [null, double.nan, double.infinity, 1.1, 0.1]) {
      final r = FaceVerificationResult.fromMap({
        'status': 'MATCH',
        'similarityScore': score,
        'thresholdUsed': 0.8,
        'thresholdVersion': 'test',
        'modelVersion': 'test'
      });
      expect(r.status, FaceVerificationStatus.notRun);
      expect(r.similarityScore, isNull);
    }
    expect(
        FaceVerificationResult.fromMap({
          'status': 'MATCH',
          'similarityScore': 1.0,
          'thresholdUsed': 0.8
        }).status,
        FaceVerificationStatus.notRun);
  });
  test('Only a complete valid result can show MATCH', () {
    final valid = <String, dynamic>{
      'status': 'MATCH',
      'similarityScore': 0.9,
      'thresholdUsed': 0.8,
      'thresholdVersion': 'test',
      'modelVersion': 'test',
      'detectorVersion': 'test',
      'alignmentVersion': 'test',
      'qualityVersion': 'test',
      'reasonCode': 'COMPLETED'
    };
    expect(FaceVerificationResult.fromMap(valid).status,
        FaceVerificationStatus.match);
    expect(
        FaceVerificationResult.fromMap(
            {...valid, 'reasonCode': 'INFERENCE_FAILED'}).status,
        FaceVerificationStatus.notRun);
    expect(
        FaceVerificationResult.fromMap(
            {...valid, 'similarityScore': double.nan}).status,
        FaceVerificationStatus.notRun);
  });
  test('Failures never expose stale scores', () {
    for (final state in ['RECAPTURE', 'NOT_RUN', 'UNKNOWN']) {
      final r = FaceVerificationResult.fromMap(
          {'status': state, 'similarityScore': 0.99, 'thresholdUsed': 0.8});
      expect(r.similarityScore, isNull);
      expect(r.thresholdUsed, isNull);
      expect(r.status, isNot(FaceVerificationStatus.match));
    }
  });
  test('Document is required before calling native code', () async {
    final result =
        await FaceVerificationService().verifyFace(liveImagePath: 'selfie.jpg');
    expect(result.status, FaceVerificationStatus.notRun);
  });
}
