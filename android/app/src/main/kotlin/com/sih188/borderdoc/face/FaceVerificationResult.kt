package com.sih188.borderdoc.face

/** Only scores and versioned metadata cross the platform channel. */
data class FaceVerificationResult(
    val status: String,
    val similarityScore: Float? = null,
    val thresholdUsed: Float? = null,
    val modelVersion: String = FaceVerificationModule.MODEL_VERSION,
    val reasonCode: String = "UNAVAILABLE",
    val thresholdVersion: String? = null,
    val timingMs: Map<String, Long> = emptyMap()
) {
    companion object {
        fun notRun(reason: String = "UNAVAILABLE") = FaceVerificationResult("NOT_RUN", reasonCode=reason)
    }
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to status, "similarityScore" to similarityScore,
        "thresholdUsed" to thresholdUsed, "modelVersion" to modelVersion,
        "reasonCode" to reasonCode, "thresholdVersion" to thresholdVersion,
        "detectorVersion" to "mlkit-bundled-16.1.5",
        "alignmentVersion" to EdgeFaceMath.ALIGNMENT_VERSION,
        "qualityVersion" to FaceQualityGate.VERSION, "timingMs" to timingMs
    )
}
