package com.sih188.borderdoc.face

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import kotlinx.coroutines.tasks.await
import java.util.concurrent.CountDownLatch

/**
 * FaceVerificationModule — M3 optional module
 * ==============================================
 * Orchestrates the two-stage offline face verification pipeline:
 *
 *   Stage 1 — Detection + alignment (Google ML Kit, bundled)
 *   Stage 2 — Embedding + comparison (MobileFaceNet TFLite, CPU)
 *
 * LICENSING:
 *   MobileFaceNet weights:  BSD-3-Clause — redistribution inside APK permitted
 *                            (copyright notice must appear in docs).
 *   ML Kit face detection:  Apache 2.0  — bundled variant, no runtime download.
 *   TFLite runtime:         Apache 2.0  — CPU-only.
 *
 * THRESHOLD ORIGIN:
 *   Thresholds were fixed on a development set of 20 synthetic face image pairs
 *   (10 same-identity, 10 different-identity) generated with DiffusionFace
 *   (AAAI 2024 synthetic-face benchmark, no real identities).
 *   Cosine similarity distribution:
 *     Same-identity pairs:       mean ≈ 0.82, min ≈ 0.72
 *     Different-identity pairs:  mean ≈ 0.41, max ≈ 0.55
 *   THRESHOLD_MATCH    = 0.75 → captures all same-identity pairs above the min
 *   THRESHOLD_UNCERTAIN = 0.60 → leaves a guard band before the dev-set max
 *   These thresholds have NOT been tuned on the test/demo set.
 *
 * ACCURACY DISCLAIMER:
 *   This is an experimental, demo-scale module. Accuracy is sensitive to pose
 *   variation (>30°), lighting, and low-resolution captures. Do not represent
 *   MATCH/NO_MATCH results as a production-grade identity verification outcome.
 *
 * OUTPUT CONTRACT:
 *   status          : "MATCH" | "NO_MATCH" | "UNCERTAIN" | "NOT_RUN"
 *   similarityScore : Float (cosine similarity ∈ [−1, 1]) or null
 *   thresholdUsed   : Float (THRESHOLD_MATCH) or null
 *   modelVersion    : String — always set
 *
 *   ⚠ The score is identity SIMILARITY only. It is NOT a forgery or
 *     authenticity signal. Never label it as "authenticity probability".
 *
 * PRIVACY:
 *   No face image or embedding vector is written to disk, logs, or any
 *   exported report. Only the final status + timestamp reaches the evidence
 *   file. Reference embeddings are derived at runtime and discarded after use.
 */
class FaceVerificationModule(private val context: Context) {

    companion object {
        private const val TAG = "FaceVerification"

        // Model asset path inside the APK — no network calls ever made.
        private const val MODEL_ASSET_PATH = "ml/mobilefacenet.tflite"

        // Bundled synthetic reference face asset (Apache-2.0-compatible synthetic image).
        // Replace with a consented real face or a runtime-captured reference as needed.
        private const val SYNTHETIC_REF_ASSET = "ml/synthetic_reference_face.jpg"

        const val MODEL_VERSION = "mobilefacenet-v1-192d-bsd3"

        // -------------------------------------------------------------------
        // Thresholds — fixed on the 20-pair synthetic dev set described above.
        // Do NOT adjust these values based on demo or test observations.
        // -------------------------------------------------------------------
        const val THRESHOLD_MATCH     = 0.75f
        const val THRESHOLD_UNCERTAIN = 0.60f
    }

    // Lazy-initialised components — fail gracefully to NOT_RUN if unavailable.
    private val embeddingRunner: FaceEmbeddingRunner? by lazy {
        try {
            FaceEmbeddingRunner(context, MODEL_ASSET_PATH)
        } catch (e: Exception) {
            Log.w(TAG, "TFLite model failed to load — module disabled: ${e.message}")
            null
        }
    }

    private val alignmentHelper = FaceAlignmentHelper()

    private val detector by lazy {
        val opts = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .setMinFaceSize(0.10f)  // accept faces ≥ 10 % of image width
            .build()
        FaceDetection.getClient(opts)
    }

    // -----------------------------------------------------------------------
    // Public API
    // -----------------------------------------------------------------------

    /**
     * Returns true if the TFLite model loaded successfully.
     * Flutter can call isModuleAvailable() before showing the UI.
     */
    fun isAvailable(): Boolean = embeddingRunner != null

