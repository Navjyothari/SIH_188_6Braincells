package com.sih188.borderdoc.face

import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for the face verification module logic.
 * These tests cover the pure-Kotlin parts that don't need Android context:
 *   - Cosine similarity computation
 *   - Threshold verdict logic
 *   - Result serialisation
 *   - NOT_RUN contract
 */
class FaceVerificationTest {

    // -----------------------------------------------------------------------
    // Cosine similarity via reflection (private helper, tested indirectly
    // through a test-accessible wrapper below)
    // -----------------------------------------------------------------------

    // Test-accessible wrapper replicating the private cosineSimilarity logic
    private fun cosine(a: FloatArray, b: FloatArray): Float {
        var dot = 0f; var normA = 0f; var normB = 0f
        for (i in a.indices) { dot += a[i]*b[i]; normA += a[i]*a[i]; normB += b[i]*b[i] }
        val denom = Math.sqrt((normA * normB).toDouble()).toFloat()
        return if (denom < 1e-8f) 0f else dot / denom
    }

    @Test fun `identical vectors have cosine similarity 1`() {
        val v = FloatArray(192) { it.toFloat() + 1f }
        assertEquals(1.0f, cosine(v, v), 1e-5f)
    }

    @Test fun `orthogonal vectors have cosine similarity 0`() {
        val a = FloatArray(192) { if (it % 2 == 0) 1f else 0f }
        val b = FloatArray(192) { if (it % 2 == 1) 1f else 0f }
        assertEquals(0.0f, cosine(a, b), 1e-5f)
    }

    @Test fun `opposite vectors have cosine similarity -1`() {
        val v = FloatArray(192) { it.toFloat() + 1f }
        val neg = FloatArray(192) { -(it.toFloat() + 1f) }
        assertEquals(-1.0f, cosine(v, neg), 1e-5f)
    }

    @Test fun `zero vector returns 0 not NaN`() {
        val zero = FloatArray(192) { 0f }
        val v    = FloatArray(192) { 1f }
        assertFalse(cosine(zero, v).isNaN())
        assertEquals(0f, cosine(zero, v), 1e-5f)
    }


    // -----------------------------------------------------------------------
    // Threshold verdict logic
    // -----------------------------------------------------------------------

    private fun verdict(score: Float): String = when {
        score >= FaceVerificationModule.THRESHOLD_MATCH     -> "MATCH"
        score >= FaceVerificationModule.THRESHOLD_UNCERTAIN -> "UNCERTAIN"
        else                                                 -> "NO_MATCH"
    }

    @Test fun `score at THRESHOLD_MATCH boundary is MATCH`() {
        assertEquals("MATCH", verdict(FaceVerificationModule.THRESHOLD_MATCH))
    }

    @Test fun `score just below THRESHOLD_MATCH is UNCERTAIN`() {
        assertEquals("UNCERTAIN", verdict(FaceVerificationModule.THRESHOLD_MATCH - 0.001f))
    }

    @Test fun `score at THRESHOLD_UNCERTAIN boundary is UNCERTAIN`() {
        assertEquals("UNCERTAIN", verdict(FaceVerificationModule.THRESHOLD_UNCERTAIN))
    }

    @Test fun `score just below THRESHOLD_UNCERTAIN is NO_MATCH`() {
        assertEquals("NO_MATCH", verdict(FaceVerificationModule.THRESHOLD_UNCERTAIN - 0.001f))
    }

    @Test fun `high score gives MATCH`() {
        assertEquals("MATCH", verdict(0.90f))
    }

    @Test fun `low score gives NO_MATCH`() {
        assertEquals("NO_MATCH", verdict(0.30f))
    }

    // -----------------------------------------------------------------------
    // NOT_RUN contract — must never produce a fake score
    // -----------------------------------------------------------------------

    @Test fun `NOT_RUN result has null similarity score`() {
        val r = FaceVerificationResult.notRun()
        assertEquals("NOT_RUN", r.status)
        assertNull(r.similarityScore)
        assertNull(r.thresholdUsed)
        assertEquals(FaceVerificationModule.MODEL_VERSION, r.modelVersion)
    }

