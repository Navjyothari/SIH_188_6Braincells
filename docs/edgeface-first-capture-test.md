# First captured-pair test (S)

## On the phone

1. Open BorderDoc. If on the results screen, choose **New Screening**.
2. Photograph your own printed portrait or the portrait area of your own ID, with unrelated personal fields covered. Use even light and avoid glare. A printed photo is sufficient for this initial capture check; it does not substitute for later document-condition evaluation.
3. Tap **Confirm & continue to selfie**.
4. The live-face screen currently uses the rear camera. Ask someone to take a straight-on photo of you, with your face inside the oval, then tap **Confirm & verify face**.
5. Leave the results screen open and tell the assistant **captured**. Keep debugging connected. A neutral **NOT RUN** is expected because production approvals remain pending.

No photo upload is needed. The assistant will identify only the new app-cache captures by their filenames/timestamps and run the test on the phone. If retakes leave ambiguous files, clarify which capture to use before measuring. No image inspection or copying to the computer is needed for timing and quality tests.

## What the engineering test does

`CapturedPairDiagnosticTest` requires explicit document and selfie paths inside this app's cache and uses S from the instrumentation APK. It runs the existing decoder, ML Kit detector, five-point alignment, provisional quality gates and embedding implementation. It reports the first pair's stage timings and 20 repeated pair-processing durations. Startup/hash/load/warm-up is reported separately. No identity score, threshold or match verdict is produced; embeddings are kept in memory only.

A capture rejected by the quality gates is recorded as RECAPTURE with a role-specific reason, not as successful inference. Other exceptions fail the test. Capture time, UI responsiveness, memory peaks, sustained thermal behaviour and lower-end hardware qualification are separate checks. This harness exercises the component pipeline, not the production method-channel/decision-policy path.

## Assistant commands

Build/install the instrumentation APK, then run the fictional-portrait smoke check first:

```text
adb -s DEVICE shell am instrument -w -r -e class com.sih188.borderdoc.face.CapturedPairDiagnosticTest -e synthetic true com.sih188.borderdoc.test/androidx.test.runner.AndroidJUnitRunner
```

After the user has captured the pair, provide the two verified app-cache paths:

```text
adb -s DEVICE shell am instrument -w -r -e class com.sih188.borderdoc.face.CapturedPairDiagnosticTest -e document DOCUMENT_PATH -e selfie SELFIE_PATH com.sih188.borderdoc.test/androidx.test.runner.AndroidJUnitRunner
```

Record the aggregate report and provisional quality outcome without copying photos, paths or embeddings into version control. Do not infer recognition accuracy or tune thresholds from this single pair.

## Detector sizing experiment

Optional instrumentation argument `-e maxEdge N` downsizes only detection, maps landmarks and face-size checks back to original coordinates, and keeps alignment pixels at original resolution. The harness first computes a full-resolution reference embedding per capture, then requires cosine >=0.98 for every candidate embedding. This alignment-stability tolerance is separate from the stricter same-input desktop/Android numerical parity test. Production does not enable downscaling: 1024, 1536 and 1920 all failed the document alignment comparison on the first captured pair tested. Do not loosen the tolerance based on this single pair.

## Sustained workload test

`CapturedPairDiagnosticTest` accepts `-e liveCopies 3 -e sustainSeconds 300`. It processes the document once and independently decodes/detects/aligns/embeds the same live capture three times per iteration. This is a workload proxy; it does not establish the accuracy benefit of three independent photos or include camera/UI time. It runs an initial 20-iteration batch, continues until five minutes have elapsed, then runs another 20-iteration batch.

Memory samples are taken outside timed iterations (every five batch iterations / ten sustained iterations). Reports include total process PSS, allocated native/Java heap and Android's thermal status. Sampled PSS includes the debug instrumentation process and does not establish peak memory or absence of leaks. Model close does not imply all runtime/ML Kit caches or allocator arenas are returned to the OS. Raw images/embeddings remain on the phone/in memory, respectively.