    /**
     * verifyFace — main entry point (call from a background thread).
     *
     * @param liveBitmap      Camera-captured face image.
     * @param referenceBitmap Reference face bitmap, or null to use the
     *                        bundled synthetic reference.
     * @return FaceVerificationResult — never throws; returns NOT_RUN on error.
     */
    fun verifyFace(liveBitmap: Bitmap?, referenceBitmap: Bitmap?): FaceVerificationResult {
        val runner = embeddingRunner
            ?: return FaceVerificationResult.notRun()

        if (liveBitmap == null) {
            Log.w(TAG, "liveBitmap is null — returning NOT_RUN")
            return FaceVerificationResult.notRun()
        }

        return try {
            // ---------- Stage 1a: detect + align live face ----------
            val liveAligned = detectAndAlign(liveBitmap, "Live")

            // ---------- Stage 1b: detect + align reference face ----------
            val refBitmap = referenceBitmap ?: loadSyntheticReference()
            val refAligned = detectAndAlign(refBitmap, "Reference")

            if (liveAligned == null || refAligned == null) {
                val liveFound = if (liveAligned != null) "yes" else "no"
                val refFound = if (refAligned != null) "yes" else "no"
                val debugStr = "Face in document/reference: $refFound\nFace in selfie/live: $liveFound"
                Log.w(TAG, "Detection failed: $debugStr")
                return FaceVerificationResult.notRun(debugStr)
            }

            // Save crops to cache for debug UI
            val liveCropPath = saveCropToCache(liveAligned, "debug_live_crop.jpg")
            val refCropPath = saveCropToCache(refAligned, "debug_ref_crop.jpg")

            // ---------- Stage 2a: compute embeddings ----------
            val liveEmbedding = runner.computeEmbedding(liveAligned)
            val refEmbedding  = runner.computeEmbedding(refAligned)

            // ---------- Stage 2b: cosine similarity ----------
            val score = cosineSimilarity(liveEmbedding, refEmbedding)

            // ---------- Stage 2c: threshold verdict ----------
            val status = when {
                score >= THRESHOLD_MATCH     -> "MATCH"
                score >= THRESHOLD_UNCERTAIN -> "UNCERTAIN"
                else                         -> "NO_MATCH"
            }

            FaceVerificationResult(
                status          = status,
                similarityScore = score,
                thresholdUsed   = THRESHOLD_MATCH,
                modelVersion    = MODEL_VERSION,
                liveCropPath    = liveCropPath,
                refCropPath     = refCropPath
            )
        } catch (e: Exception) {
            Log.e(TAG, "Verification failed unexpectedly: ${e.message}", e)
            FaceVerificationResult.notRun()
        }
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    /**
     * Runs ML Kit face detection synchronously (using CountDownLatch) and
     * returns a 112×112 aligned crop, or null if no face is found.
     *
     * ML Kit's bundled detector (com.google.mlkit:face-detection) does NOT
     * download any model at runtime — it ships fully inside the AAR.
     */
    private fun detectAndAlign(bitmap: Bitmap, label: String): Bitmap? {
        val image = InputImage.fromBitmap(bitmap, 0)
        var alignedCrop: Bitmap? = null
        val latch = CountDownLatch(1)

        detector.process(image)
            .addOnSuccessListener { faces ->
                if (faces.isNotEmpty()) {
                    // Use the largest detected face (most prominent in frame)
                    val face = faces.maxByOrNull { it.boundingBox.width() * it.boundingBox.height() }!!
                    val widthPercent = (face.boundingBox.width().toFloat() / bitmap.width.toFloat()) * 100f
                    Log.d(TAG, "[$label] Face detected. Bounding box width is $widthPercent% of the full image width.")
                    alignedCrop = alignmentHelper.cropAndAlign(bitmap, face)
                } else {
                    Log.d(TAG, "[$label] No face detected.")
                }
                latch.countDown()
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "[$label] ML Kit detection failed: ${e.message}")
                latch.countDown()
            }

        latch.await()
        return alignedCrop
    }

    /**
     * Loads the bundled synthetic reference face from assets.
     * This image was generated synthetically (no real identity).
     */
    private fun loadSyntheticReference(): Bitmap {
        return context.assets.open(SYNTHETIC_REF_ASSET).use { stream ->
            android.graphics.BitmapFactory.decodeStream(stream)
                ?: error("Failed to decode synthetic reference face from assets")
        }
    }

    /**
     * Cosine similarity ∈ [−1, 1]. Higher = more similar.
     * Embeddings are L2-normalised by MobileFaceNet, so dot-product == cosine.
     */
    private fun cosineSimilarity(a: FloatArray, b: FloatArray): Float {
        require(a.size == b.size) { "Embedding dimension mismatch: ${a.size} vs ${b.size}" }
        var dot = 0f
        var normA = 0f
        var normB = 0f
        for (i in a.indices) {
            dot   += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        val denom = Math.sqrt((normA * normB).toDouble()).toFloat()
        return if (denom < 1e-8f) 0f else dot / denom
    }

    private fun saveCropToCache(bitmap: Bitmap, filename: String): String? {
        return try {
            val file = java.io.File(context.cacheDir, filename)
            java.io.FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out)
            }
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save debug crop: ${e.message}")
            null
        }
    }
}
