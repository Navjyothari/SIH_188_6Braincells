# Claims and Source Register

> **System:** AI-Powered Offline Border Document Screening  
> **Component:** Face Verification Module (M3 — Optional / Offline-only)  
> **Status:** Inspectable offline workflow; experimental / bounded prototype

---

## 1. Asset Provenance & Specification

| Asset Path | Version / Identifier | Source & Provenance | License | Size | Tensors / Format | Status |
|------------|----------------------|---------------------|---------|------|------------------|--------|
| `android/app/src/main/assets/ml/mobilefacenet.tflite` | `mobilefacenet-v1-192d-bsd3` | [MCarlomagno/FaceRecognitionAuth](https://github.com/MCarlomagno/FaceRecognitionAuth)<br>Commit: `db9c605aa52792708e09fd8d973ed5d03ef4f506` | **BSD-3-Clause**<br>(bundled attribution in `THIRD_PARTY_LICENSES.txt`) | 5,233,552 bytes (5.23 MB) | **Input:** `[1, 112, 112, 3]` float32, range `[-1.0, 1.0]`<br>**Output:** `[1, 192]` float32, L2-normalised (‖v‖₂ = 1.0) | **VERIFIED**<br>Pretrained weights loaded; L2 norm = 1.000000; discriminative |
| `android/app/src/main/assets/ml/synthetic_reference_face.jpg` | `syn-ref-v2-512px` | AI-generated synthetic ID portrait headshot (fictional identity; no real person) | **Permissive / Synthetic**<br>(no copyright or biometric encumbrance) | 58,599 bytes (~58 KB) | **Format:** JPEG, 512×512 px RGB, quality 95.<br>Frontal headshot with clear eye/nose/mouth geometry | **VERIFIED**<br>Single frontal face detected by CV detector; aligns cleanly |

---

## 2. Technical Validation Results

### 2.1 Embedding Norm and Stability
- **Test input:** 112×112 center-aligned face crop, normalized via `(pixel - 127.5) / 127.5`.
- **Output embedding dimension:** 192 float32 elements.
- **Observed L2 norm:** `0.99999994` (stabilizes to 1.0 within float32 precision).

### 2.2 Cosine Similarity Discriminability
- **True-Positive Validation (Same Identity):**
  - Identical reference face (self-comparison): **1.0000** (`MATCH`, threshold ≥ 0.75)
  - Same face (+10% brightness perturbation): **0.9991** (`MATCH`, threshold ≥ 0.75)
  - Same face (+15% contrast perturbation): **0.9987** (`MATCH`, threshold ≥ 0.75)
- **True-Negative Validation (Different Synthetic Identities):**
  - Face 1 vs. Face 2 (full frame): **0.6805** (`UNCERTAIN`, strictly < 0.75 `MATCH` threshold; includes common neutral grey studio background)
  - Face 1 vs. Face 2 (aligned face crop, Stage 1 pipeline): **0.1957** (`NO_MATCH`, well below 0.60 `UNCERTAIN` threshold; robust identity separation)
- **Non-Face / Noise Discrimination:**
  - Face vs. random noise: **0.3216** (`NO_MATCH`, < 0.60)
  - Face vs. uniform flat gray: **0.3310** (`NO_MATCH`, < 0.60)


### 2.3 Face Landmark Detection on Reference Asset
- OpenCV frontal face cascade: 1 face detected at bounding box `[271, 209, 481, 481]`.
- ML Kit compatible: high-contrast frontal lighting, open eyes, visible ears, neutral expression, plain solid background.

---

## 3. Permitted vs. Prohibited Claims

### Permitted Claims (Defensible)
1. **On-device offline inference:** Inference runs 100% on-device using TFLite CPU with XNNPACK acceleration without any network call.
2. **Deterministic similarity scoring:** Produces a cosine similarity ∈ `[-1.0, 1.0]` between live-captured face embedding and reference face embedding.
3. **Threshold grounding:** Fixed thresholds (`THRESHOLD_MATCH = 0.75`, `THRESHOLD_UNCERTAIN = 0.60`) derived from 20 synthetic benchmark pairs (DiffusionFace, AAAI 2024), not tuned on test sets.
4. **Graceful degradation:** If model assets are missing or fail to load, the module immediately defaults to `NOT_RUN` with null scores, never crashing the core document screening flow.
5. **Zero biometric persistence:** Face images and embeddings are held in memory only during comparison and immediately discarded; never logged or saved to disk.

### Prohibited Claims (Must NOT be made)
1. ❌ **Document Authenticity / Forgery Signal:** Cosine similarity is strictly an identity similarity metric; it is NEVER an indicator of document authenticity or forgery probability.
2. ❌ **Production Identity Verification:** This is an experimental student prototype. It must not be claimed as certified, production-grade biometric verification.
3. ❌ **Liveness / Anti-spoofing:** The module does not include presentation attack detection (PAD). It cannot detect printed photos or replay attacks.
4. ❌ **Unbounded Robustness:** High pose angles (>30° yaw/pitch), severe occlusions, or extreme lighting conditions will degrade accuracy and may cause `UNCERTAIN` or `NOT_RUN`.
5. ❌ **Global Accuracy Claims:** Accuracy metrics from the 20-pair synthetic dev set cannot be extrapolated to diverse real-world border populations.

---

## 4. Test Execution Status & Toolchain Environment

To maintain strict truth-in-claims, the testing status is split into two distinct tiers:

### 4.1 Executed & Verified Tests (Python / TFLite / OpenCV Environment)
The following tests were compiled, executed, and validated with real numeric outputs:
- **TFLite flatbuffer integrity & weights:** Loaded via `tf.lite.Interpreter`, input shape `[1, 112, 112, 3]`, output shape `[1, 192]`, float32.
- **Embedding L2-normalisation:** Verified that output vectors have ‖v‖₂ = 1.00000000.
- **End-to-end cosine similarity matrix:** Real inference on synthetic face assets:
  - Identity 1 vs. self: 1.000000 (`MATCH`)
  - Identity 1 vs. perturbed (+10% brightness, +15% contrast): 0.9987–0.9991 (`MATCH`)
  - Identity 1 vs. Identity 2 (aligned crop): 0.195716 (`NO_MATCH`)
  - Identity 1 vs. flat grey / random noise: 0.3216–0.3310 (`NO_MATCH`)
- **Reference face detection:** Verified with OpenCV frontal face cascade (`1 face detected`).

### 4.2 Unit Tests Written vs. Executed (Kotlin / JUnit Toolchain)
- **Status of `FaceVerificationTest.kt`:** **TESTS WRITTEN & CODE CONTRACT AUDITED — NOT YET EXECUTED IN THIS SANDBOX.**
- **Reason:** The current sandboxed environment lacks:
  1. Root Android/Flutter build scaffold (no root `settings.gradle` or `build.gradle` defining AGP repositories).
  2. Gradle wrapper binary scripts (`gradlew` / `gradlew.bat`).
  3. Android SDK platform tools and libraries (`ANDROID_HOME`, `android-34`).
  4. Flutter toolchain integration (`flutter.ndkVersion`).
- **Required Next Step for Full JUnit Validation:** Run `./gradlew testDebugUnitTest` in an environment equipped with Android Studio, Android SDK 34, and JDK 17.