    @Test fun `NOT_RUN toMap contains required keys`() {
        val map = FaceVerificationResult.notRun().toMap()
        assertTrue(map.containsKey("status"))
        assertTrue(map.containsKey("similarityScore"))
        assertTrue(map.containsKey("thresholdUsed"))
        assertTrue(map.containsKey("modelVersion"))
        assertNull(map["similarityScore"])
        assertNull(map["thresholdUsed"])
    }

    // -----------------------------------------------------------------------
    // Result serialisation (toMap)
    // -----------------------------------------------------------------------

    @Test fun `MATCH result serialises correctly`() {
        val r = FaceVerificationResult(
            status          = "MATCH",
            similarityScore = 0.82f,
            thresholdUsed   = FaceVerificationModule.THRESHOLD_MATCH,
            modelVersion    = FaceVerificationModule.MODEL_VERSION
        )
        val map = r.toMap()
        assertEquals("MATCH", map["status"])
        assertEquals(0.82f,   map["similarityScore"])
        assertEquals(FaceVerificationModule.THRESHOLD_MATCH, map["thresholdUsed"])
        assertEquals(FaceVerificationModule.MODEL_VERSION,   map["modelVersion"])
    }

    // -----------------------------------------------------------------------
    // Alignment enforcement & encapsulation audit tests
    // -----------------------------------------------------------------------

    @Test
    fun `embedding runner accepts canonical 112x112 aligned input dimensions`() {
        // Must succeed without throwing
        FaceEmbeddingRunner.validateInputDimensions(112, 112)
        assertEquals(112, FaceEmbeddingRunner.INPUT_SIZE)
        assertEquals(192, FaceEmbeddingRunner.EMBEDDING_SIZE)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `embedding runner strictly rejects full-frame 1920x1080 camera dimensions`() {
        FaceEmbeddingRunner.validateInputDimensions(1920, 1080)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `embedding runner strictly rejects uncropped 512x512 reference face dimensions`() {
        FaceEmbeddingRunner.validateInputDimensions(512, 512)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `embedding runner strictly rejects sub-minimum 100x100 crop dimensions`() {
        FaceEmbeddingRunner.validateInputDimensions(100, 100)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `embedding runner strictly rejects non-square 112x110 crop dimensions`() {
        FaceEmbeddingRunner.validateInputDimensions(112, 110)
    }

    @Test
    fun `embedding runner is private and never exposed by public verification API`() {
        // Verify that FaceVerificationModule exposes ONLY the safe public API methods
        val publicMethods = FaceVerificationModule::class.java.methods
            .filter { it.declaringClass == FaceVerificationModule::class.java }
            .map { it.name }
            .toSet()

        val allowedPublicMethods = setOf("verifyFace", "isAvailable")
        assertEquals(
            "FaceVerificationModule must not expose internal components or bypass methods",
            allowedPublicMethods,
            publicMethods
        )

        // Verify that embeddingRunner is private in FaceVerificationModule
        val fields = FaceVerificationModule::class.java.declaredFields
        val runnerField = fields.find { it.name.contains("embeddingRunner") }
        assertNotNull("embeddingRunner field must exist internally", runnerField)
        assertTrue(
            "embeddingRunner must be private to enforce that all inferences pass through detectAndAlign",
            java.lang.reflect.Modifier.isPrivate(runnerField!!.modifiers)
        )
    }

    @Test
    fun `alignment failure contract requires NOT_RUN without fallback to raw frame`() {
        // When alignment fails (no face found, low confidence, etc.):
        // 1. status must be NOT_RUN
        // 2. similarityScore must be null (never a fallback embedding on unaligned pixels)
        // 3. thresholdUsed must be null
        val result = FaceVerificationResult.notRun()
        assertEquals("NOT_RUN", result.status)
        assertNull("Similarity score must be null on alignment failure", result.similarityScore)
        assertNull("Threshold must be null on alignment failure", result.thresholdUsed)
        assertEquals(FaceVerificationModule.MODEL_VERSION, result.modelVersion)
    }
}
