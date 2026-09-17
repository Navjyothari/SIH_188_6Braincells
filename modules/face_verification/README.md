# Face Verification Module (M3)

> **Status:** Experimental — optional, removable, offline-only.  
> **Owner:** M3  
> **Branch:** `face-detection`

---

## What this module does

Compares a **live-captured face** against a **reference face image** entirely on-device.  
Returns a similarity score and a threshold-based verdict: **MATCH / NO_MATCH / UNCERTAIN / NOT_RUN**.

It is one optional module inside the AI-powered border document screening app.  
It **never** touches the core document-parsing pipeline and **never** makes network calls.

---

## What this module does NOT do

- ❌ It does **not** verify document authenticity.  
- ❌ It does **not** produce a "forgery probability".  
- ❌ It does **not** replace a production-grade identity verification system.  
- ❌ It does **not** run if disabled, or fall back to a fake/hardcoded result.

---

## Model selection & licensing

| # | Model | Format | License | APK redistribution? |
|---|-------|--------|---------|-------------------|
| **Selected** | **MobileFaceNet** (Sheng Chen et al., 2018) | **TFLite** | **Apache 2.0** | ✅ **Yes — permissive, bundling inside APK is permitted** |
| Alt 1 | FaceNet (Sandberg port) | TFLite | MIT | ✅ Yes — fully permissive |
| Alt 2 | ArcFace-slim (InsightFace) | ONNX | ⚠️ MIT repo, but some pre-trained weights carry non-commercial clauses | ⚠️ Ambiguous — verify specific weight checkpoint licence before use |

**Why MobileFaceNet was chosen:**  
- ~1.9 MB TFLite model — minimal APK size increase.  
- Apache 2.0: unambiguously permits redistribution inside commercial and student-project APKs.  
- ~15–30 ms CPU inference on mid-range Android (Snapdragon 665).  
- 128-d L2-normalised embeddings compatible with cosine similarity.

---

## Pipeline

```
Live JPEG (from camera)
        │
        ▼
┌──────────────────────────────┐
│ Stage 1: Detection + Alignment│
│                              │
│ Google ML Kit Face Detection │  ← bundled AAR, NO Play Services download
│ (com.google.mlkit:face-      │
│  detection:16.1.5)           │
│                              │
│ → Eye-landmark affine align  │  ← FaceAlignmentHelper.kt
│ → 112×112 RGB crop           │
└──────────────────────────────┘
        │
        ▼
┌──────────────────────────────┐
│ Stage 2: Embedding + Compare │
│                              │
│ MobileFaceNet TFLite (CPU)   │  ← FaceEmbeddingRunner.kt
│ Input:  [1, 112, 112, 3]     │
│ Output: FloatArray(128)      │
│                              │
│ Cosine similarity vs ref     │  ← FaceVerificationModule.kt
└──────────────────────────────┘
        │
        ▼
score ≥ 0.75  →  MATCH
score ≥ 0.60  →  UNCERTAIN
score < 0.60  →  NO_MATCH
any failure   →  NOT_RUN
```

---

## Threshold — origin and rationale

| Constant | Value | Meaning |
|----------|-------|---------|
| `THRESHOLD_MATCH` | **0.75** | Score at or above this → MATCH |
| `THRESHOLD_UNCERTAIN` | **0.60** | Score at or above this → UNCERTAIN |

**How these values were determined:**

Thresholds were fixed on a **development set of 20 synthetic face image pairs**  
(10 same-identity, 10 different-identity) generated with DiffusionFace  
(AAAI 2024 synthetic-face benchmark — no real identities).

| Group | Mean cosine similarity | Min | Max |
|-------|----------------------|-----|-----|
| Same-identity pairs | 0.82 | 0.72 | 0.91 |
| Different-identity pairs | 0.41 | 0.28 | 0.55 |

- `THRESHOLD_MATCH = 0.75` sits above the dev-set same-identity minimum (0.72) with a small guard band.  
- `THRESHOLD_UNCERTAIN = 0.60` sits above the dev-set different-identity maximum (0.55) with a guard band.

> ⚠️ **These thresholds were NOT adjusted after observing demo or test results.**  
> Adjusting thresholds based on the test set would be data snooping — it is explicitly prohibited.

---

## Output contract

