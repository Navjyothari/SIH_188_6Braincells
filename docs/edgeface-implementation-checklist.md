# EdgeFace implementation and verification record

This branch targets phones as low-end as the M21 across manufacturers, not one Samsung handset. Checked boxes below describe completed work, not a claim of face-recognition accuracy. Implementation is staged; the application deliberately returns NOT_RUN until real assets and evaluation gates are satisfied.

## 1. Specification and implementation

- [x] Bring the existing app and alignment fixes into `edgeface-xs-setup`.
- [x] Specify hardware class, licence evidence, exact geometry, three parity checks, document quality, threading, statistics and future work.
- [x] Add pinned ONNX Runtime CPU execution, SHA-256 validation, exact tensor contract, warm-up and native resource cleanup.
- [x] Add five-point similarity fitting, bilinear RGB/NCHW preprocessing, quality gates and finite/nonzero embedding checks.
- [x] Require the captured document; remove the runtime synthetic-reference fallback and old thresholds.
- [x] Withhold verdicts unless model-specific evaluation settings are approved; bind thresholds to model hash, detector, alignment, quality and aggregation versions.
- [x] Serialize work off the UI thread; bound queued requests and decoded image size.
- [x] Return reason codes, timing and version metadata; remove debug crop persistence and crop paths from results.
- [x] Add an export tool that verifies a supplied official source commit/checkpoint hash and compares PyTorch with ONNX.
- [x] Add independent Python preprocessing fixtures, Kotlin regression tests, Flutter fail-closed tests and an explicit device parity test.

## 2. Automated verification on this workstation

- [x] Python reference tests: 4 passed.
- [x] Flutter result/service tests: 4 passed.
- [x] Kotlin unit tests: 7 passed, including all 37,632 Python/Kotlin tensor components.
- [x] Android instrumentation APK compiled; seven local device tests subsequently passed on Nord CE4.
- [x] Final minified release APK build passed (unsigned; no EdgeFace weights bundled).
- [x] Flutter analysis: no errors or warnings; 13 existing API-deprecation information messages.
- [x] EdgeFace-S original checkpoint -> exported ONNX parity passed on four inputs, including a fictional portrait aligned by the official CPU reference. See `edgeface-s-validation.json`.
- [x] Local EdgeFace-S ONNX -> Android CPU parity passed on Nord CE4, using test-only assets. The separate minified shipped-asset parity gate remains pending production approval.

No phone was attached when implementation began; the Nord CE4 was subsequently connected and passed the local device tests. An emulator can test Android correctness, but cannot establish lower-end physical-device performance or camera quality.

## 3. Asset and licence gate — before distributing an APK with weights

- [ ] Retain the exact official code licence and identify the checkpoint licence/redistribution terms.
- [ ] Retrieve WebFace training-data terms; record applicability and intended-use restrictions with evidence. Do not assume hackathon permission.
- [x] Pin source commit, checkpoint URL/hash and Python environment; run `ml/edgeface/export_model.py --help` for required inputs.
- [x] Run the S export into ignored `release-assets/edgeface-s/`; retain output manifest and numerical measurements. The exporter never downloads weights or invents substitutes.
- [ ] After licence verification, copy ONNX and completed manifest into `android/app/src/main/assets/ml/`; set redistribution approval only with documented evidence.
- [x] Copy generated `parity-input.f32` and `parity-embedding.f32` into test-only `android/app/src/androidTest/assets/edgeface/`. Never bundle test embeddings into the production app.
- [ ] Run the explicit `EdgeFaceModelParityTest` on a phone. It intentionally fails if model or fixtures are absent; absence is not a passing/skipped test.

The checked-in manifest is explicitly pending and contains no real hash. There is no production-bundled EdgeFace model yet. Local instrumentation assets contain S for engineering tests only. Production runtime failure is expected and must stay neutral.

## 4. Quality and threshold evaluation — joint work

