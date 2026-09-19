package com.sih188.borderdoc.face

/**
 * FaceVerificationResult — output contract for the M3 face verification module.
 *
 * OUTPUT CONTRACT (matches Flutter FaceVerificationResult Dart class):
 * ┌─────────────────────────────────────────────────────────────────┐
 * │  status          : "MATCH" | "NO_MATCH" | "UNCERTAIN" | "NOT_RUN" │
 * │  similarityScore : Float ∈ [−1, 1]  or null if NOT_RUN          │
 * │  thresholdUsed   : Float            or null if NOT_RUN           │
 * │  modelVersion    : String           always present               │
 * └─────────────────────────────────────────────────────────────────┘
 *
 * IMPORTANT — score semantics:
 *   similarityScore is a cosine SIMILARITY between two face embeddings.
 *   It is NOT a forgery probability, an authenticity score, or a
 *   confidence that the document is genuine. It only indicates how
 *   similar the two captured faces are according to MobileFaceNet.
 *
 * PRIVACY:
 *   No face image or embedding vector is present in this result.
 *   Only status + score + metadata reach the evidence file.
 */
data class FaceVerificationResult(
    val status:          String,        // "MATCH" | "NO_MATCH" | "UNCERTAIN" | "NOT_RUN"
    val similarityScore: Float?,        // null when status == NOT_RUN
    val thresholdUsed:   Float?,        // null when status == NOT_RUN
    val modelVersion:    String,
    val debugInfo:       String? = null,
    val liveCropPath:    String? = null,
    val refCropPath:     String? = null
) {
    companion object {
        /**
         * Returns a NOT_RUN result — used whenever the module is disabled,
         * fails to load, no face is detected, or consent conditions aren't met.
         * NEVER returns a fake score or a hardcoded verdict.
         */
        fun notRun(debugInfo: String? = null): FaceVerificationResult = FaceVerificationResult(
            status          = "NOT_RUN",
            similarityScore = null,
            thresholdUsed   = null,
            modelVersion    = FaceVerificationModule.MODEL_VERSION,
            debugInfo       = debugInfo
        )
    }

    /**
     * Serialises this result to a Map<String, Any?> that Flutter's
     * MethodChannel can decode without a custom codec.
     */
    fun toMap(): Map<String, Any?> = mapOf(
        "status"          to status,
        "similarityScore" to similarityScore,
        "thresholdUsed"   to thresholdUsed,
        "modelVersion"    to modelVersion,
        "debugInfo"       to debugInfo,
        "liveCropPath"    to liveCropPath,
        "refCropPath"     to refCropPath
    )
}
