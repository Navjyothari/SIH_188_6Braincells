# EdgeFace-XS offline 1:1 face-verification setup

## Status and decision

This document specifies the planned face-comparison module for the Android-first prototype. It is the design and implementation contract. The companion checklist records implementation progress; real-model licensing, device parity and evaluated thresholds are still pending. No approved recognition verdict is enabled by this document.

**Selected first candidate:** EdgeFace-S (`edgeface_s_gamma_05`), per user decision. Evaluate S first; XS is deferred until S has been measured. The filename is retained for existing links.

**Selection remains provisional:** benchmark EdgeFace-S (`edgeface_s_gamma_05`) alongside XS before the release choice. Official benchmarks list CFP-FP 95.74 vs 94.71 and AgeDB-30 97.03 vs 96.08 (S vs XS), with 306.12 vs 154 MFLOPs. These are not photographed-ID accuracy or device-latency results. Prefer S only if it improves development-set document-to-selfie results and meets the end-to-end p95/memory/thermal budget on representative lower-end phones. Otherwise use XS. Freeze this model choice before the final subject-disjoint held-out evaluation; do not use that test set to choose the winner. Keep each candidate's provenance, parity, quality/threshold configuration and reports separate. XS is an explicitly validated alternative, never a silent runtime fallback. The runtime accepts a single explicitly selected S or XS manifest and checksum; there is no automatic model fallback. Selecting S requires its own full release validation.

