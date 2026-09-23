# Face crop and orientation correction

Based on face-detection commit 830fcfd. The reported debug crops showed background instead of the document portrait and an upside-down partial live face.

Two preprocessing errors caused this: reversing eye correspondences could introduce a half-turn, and transforming the complete source with Bitmap.createBitmap rebased its bounding box before the top-left crop. That discarded the translation intended to position the face.

The helper now orders eyes by their image coordinates after EXIF normalization and draws the similarity transform directly onto a fixed 112x112 canvas. Both eyes land at the canonical positions. Missing or invalid landmarks return an unavailable result rather than embedding an unaligned rectangle. The decoder handles all eight EXIF orientations, including mirrored cases. Detector work uses a bounded background wait so alignment exceptions cannot leave a latch waiting forever. Match thresholds are unchanged.

Regression coverage includes translated, scaled, rolled and reversed eye inputs; invalid landmarks; actual JPEG decoding for all eight EXIF orientations; and the bundled detector/model comparing the synthetic portrait against itself at a different position in a larger image. These tests establish preprocessing behavior, not population-level face accuracy. They do not access the user's face captures.

The supplied model is bundled locally, SHA-256 be4bc7cfc53f7bc336d0f28b1ab92535f618c913a422b683210750f6b5354854. Assets remain ignored by Git.

Retest with a new document and live capture. Existing debug thumbnails and scores were produced by the old preprocessing and are not recomputed. A remaining mismatch after correct crops still requires evaluation; the change does not promise a MATCH or validate the existing thresholds.

This branch remains the standalone face experiment. Its OCR card is still a labelled development stub. Other review findings, including biometric cache lifecycle and independent model evaluation, are not resolved by this crop fix.

## Build verification - 23 September 2026

- Debug APK built successfully; all 20 existing Kotlin unit tests passed.
- APK inspection confirmed the supplied model is bundled with the hash above.
- APK SHA-256: ef903cb7f5be317c3a2a6b5c9246e7f76a8685e916e1ed1d9d30c748374580f7.
- Target for physical regression: connected CPH2613 phone, Android 16.
- In-place phone installation succeeded. All four Android instrumentation tests passed on that phone (1.105 seconds), including actual ML Kit detection and TFLite inference on the supplied synthetic portrait. The same portrait placed at a different location in a larger canvas produced MATCH with the existing threshold. All eight JPEG orientations and 12 combinations of position/scale/roll/eye ordering passed their pixel assertions.
- User subsequently confirmed that new document/live captures were correctly cropped and upright. The displayed similarity was 0.7165 (UNCERTAIN). This confirms the reported visual preprocessing problem is resolved in that attempt; it does not validate recognition accuracy or thresholds. Existing user photos were not accessed for the automated tests.

## User question and response - 23 September 2026

**Question (paraphrased):** The crops are now correct and upright, but two photos reported by the user to depict the same person, taken about five days apart with little visible change, produced only about 0.71. Is this because the TFLite model was not custom-trained? What exactly is wrong?

**Response:** The observed value, 0.7165, is cosine similarity between face embeddings, not 71.65% confidence or a probability of identity. The current policy returns MATCH at or above 0.75, UNCERTAIN from 0.60 to below 0.75, and NO_MATCH below 0.60. UNCERTAIN is therefore consistent with the implemented policy.

One comparison does not establish that custom training is needed. Pretrained face-comparison models are intended to compare identities outside their training subjects. Training on this user's own photos would not establish general reliability. The exact cause of this score cannot be identified from the screenshot alone, and the five-day interval alone does not explain it.

Possible contributors and remaining uncertainties:

- Capture differences: the document thumbnail appears softer and has different lighting and glasses reflections. These are plausible contributors, not measured causes in this case.
- Preprocessing compatibility: the geometry fix ensures correct eye placement, but optimal preprocessing for these exact weights remains unverified. The cited upstream app uses a bounding-box crop followed by square resizing and `(pixel - 128) / 128`, whereas this app uses two-eye alignment and `(pixel - 127.5) / 127.5`. Neither difference has been demonstrated to explain this score; the upstream app is not itself proof of the model's training preprocessing. See [upstream implementation](https://github.com/MCarlomagno/FaceRecognitionAuth/blob/master/lib/services/ml_service.dart).
- Threshold calibration: reproducible evidence supporting 0.75 for this exact model and document-to-camera workflow has not been supplied. The numerical cutoff is a policy choice that needs evaluation.

The passing synthetic regression compares the same underlying photo at different canvas positions. It establishes preprocessing consistency and real inference, not recognition performance across different photographs or people.

Recommended investigation, not yet performed:

1. Compare the original portrait file with a photographed document version to measure recapture effects.
2. Compare multiple fresh captures under consistent lighting.
3. Evaluate same-person and different-person pairs across consenting participants, select thresholds using development data, and evaluate them on separate held-out subjects. Record raw results, failures and uncertain outcomes.

Do not lower the threshold just to pass this example: that may increase acceptance of different-person pairs. Verify preprocessing and score distributions first; consider another model or training only if evaluation justifies it. No thresholds were changed in response to this example. No user portraits, screenshots, or biometric embeddings are included in this documentation commit.