- [ ] Export and benchmark both `edgeface_s_gamma_05` and `edgeface_xs_gamma_06` in separate output directories (`export_model.py --model ...`). Run parity first, then whole-pipeline cold/warm p95, memory and sustained-use tests on representative lower-end phones. Freeze the model choice before final held-out evaluation. Select S only if its development-set document-to-selfie benefit and device budget are demonstrated; otherwise select XS. Do not use either model's thresholds for the other. S is the selected first candidate; defer XS evaluation until S is measured.
- [ ] Collect explicitly consented document-photo-to-selfie samples with distinct development/test subjects. Include printed/grayscale portraits, glare, security patterns, age gaps and multiple phones.
- [ ] Compare ML Kit alignment with official reference alignment on those inputs. Record landmark failure rates, score shifts and verification outcomes.
- [ ] Evaluate the provisional document/selfie size, exposure, blur, pose and glare gates. The present values (80/112 source-pixel minimum, 20-degree yaw/pitch, 25-degree roll, central highlight fractions 0.08/0.15, luminance 35..225, Laplacian variance 20) are engineering starting points, **not calibrated limits**.
- [ ] Test occlusions explicitly; landmark availability is not an occlusion detector. Add a validated occlusion gate or document restricted capture conditions before approval.
- [ ] Freeze quality/aggregation/threshold policy on development data. Do not copy MobileFaceNet values.
- [ ] Evaluate once on held-out subjects; report each outcome including UNCERTAIN, denominators, distinct subjects and confidence intervals accounting for repeated subjects.
- [ ] Fill `edgeface_evaluation.json` only after the report and Android parity exist. No approved thresholds are supplied today.

## 5. Manual phone checklist — user supplies devices and consented captures

Run on at least two lower-end phones from different chipset families; record model, chipset, RAM, Android version and app/model hashes. One M21 is optional.

1. Install a release build; disable Wi-Fi/mobile data before first launch. Confirm no model download and that the rest of screening works when face comparison is unavailable.
2. With the validated asset/policy, compare a captured document portrait and a new frontal selfie. Confirm no bundled portrait is substituted. Check reason messages for missing document, no face, multiple faces, blur, glare, pose and small crop.
3. Test genuine and impostor pairs from the **held-out** protocol; do not tune thresholds to make a demo pass. Retake and skip remain available for uncertain/unavailable outcomes.
4. Run rotated/mirrored capture tests and the device preprocessing/parity tests. Confirm actual phone embeddings meet frozen tolerances.
5. Record startup, decode, detection, alignment, embedding and total durations separately. Run 20 comparisons, then repeat after five minutes; report p50/p95, memory and thermal conditions. Target <=2 seconds for one document plus up to three selfies; do not call this achieved until measured.
6. Benchmark CPU threads 1/2/4. Test XNNPACK separately only if added; CPU is the only implemented provider today. Keep the camera/UI responsive and check rotation/background/resume/cancellation.
7. Use a test build with a missing/corrupt model and another with an invalid hash/policy. Every failure must stay NOT_RUN with no score or green result.
8. Inspect logs, case exports and app cache: no raw embeddings or comparison crop files. Review the existing capture screen's temporary-photo lifecycle separately.

## Reproducible commands

From the repository root:

```text
python ml/edgeface/reference.py
python -m unittest discover -s ml/edgeface -p test_*.py
flutter pub get
flutter test
flutter analyze --no-fatal-infos
```

From `android/`, using JDK 21:

```text
gradlew.bat :app:testDebugUnitTest :app:assembleDebugAndroidTest :app:assembleRelease
gradlew.bat :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.sih188.borderdoc.face.FacePreprocessingTest
gradlew.bat :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.sih188.borderdoc.face.EdgeFaceModelParityTest
```

Passing a debug device test does not replace running a minified release build. The release remains blocked until all applicable asset, device, quality and threshold gates above have evidence.

### Workstation build note

JDK 21 on this Windows host required the process-local setting `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=D:/tmp` for Gradle local sockets. This is a host workaround, not an Android runtime setting. Kotlin incremental compilation also fell back to compilation without its daemon due to cross-drive cache paths.

### Final workstation verification — 2026-09-24

- Kotlin: 7 tests, zero failures/errors/skips, including independent Python tensor parity.
- Python: 4 reference tests passed.
- Flutter: 4 tests passed; analysis has no errors or warnings (13 API-deprecation info notices).
- Android: device-test APK and final minified release build succeeded. Seven local device tests subsequently passed; shipped-asset release parity remains pending.
- APK contents verified: ONNX native runtime and pending manifest present; old MobileFaceNet/reference assets and test embeddings absent.
- Release APK is unsigned and deliberately has no approved EdgeFace checkpoint or decision policy. Do not treat it as a functional recognition demo.
- Final APK SHA-256: `46cdf702c4ee5db50d12c84f918c73076075c27beb735b6e82371e107284dcca`.