**Why this candidate:** S is a pretrained edge-device face-embedding model with 3.65M parameters and about 306 MFLOPs. XS (1.77M parameters, 154 MFLOPs) is deferred until S has been evaluated. The model family won the compact track of the 2023 Efficient Face Recognition competition. The official repository is BSD-3-Clause licensed and supplies pretrained weights. See [the official EdgeFace repository](https://github.com/otroshi/edgeface) and [its licence](https://github.com/otroshi/edgeface/blob/main/LICENSE).

**Runtime promise:** after the APK has been installed, the face-verification flow must need no network connection, account, cloud service, model download, or remote face database.

**What it does:** compares the portrait cropped from the document currently being screened against a newly captured live face for the same screening session.

**What it does not do:** it is not a 1:N identity search, a civil-identity lookup, an authenticity verdict, a watch-list check, an age/gender classifier, or liveness detection. A person holding up a print or replaying a screen can still defeat a plain 2D face comparison. Do not present `MATCH` as proof of identity.

## Required product boundary

```text
Supported fictional document portrait          Live selfie captured in this session
                 |                                               |
                 +----------- local face detection -------------+
                                      |
                               quality gates
                                      |
                            common face alignment
                                      |
                 EdgeFace-XS embeddings, generated on device
                                      |
                         local cosine comparison only
                                      |
       MATCH / UNCERTAIN / NO_MATCH / NOT_RUN + explanation
```

The portrait must come from the document being examined. A bundled face image is permitted only as a synthetic smoke-test fixture. It must never be the normal reference for all travellers.

Keep the module optional. The document-screening workflow must still complete when this module is disabled, unsupported, unavailable, or returns `NOT_RUN`.

## Why this is not the existing MobileFaceNet path

The current experimental branch is wired for a TFLite MobileFaceNet contract: `112 x 112` RGB input and a `192`-value embedding output. EdgeFace-XS is normally distributed as PyTorch weights; its practical mobile route is an ONNX model executed with ONNX Runtime. It uses a different model file and embedding contract. Do not reuse:

- the MobileFaceNet TFLite interpreter;
- its hard-coded `192`-float output buffer;
- its model version string;
- its thresholds; or
- a cosine score recorded under MobileFaceNet as an EdgeFace score.

The Efficient Face Recognition competition describes EdgeFace-XS as producing a 512-dimensional feature. Treat that as an expectation, not a reason to hard-code the Android buffer: inspect the exact downloaded ONNX asset at startup and fail closed if it does not match the release manifest.

## Model provenance and asset policy

### Approved acquisition route

1. Start from the official `otroshi/edgeface` release/checkpoint for `edgeface_xs_gamma_06`.
2. Export that exact checkpoint to ONNX in a controlled Python environment, **or** use an ONNX export only when its source checkpoint, conversion command, exporter version, and SHA-256 hash are documented.
3. Run desktop inference tests on the ONNX asset before adding it to Android.
4. Put the final model at the fixed Android asset path `android/app/src/main/assets/ml/edgeface.onnx`.
5. Record the model file hash, checkpoint hash, source URL, commit/tag, conversion tool versions, tensor metadata, and licence notice in a release manifest.

The community ONNX export at [yakhyo/edgeface-onnx](https://github.com/yakhyo/edgeface-onnx) lists an XS export around 6.9 MB. It is useful for experimentation, but the team must retain the provenance record above before shipping it.

### Never do this

- Do not download the model on first launch.
- Do not leave the model in `Downloads` and assume it will be packaged.
- Do not commit a model with unknown origin merely because its filename says `edgeface`.
- Do not create a random-weight substitute. A structurally valid model with random weights is not face recognition.
- Do not use public InsightFace pretrained weights as a casual substitute: their published model-zoo weights have non-commercial research restrictions. See [InsightFace model licensing](https://github.com/deepinsight/insightface/blob/master/python-package/docs/model_zoo.md).

### Large-file handling

The final model may be kept out of ordinary Git history if repository policy requires it, but the build/release process must have a deterministic, offline-capable asset step. Choose one of these approaches and document the choice in the manifest:

1. Git LFS with the object available to the release build.
2. A controlled internal release-asset store with a checksum-pinned retrieval step before the release build.
3. A separately retained, checksummed binary delivered with the release pack.

The installed APK must contain the asset. A release that expects a developer to copy a model by hand after installation is not offline-ready.

## Software prerequisites

### Development workstation

- Flutter stable SDK and a project pinned to a tested Flutter/Dart version.
- Android Studio with the Android SDK platforms/build tools required by the project.
- A JDK version compatible with the project’s Android Gradle Plugin; use the version recorded by the repository, not a machine-global guess.
- Android Debug Bridge (ADB) for installing and profiling a release build.
- Python only for the controlled export/desktop validation step. It is **not** part of the phone runtime.
- Python packages for the export environment, pinned in a requirements lock file: PyTorch, ONNX, ONNX Runtime, NumPy, Pillow/OpenCV, and the exact EdgeFace repository requirements.

### Android application dependencies

- `com.microsoft.onnxruntime:onnxruntime-android`, pinned to one tested version.
- A fully bundled face detector. The standalone ML Kit artifact (`com.google.mlkit:face-detection`) is appropriate; do not use a Play-services download-on-demand detector in an airplane-mode demo.
- Kotlin coroutines for background inference and Flutter platform-channel work already used by the app.

Use Android Kotlin for model execution. Flutter owns screens, session state, and results; Kotlin owns image decoding, face detection, alignment, ONNX Runtime, and embedding generation. This avoids relying on an unmaintained Flutter ONNX wrapper.

ONNX Runtime supports Android local inference. Start with CPU/XNNPACK for a predictable baseline; Only CPU and explicitly benchmarked XNNPACK configurations are supported. NNAPI was deprecated in Android 15 and is excluded from the supported baseline; any experiment requires separate validation. ONNX Runtime notes that accelerator performance is model- and device-specific. See [ONNX Runtime mobile deployment](https://onnxruntime.ai/docs/tutorials/mobile/) and [NNAPI guidance](https://onnxruntime.ai/docs/execution-providers/NNAPI-ExecutionProvider.html).

### Android build configuration

Add the model as an uncompressed asset if the Android loader memory-maps it. Keep all inference off the UI thread. If release minification is enabled, include the ONNX Runtime keep rule documented by ONNX Runtime:

```proguard
-keep class ai.onnxruntime.** { *; }
```

Pin the exact Maven dependency version and run a minified release build on a physical phone. A debug build passing does not prove a release build will load the runtime.

## Hardware requirements and supported-device policy

### Baseline performance class

The target is Android phones as low-end as the Samsung Galaxy M21, across manufacturers and chipsets. The M21 is a performance-class reference, not a required handset or a device allowlist. It has an Exynos 9611: four Cortex-A73 cores at up to 2.3 GHz, four Cortex-A53 cores at up to 1.7 GHz, LPDDR4X memory, and a Mali-G72 MP3 GPU. Samsung lists the chipset as end-of-life. See [Samsung’s Exynos 9611 specification](https://semiconductor.samsung.com/kr/processor/mobile-processor/exynos-9611/).

It is reasonable to target one document image and a small number of selfie captures on this device. It is not reasonable to promise continuous 30 FPS recognition or a hardware-accelerated path without measurements.

### Minimum field requirements

- Android device supported by the final app’s `minSdkVersion` and the tested ONNX Runtime version.
- At least 4 GB RAM for the M21-class target; validate memory use while the camera is active.
- A working rear camera for the document and front camera for the selfie.
- Enough free local storage for the APK, encrypted case record, and temporary camera buffers.
- No network, SIM, Google account, or Play Services connection required after installation.

### Performance acceptance gate

On each representative lower-end handset, with battery above 30% and normal thermal conditions, run 20 sequential supported comparisons. A release candidate passes only when all of the following hold:

- no crash, out-of-memory error, or unreleased camera session;
- the UI remains responsive;
- two to three selfie candidates plus one document portrait finish within the agreed product budget; start with a **2-second end-to-end target** and record the p50/p95 rather than claiming it as achieved beforehand;
- no unbounded memory growth across the 20 runs;
- a second test after five minutes of repeated work shows any thermal slowdown;
- a forced airplane-mode first launch completes successfully.

If XS misses the acceptance gate, evaluate EdgeFace-XXS as a separate candidate with its own provenance, parity results, and thresholds; never switch models silently. Do not silently reduce quality checks just to make a benchmark look faster.

## Exact inference contract

### Alignment is mandatory

The document portrait and selfie must be aligned using the same geometry before they enter the model. Alignment should use stable facial landmarks, transform each face to the model’s expected `112 x 112` crop, and preserve an auditable record of the alignment version—not the face image itself.

The official EdgeFace inference example converts the aligned image to a tensor and applies `Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])`. The expected numerical transform is therefore:

```text
RGB float pixel in [0, 255]
    -> pixel / 255.0
    -> (value - 0.5) / 0.5
    -> range [-1.0, 1.0]
```

For the common ONNX export, the tensor layout is expected to be `NCHW`:

```text
[1, 3, 112, 112], float32
```

Do not assume this from a filename. At startup and in tests, read the session metadata and compare it to the release manifest. Reject an unexpected input layout, size, dtype, or output size with `NOT_RUN`.

### Embedding and score

1. Create an embedding for the aligned document portrait.
2. Create an embedding for each accepted aligned selfie frame.
3. Validate finite, nonzero embeddings and L2-normalize at the comparison boundary (idempotent for already normalized output). Record the original output contract in the manifest.
4. Compute cosine similarity for each document/selfie pair.
5. Aggregate repeated selfie scores using a documented conservative rule, such as the median of quality-approved captures.
6. Classify the aggregate score using frozen, evaluated thresholds.

Cosine similarity is not a probability and must never be displayed as “percent identity”, “document authenticity”, or “fraud probability.”

### Quality gates before inference

Return `NOT_RUN` or `RECAPTURE` before comparison when any condition fails:

- zero or multiple candidate faces in either image;
- face crop too small for the defined minimum pixel size;
- blur above the frozen threshold;
- severe over-/under-exposure;
- head yaw/pitch/roll beyond the validated range;
- eyes/central facial landmarks unavailable for alignment;
- major occlusion such as mask, sunglasses, or hand;
- rotated/mirrored image not corrected to the standard orientation; or
- model asset/session/inference failure.

The UI must explain the recoverable cause, for example: “Use a well-lit frontal selfie; remove face covering.” Never turn an unavailable comparison into a green pass.

## Flutter/Kotlin interface

Expose one narrow asynchronous MethodChannel call, for example:

```text
verifyFace(
  documentImagePath: String,
  selfieImagePaths: List<String>,
  sessionId: String,
  modelManifestId: String
) -> {
  status: "MATCH" | "UNCERTAIN" | "NO_MATCH" | "NOT_RUN" | "RECAPTURE",
  similarityScore: number | null,
  thresholdVersion: String | null,
  modelVersion: String,
  detectorVersion: String,
  alignmentVersion: String,
  reasonCode: String,
  timingMs: { decode, detect, align, embed, total }
}
```

Rules for the interface:

- Do not return raw embeddings to Dart, logs, analytics, an export, or a server.
- Do not persist the live selfie or document crop outside the approved encrypted case record.
- Do not use the `sessionId` as an identity lookup key.
- Close the ONNX session/interpreter and recycle buffers when the screen/session ends.
- Serialize model execution or use a documented, safe pooling strategy; do not share a mutable session across concurrent camera callbacks without synchronization.

## Suggested project layout

```text
android/app/src/main/
├── assets/ml/
│   ├── edgeface.onnx                  # release asset; checksum in manifest
│   └── edgeface_manifest.json         # source, hashes, tensor contract
└── kotlin/com/sih188/borderdoc/face/
    ├── FaceDetectorAndAligner.kt
    ├── FaceQualityGate.kt
    ├── EdgeFaceEmbeddingRunner.kt
    ├── FaceVerificationModule.kt
    └── FaceVerificationResult.kt

lib/modules/face_verification/
├── face_verification_service.dart
├── face_verification_result.dart
└── face_verification_widget.dart

docs/
└── edgeface-xs-offline-face-verification.md
```

Keep a model manifest like this beside the asset:

```json
{
  "modelId": "edgeface-xs-gamma-06",
  "modelVersion": "<official-release-or-git-commit>",
  "sourceCheckpoint": "<official-url>",
  "codeLicense": "BSD-3-Clause",
  "weightsLicenseStatus": "pending verification",
  "trainingDataTermsStatus": "pending verification",
  "sourceCheckpointSha256": "<sha256>",
  "onnxSha256": "<sha256>",
  "conversionCommand": "<versioned-command>",
  "input": { "shape": [1, 3, 112, 112], "dtype": "float32", "normalization": "(rgb/255 - 0.5) / 0.5" },
  "output": { "shape": [1, 512], "dtype": "float32", "l2Normalized": "<verified true|false>" },
  "detectorVersion": "<bundled-detector-version>",
  "alignmentVersion": "<alignment-algorithm-version>"
}
```

The values above are a template. Fill them only from the inspected, shipped model.

## Installation and implementation sequence

### 1. Prepare a reproducible model workspace

Create a separate `ml/edgeface/` environment outside the Android runtime. Pin Python and all packages. Save:

- the official source repository commit/tag;
- checkpoint checksum;
- export script and command;
- ONNX checker output;
- ONNX input/output metadata;
- one fixed set of synthetic test images and expected embedding hashes/tolerances.

Never make a desktop model conversion an unrecorded one-off action.

### 2. Validate the ONNX asset on desktop

Before Android work, write a test that:

1. loads the exact file;
2. asserts file hash and input/output contract;
3. checks the model executes on a `112 x 112` aligned RGB fixture;
4. checks output has the expected dimensions and finite values;
5. checks normalization status and cosine calculation;
6. confirms the same image compared with itself is approximately `1.0`; and
7. records distinct-face smoke-test scores without inventing a recognition threshold from synthetic fixtures.

This is a structural test, not an accuracy study.

### 3. Add Android ONNX Runtime

Add the pinned Android runtime dependency, configure the asset path, and build a simple Kotlin smoke test that:

1. opens the model from assets;
2. logs only non-sensitive tensor metadata;
3. passes a fixed synthetic tensor;
4. asserts output dimensions and finite values; and
5. closes the session.

Run this on a representative M21-class handset in release mode before connecting it to the camera.

### 4. Implement common detection and alignment

Use one bundled detector for both document and selfie input. Decode image orientation first. Detect faces once per still image, select a face only when exactly one face satisfies the quality gates, align it, and pass exactly the same preprocessing implementation to EdgeFace.

For a live selfie flow, do detection/quality preview at a throttled cadence and only run EdgeFace after the user captures a quality-approved frame. Do not run full embedding inference on every camera preview frame on lower-end phones.

### 5. Connect Flutter last

When Kotlin image-to-embedding tests pass, expose the MethodChannel. Flutter should show processing and error states, never decide the score itself. Display the result plus a clear limitation label such as: “Experimental face similarity check; not an authoritative identity verification.”

### 6. Freeze thresholds only after evaluation

Split consented test subjects before tuning:

- **Development set:** selects image-quality gates, aggregation rule, and thresholds.
- **Held-out test set:** evaluates the frozen configuration once.

Include genuine document-photo-to-selfie pairs and impostor pairs. Vary lighting, glasses, facial hair, pose, screen/document capture quality, and the two test phones. Report false matches, false non-matches, `NOT_RUN`, and `RECAPTURE` separately with denominators. A threshold from MobileFaceNet, a paper benchmark, or another team’s demo is not valid for EdgeFace-XS in this workflow.

## Device test matrix

Run every release candidate in airplane mode on at least two Android phones:

| Scenario | Expected result |
|---|---|
| Fresh install, radios disabled | Model loads; first comparison finishes without download. |
| Lower-end handset, clear genuine pair | A result is produced and timing is recorded. |
| Lower-end handset, clear impostor pair | Not silently reported as `MATCH`. |
| Dim/blurred selfie | `RECAPTURE` or `NOT_RUN`; never a green result. |
| Multiple faces in frame | `RECAPTURE` / explicit reason. |
| Rotated document capture | Orientation is corrected or explicitly rejected. |
| Model removed/corrupted | `NOT_RUN`, core document workflow remains usable. |
| 20 sequential comparisons | No crash, leak, camera lock, or unbounded slowdown. |
| Restart after completed screening | Stored result and model/threshold versions remain inspectable. |

Save only aggregate timings, result categories, model versions, and consented evaluation identifiers in the test report. Do not upload biometric images or embeddings to a public repository.

## Privacy, consent, and security

Face images and embeddings are biometric data. This prototype must:

- use only fictional document portraits, synthetic fixtures, or explicitly consented volunteers;
- obtain consent before capture and state the test purpose and retention period;
- avoid persistent embeddings unless a separately approved retention design is implemented;
- encrypt approved local case records before persistence;
- keep raw face crops and embeddings out of logs, analytics, crash reports, and exported evidence files;
- provide a deletion/reset route for consented test data; and
- retain only the model, detector, alignment, and threshold versions needed to reproduce a result.

The Android detector can locate faces and landmarks but does not itself recognize people. The embedding model performs the comparison. See [ML Kit face-detection documentation](https://developers.google.com/ml-kit/vision/face-detection).

## Failure handling and user-facing wording

| Condition | Result | Example wording |
|---|---|---|
| No usable face in document portrait | `NOT_RUN` | “No clear face could be read from this document portrait.” |
| No usable face in selfie | `RECAPTURE` | “Take a frontal selfie in better light.” |
| Multiple faces | `RECAPTURE` | “Ensure exactly one person is visible.” |
| Asset/runtime/inference fault | `NOT_RUN` | “Face comparison is unavailable on this device.” |
| Score below frozen no-match boundary | `NO_MATCH` | “The captured selfie did not sufficiently match the document portrait.” |
| Score in threshold guard band | `UNCERTAIN` | “The comparison is inconclusive; recapture or refer for human review.” |
| Score meets frozen match boundary | `MATCH` | “The experimental face-similarity check met the configured threshold.” |

`MATCH` must be phrased as an experimental similarity result, never as “identity verified”, “document genuine”, or “fraud cleared.”

## Release checklist

- [ ] Exact model source and licence reviewed.
- [ ] Checkpoint, ONNX, and manifest SHA-256 values recorded.
- [ ] Desktop input/output and deterministic fixture tests pass.
- [ ] Android smoke test passes in a minified release build.
- [ ] At least two representative lower-end devices from different chipset families pass airplane-mode first launch.
- [ ] Per-device p50/p95 timing, memory, and 20-run stability report stored.
- [ ] Thresholds frozen before held-out evaluation.
- [ ] Held-out results include false match, false non-match, recapture, and not-run denominators.
- [ ] Face images and embeddings absent from logs, exports, and the source repository.
- [ ] UI labels and demo script use “experimental face similarity,” not authentication claims.
- [ ] Core screening workflow still works if this module is disabled.

## Implementation additions and acceptance gates

### Licence evidence, not assumptions

Record code, checkpoint redistribution, and training-data terms separately, including source URLs, retrieved notices, review date, intended use, and unresolved restrictions. The repository BSD-3-Clause notice is verified; the official Idiap S model card explicitly lists CC BY-NC-SA 4.0 for the model, so do not infer BSD checkpoint terms. Review the non-commercial/share-alike conditions and unresolved WebFace training-data terms before redistribution; see [the evidence record](edgeface-licence-and-provenance.md). Do not mark these checked, or claim hackathon/commercial permission, without evidence. Do not ship model weights while redistribution permission is unresolved. Runtime code and synthetic numerical tests can be developed independently.

### Versioned five-point geometry

Use EXIF-normalized, unmirrored image coordinates. Map ML Kit LEFT_EYE/RIGHT_EYE to the two eye points ordered by image x, NOSE_BASE to the nose point, and MOUTH_LEFT/MOUTH_RIGHT to the two mouth corners ordered by image x. Never substitute MOUTH_BOTTOM. Require all five finite in-bounds landmarks and a non-degenerate fit. Reject excessive pose before ordering.

The 112 x 112 square reference is: image-left eye (38.2946, 51.6963), image-right eye (73.5318, 51.5014), nose (56.0252, 71.7366), image-left mouth (41.5493, 92.3655), image-right mouth (70.7299, 92.2041). Pin this to the official EdgeFace square-crop reference. Fit an orientation-preserving least-squares similarity transform (scale, rotation, translation; equivalent to the 2D Umeyama objective), with no reflection, shear, or independent x/y scale. Use inverse mapping, bilinear interpolation, integer pixel-center coordinates and black border fill. Version geometry and sampling together.

ML Kit's nose/eye definitions are not assumed interchangeable with MTCNN. Compare ML Kit and the official reference detector/alignment on the same consented evaluation inputs, reporting failure rates, score shifts, and verification accuracy. A numerical parity pass does not establish detector equivalence.

### Three separate parity checks

1. Original PyTorch checkpoint versus exported desktop ONNX on identical tensors.
2. Desktop ONNX versus Android ONNX on identical tensors, including CPU and any supported XNNPACK configuration.
3. Python versus Kotlin preprocessing on fixed lossless RGB images and supplied landmarks; compare aligned pixels, NCHW tensors, embeddings and pair scores. Test RGB channel order, transform direction, orientation, border pixels and resizing.

Start identical-tensor FP32 validation at cosine >= 0.9999 and maximum absolute difference <= 0.0001 for L2-normalized embeddings; record measured errors before freezing the tolerance. Do not silently loosen a failure to 0.98. Image preprocessing has a separately recorded tolerance. JPEG decoder and detector differences need their own end-to-end evaluation. Synthetic fixtures establish correctness, not biometric accuracy. Test embeddings must remain local/test-only and never enter the application result channel.

### Document and selfie quality policies

Use separately versioned minimum face-width/height rules in source pixels before upscaling. Check a document portrait's clipped highlights/glare as well as blur and exposure; bright paper outside the face must not trigger the glare metric. Initial engineering cutoffs are provisional until development-set evaluation. Grayscale printing is supported as three equal RGB channels. Collect real document-photo-to-selfie conditions: printing/security patterns, glare, small portraits, compression, facial hair, glasses and expected age gaps. The UNCERTAIN band exists for inconclusive comparisons; a recapture may not fix an old portrait. Major occlusion cannot be inferred reliably from landmark presence alone and remains a release evaluation gate.

### Runtime and asset integrity

Verify the bundled ONNX SHA-256 against the manifest before creating a session. Require manifest tensor names, shapes and dtypes to agree with runtime metadata. Reject non-finite or zero-norm outputs. Initialize and warm up on a background worker; report cold startup separately from warmed inference. Serialize verification and shutdown, bound input image memory, and close native resources.

Benchmark CPU thread counts 1, 2 and 4 on representative lower-end devices; four threads do not imply affinity to the four performance cores. Start with CPU, two intra-op threads, one inter-op thread, sequential execution. XNNPACK has its own pool: test its pool and ORT fallback pool together and avoid oversubscription. No NNAPI production path. No quantization in this baseline; any future quantized model needs fresh parity and held-out accuracy evaluation.

### Evaluation honesty and future work

Use subject-disjoint development/test splits. Freeze the quality policy, aggregation rule, detector, model, alignment and thresholds as one configuration. Report MATCH, UNCERTAIN, NO_MATCH, NOT_RUN and RECAPTURE with denominators and confidence intervals. With few volunteers, findings are indicative only; many correlated pairs do not establish a low false-accept rate. Use subject-aware resampling where observations share identities and report distinct subject counts. Zero observed false accepts is not a zero population false-accept rate.

Future work: randomized head-pose challenges may use ML Kit Euler angles but do not establish liveness and do not stop replayed video. EdgeFace-S escalation for UNCERTAIN is a later experiment requiring evaluation of the entire cascade, separate thresholds and device budgets. Neither is required for the XS baseline.

The actionable implementation and manual verification record is in [edgeface-implementation-checklist.md](edgeface-implementation-checklist.md).

## Sources

- [EdgeFace official repository, model variants, benchmarks, and weights](https://github.com/otroshi/edgeface)
- [EdgeFace BSD-3-Clause licence](https://github.com/otroshi/edgeface/blob/main/LICENSE)
- [Community ONNX exports and approximate model sizes](https://github.com/yakhyo/edgeface-onnx)
- [ONNX Runtime mobile deployment guidance](https://onnxruntime.ai/docs/tutorials/mobile/)
- [ONNX Runtime NNAPI execution-provider guidance](https://onnxruntime.ai/docs/execution-providers/NNAPI-ExecutionProvider.html)
- [Samsung Exynos 9611 specifications](https://semiconductor.samsung.com/kr/processor/mobile-processor/exynos-9611/)
- [ML Kit face detection](https://developers.google.com/ml-kit/vision/face-detection)

- [NNAPI deprecation](https://developer.android.com/ndk/guides/neuralnetworks/migration-guide)
- [XNNPACK thread-pool guidance](https://onnxruntime.ai/docs/execution-providers/Xnnpack-ExecutionProvider.html)
- [Official alignment reference](https://github.com/otroshi/edgeface/blob/main/face_alignment/mtcnn_pytorch/src/align_trans.py)


### Startup timing clarification — 2026-09-24

The user accepts approximately three seconds for cold startup. Record cold startup separately; it is not subject to the two-second warm-processing target. Warm latency, sustained behaviour and memory still require measurement. This does not establish a new hard cold-start maximum.


### Automatic portrait location and document scope — 2026-09-25

Capture the whole document for OCR. Do not require portrait tapping, manual cropping or hiding legitimate secondary/security portraits. Face detection produces candidate face regions; EdgeFace embeds the selected aligned portrait, not the full page. Detection count is not a count of distinct people.

The initial automatic adapter is deliberately narrow: a single detected document face uses the existing pipeline; multiple faces require a recognized Indian passport-style layout. Bundled Latin OCR reads the full image. The adapter requires unambiguous Republic of India, passport, surname and given-name labels with consistent relative geometry, then selects the unique detected portrait to the left of the name-field column beneath the header. It never chooses a face just because it is largest, leftmost in the camera frame, or coloured. No text values or OCR transcript are saved by this locator. Unknown/ambiguous layouts abstain. This is a provisional layout rule, not a learned universal document detector or an authenticity check.

The live input continues to require exactly one face. Selected document portraits still pass all existing quality/alignment checks. The decision policy is additionally bound to `documentPortraitVersion=single-face-or-indian-passport-ocr-anchors-v1`; existing evaluation approval remains false. Original full-resolution pixels remain available to the eventual OCR field pipeline. The on-screen OCR result in this branch remains a development placeholder; adding layout-anchor OCR is not completion of OCR field extraction/validation.

The existing roadmap currently scopes the screening prototype to one fictional passport-style layout and explicitly excludes Aadhaar support. Local document-to-live face experiments are not proof of a working document parser. Broader passport/visa/ID/Aadhaar coverage requires separate layout adapters, field parsers and tests before it is advertised. No inherent EdgeFace restriction requires passports, but document-screening support is a separate capability.

Dependency: bundled `com.google.mlkit:text-recognition:16.0.1`, following the official Android integration guide: https://developers.google.com/ml-kit/vision/text-recognition/v2/android. It is packaged at build time; no OCR model download is requested on the phone.
