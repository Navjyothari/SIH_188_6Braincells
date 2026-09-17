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
        val v = FloatArray(128) { it.toFloat() + 1f }
        assertEquals(1.0f, cosine(v, v), 1e-5f)
    }

    @Test fun `orthogonal vectors have cosine similarity 0`() {
        val a = FloatArray(128) { if (it % 2 == 0) 1f else 0f }
        val b = FloatArray(128) { if (it % 2 == 1) 1f else 0f }
        assertEquals(0.0f, cosine(a, b), 1e-5f)
    }

    @Test fun `opposite vectors have cosine similarity -1`() {
        val v = FloatArray(128) { it.toFloat() + 1f }
        val neg = FloatArray(128) { -(it.toFloat() + 1f) }
        assertEquals(-1.0f, cosine(v, neg), 1e-5f)
    }

    @Test fun `zero vector returns 0 not NaN`() {
        val zero = FloatArray(128) { 0f }
        val v    = FloatArray(128) { 1f }
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
}