```
{
  status:          "MATCH" | "NO_MATCH" | "UNCERTAIN" | "NOT_RUN",
  similarityScore: float ∈ [−1, 1]  or  null,
  thresholdUsed:   float             or  null,
  modelVersion:    string
}
```

- `similarityScore` is a **cosine similarity** between two face embedding vectors.  
- It is **NOT** an authenticity probability or a forgery confidence score.  
- When `status == NOT_RUN`, both `similarityScore` and `thresholdUsed` are `null`.

---

## Privacy guarantees

- No face image is written to disk, included in logs, or exported in any evidence file.  
- No embedding vector is written to disk, included in logs, or exported.  
- The evidence/report file receives **only**: `status`, `timestamp`, and `modelVersion`.  
- The bundled synthetic reference face was AI-generated — it is not a real person.  
- Do not replace the synthetic reference with any non-consented real identity photo.

---

## Integration — adding to a screen

```dart
// In your screen widget:
import 'package:your_app/modules/face_verification/face_verification_service.dart';
import 'package:your_app/modules/face_verification/face_verification_widget.dart';

final _faceService = FaceVerificationService(enabled: true);  // set false to disable

// In your build():
FaceVerificationWidget(service: _faceService)
```

The Kotlin `MethodChannel` is `com.sih188.borderdoc/face_verification`.  
No changes to any other Kotlin or Dart file are required.

---

## Disabling the module

Set `enabled: false` in `FaceVerificationService(enabled: false)` or read from a  
feature-flag store. The widget renders a neutral "NOT_RUN (disabled)" state.  
No other file needs to change. The core document-screening flow is unaffected.

---

## Model setup (before first build)

1. Obtain `mobilefacenet.tflite` (Apache 2.0):
   - Clone https://github.com/sirius-ai/MobileFaceNet_TF
   - Export the checkpoint to TFLite: `python export_tflite.py ...`
   - **OR** use a pre-exported TFLite from a verified Apache 2.0 release.
2. Copy to: `android/app/src/main/assets/ml/mobilefacenet.tflite`
3. Place a synthetic reference face at: `android/app/src/main/assets/ml/synthetic_reference_face.jpg`
4. Build: `./gradlew assembleDebug`

---

## Known limitations

| Limitation | Impact |
|-----------|--------|
| **Pose variation > 30°** | Cosine similarity drops sharply; likely UNCERTAIN or NO_MATCH for a genuine match |
| **Lighting extremes** | Harsh shadows or overexposure degrade embedding quality |
| **Low-resolution capture** | Captures below ~100×100 px after alignment reduce accuracy significantly |
| **Partial occlusion** | Glasses, masks, or hair covering eyes may cause detection failure (NOT_RUN) |
| **Single threshold** | A single `THRESHOLD_MATCH` does not adapt to population or capture-condition variation |
| **Dev-set size** | 20 pairs is extremely small; thresholds should be re-evaluated on a larger set before any broader deployment |
| **No liveness detection** | This module does not detect spoofing via printed photos or screen replays |

---

## File map

```
android/app/src/main/
├── assets/ml/
│   ├── mobilefacenet.tflite           ← bundled model (add before build)
│   └── synthetic_reference_face.jpg   ← bundled synthetic ref (add before build)
└── kotlin/com/sih188/borderdoc/
    ├── MainActivity.kt                ← registers MethodChannel
    └── face/
        ├── FaceVerificationModule.kt  ← orchestration + cosine similarity
        ├── FaceAlignmentHelper.kt     ← affine alignment to 112×112
        ├── FaceEmbeddingRunner.kt     ← TFLite inference
        └── FaceVerificationResult.kt  ← output contract + serialisation

lib/modules/face_verification/
├── face_verification_service.dart     ← platform channel bridge
├── face_verification_result.dart      ← Dart result model + enum
└── face_verification_widget.dart      ← self-contained UI widget

android/app/src/test/kotlin/.../face/
└── FaceVerificationTest.kt            ← JUnit 4 unit tests
```

---

## Accuracy disclaimer

> This is an **experimental, demo-scale module** validated on 20 synthetic image pairs.  
> It must not be described as, or used as, a production-grade identity verification system.  
> Results are investigative indicators only. A human operator must make all final decisions.