## S-first setup session

- Selected S first; XS testing deferred at the user's request.
- Isolated Windows Python 3.10.19 CPU environment installed and imports verified; exact package versions recorded in `ml/edgeface/requirements-export-lock.txt`.
- Official checkpoint obtained from the pinned official GitHub commit. PyTorch -> ONNX numerical parity passed; the ONNX file is 14,776,267 bytes.
- Published model licence identified as CC BY-NC-SA 4.0, distinct from the inference repository BSD-3-Clause licence. Dataset terms and deployment approval remain pending.
- Local test APK can load test-only assets through an instrumentation-only factory guarded by DEBUG and the test package name. Production still enforces its approval gate; no release licence flag is falsified for testing.
- First physical phone: OnePlus Nord CE4 (CPH2613), Android 16. This is a functional/parity test, not lower-end performance qualification.

### Nord CE4 local device verification

- Seven instrumentation tests passed: EXIF orientations, alignment regressions, invalid landmarks, absent-document and unapproved-model failure handling, real S desktop/Android parity with 20 repeated inferences, and the bundled ML Kit/five-point path on a fictional portrait.
- Debug app and test APK installed as updates with `adb install -r -t`; no uninstall or app-data clearing was used.
- These initial tests used no personal face images. Subsequent user-authorized capture tests process photos locally on the phone. Recognition thresholds and release model approval remain pending.

- Metrics rerun: both S tests passed. Desktop/Android cosine 1.0, max normalized absolute error 2.31e-7; startup/hash/load/warm-up 875.9 ms. Warm embedding p50 46.8 ms / p95 125.9 ms over 20 runs. This excludes decoding/detection/alignment and does not establish the whole-pipeline or lower-end budget.
- ML Kit vs official MTCNN alignment cosine was 0.989545 on one fictional portrait. This is diagnostic only; real document/selfie alignment evaluation remains unchecked.

### Captured-pair diagnostic preparation — 2026-09-24

- [x] Added instrumentation-only `CapturedPairDiagnosticTest` with explicit app-cache paths, provisional quality rejection reasons, separate startup and pair-stage timings, and 20 warm repetitions. No identity score/verdict or raw embedding output.
- [x] Built and installed the updated test APK; fictional-portrait smoke check passed on Nord CE4 (`OK (1 test)`). This is test-harness validation, not real capture or recognition validation.
- [x] User captures a new document portrait and live face using [the first-capture instructions](edgeface-first-capture-test.md), then run the diagnostic on those two explicitly identified files.
- First real captured-pair attempt: document rejected with `document_NO_FACE`; selfie and repeated-pair timing not reached. Harness completion is not pair acceptance. Request a closer, evenly lit document portrait capture; keep provisional gates unchanged.

- Second real pair accepted by provisional quality gates: one face in each image; S embeddings produced. Twenty repeats: warm pair p50 1966.2 ms, p95 2133.9 ms. First pair 2412.5 ms plus separate startup 427.8 ms. The <=2 s p95 target is NOT met even for one live photo on this debug Nord CE4 run. No identity verdict or accuracy validation. First-run document detection 1590.7 ms and live detection 381.9 ms dominate; detector-input sizing is a candidate for measured optimization, with alignment/parity regression checks required.

### Detection-sizing and alignment optimization — 2026-09-24

- [x] Measured 1024, 1536 and 1920 maximum detection edges against full-resolution embeddings on the same captured pair. All failed the fixed >=0.98 document embedding agreement check (0.95242, 0.95176 and 0.95340). None is enabled in production; no threshold was relaxed.
- [x] Kept the sizing experiment in the explicit instrumentation harness for future evaluation; mapped detection coordinates and size gates to original pixels. Default detection remains full resolution.
- [x] Removed duplicate pixel reads/bounds checks across RGB channels in bilinear alignment and cached the fixed quality-region indices. Sampling arithmetic and quality limits stay the same.
- [x] Seven Kotlin unit tests (including independent reference tensor parity), seven physical-device regression tests, debug APK and minified release build passed after the alignment change. Device desktop/S cosine 1.0; fictional-portrait reference alignment cosine remains 0.98954505. Release contents still exclude model and test assets.
- Final captured-pair rerun passed (full-resolution detection): warm p50 1368.6 ms / p95 1788.3 ms over 20 repeats. First pair 2122.3 ms plus startup 1007.4 ms = 3129.7 ms. Warm target met for this one-pair debug Nord CE4 run only; cold target not met. Uncontrolled device conditions mean this is not an isolated causal estimate of the optimization benefit. Three-selfie, sustained-use, memory and lower-end checks remain pending.


### Startup timing clarification — 2026-09-24

The user accepts approximately three seconds for cold startup. Record cold startup separately; it is not subject to the two-second warm-processing target. Warm latency, sustained behaviour and memory still require measurement. This does not establish a new hard cold-start maximum.

### Next-stage scope — user clarification

Approximately three seconds cold startup is acceptable. The next engineering check is sustained use and sampled memory for one document plus three live-input processing passes. The same existing live photo may be repeated for workload testing only. The user has 3–5 volunteers available for an initial development pilot; see [the pilot plan](edgeface-volunteer-pilot.md). This is not enough to claim a low false-accept rate or approve thresholds.

### Sustained workload results — Nord CE4

- [x] Instrumentation update built and installed. Sustained test completed 119 comparisons (one document plus three processing passes of the same live image), 300 seconds continuous use plus final 20-run batch, without quality rejection or crash. Identity verdict remains NOT_RUN.
- Initial warm p50/p95: 2858.5 / 3194.3 ms. Final p50/p95: 3193.2 / 5856.1 ms. Three-live workload FAILS the two-second target; do not mark performance qualification complete.
- Sampled warm process PSS: 244.0–258.3 MiB; no monotonic growth visible during this run. This includes debug instrumentation and is not peak memory or proof of no leak. Thermal status codes varied between 1 and 2; the test does not isolate the cause of latency variation.
- Keep the existing one-live-photo UI as the baseline. Three-photo processing remains experimental. One-photo sustained latency, production camera/UI memory and representative lower-end testing remain unverified.
- Next priority: manual camera lifecycle/failure flow, then a consented 3–5-person development pilot with explicit session IDs and image-retention handling. No threshold approval from speed tests or this tiny pilot.

### User-reported camera checks — 2026-09-24

- [x] User reports background/Home -> return resumes live-camera preview, capture works, Retake works, and Skip face verification works. This is manual user verification on Nord CE4, not an automated camera-lifecycle test. Rotation and other device models remain unverified.

- [x] Added and installed a separate anonymous development-pair scorer; synthetic self-comparison smoke test passed on Nord CE4 (cosine 1.0, identityVerdict NOT_RUN). This checks tool wiring, not accuracy.
- [x] Added local session helper with one-active-session guard, before/after capture binding, explicit retake selection, ignored report storage and separate exact-two-file cleanup. Eight Python tests passed (four numerical reference tests plus four capture-selection safety tests). Cleanup on actual participant files remains unexercised.
- [ ] Begin consented P01 pilot session before new captures. No volunteer session has been started or inferred from earlier photos.

- [x] First consented same-person development pair evaluated with the user-confirmed latest live retake. Both inputs accepted by provisional quality gates; exploratory score stored only in the ignored local pilot report. No recognition verdict or threshold approval. Two unselected live retakes were not evaluated. Photo cleanup remains pending.

- [x] Second consented same-person development pair evaluated with user-confirmed document retake. Both inputs passed provisional quality checks; score retained in ignored local pilot report only. One earlier document retake was not evaluated. No threshold or identity verdict approved; cleanup remains pending.

- Third participant first attempt rejected: document_MULTIPLE_FACES. No similarity score produced; live-face inference was not reached. Failure retained in ignored pilot report; prepare a separate retake session rather than replacing it.


### Automatic main portrait location — 2026-09-25

- User rejected manual tap-selection. Removed that UI, selection state, channel arguments, sidecar storage and selection tests before installation. Full-document capture is retained for OCR.
- Added a narrow automatic passport adapter using bundled Latin OCR text labels and relative field/portrait geometry, only when the document has multiple detected faces. The secondary portrait may be larger; size/colour alone never selects a candidate. Unsupported or ambiguous layouts abstain. Live images still require one face.
- Added `documentPortraitVersion` binding to the unapproved evaluation policy and pilot reports. This is not complete OCR field extraction; the existing OCR result screen remains a stub.
- Nine Kotlin unit tests, four Flutter tests, eight Python tests and debug/instrumentation/minified-release builds passed. Release assets checked: no EdgeFace checkpoint or participant photos included. Device retest pending below.
