package com.sih188.borderdoc.face

import org.junit.Assert.*
import org.junit.Test

class FaceVerificationTest {
    @Test fun cosineNormalizesAndRejectsInvalidVectors() {
        assertEquals(1f,EdgeFaceMath.cosine(floatArrayOf(2f,4f),floatArrayOf(1f,2f)),1e-6f)
        assertEquals(0f,EdgeFaceMath.cosine(floatArrayOf(1f,0f),floatArrayOf(0f,2f)),1e-6f)
        for (bad in listOf(floatArrayOf(0f,0f),floatArrayOf(Float.NaN,1f),floatArrayOf(Float.POSITIVE_INFINITY,1f))) {
            assertThrows(IllegalArgumentException::class.java) { EdgeFaceMath.cosine(bad,floatArrayOf(1f,2f)) }
        }
    }
    @Test fun thresholdsRequireApprovalAndExactModelAndAlignment() {
        val policy=DecisionPolicy("hash",EdgeFaceMath.ALIGNMENT_VERSION,"test-only",0.2f,0.8f,true)
        assertEquals("MATCH",policy.classify(0.8f,"hash"))
        assertEquals("UNCERTAIN",policy.classify(0.2f,"hash"))
        assertEquals("NO_MATCH",policy.classify(0.19f,"hash"))
        assertThrows(IllegalArgumentException::class.java) { policy.classify(Float.NaN,"hash") }
        assertThrows(IllegalArgumentException::class.java) { policy.classify(1f,"different") }
        assertThrows(IllegalArgumentException::class.java) { policy.copy(approved=false).classify(1f,"hash") }
        assertThrows(IllegalArgumentException::class.java) { policy.copy(match=0.1f).classify(1f,"hash") }
        assertThrows(IllegalArgumentException::class.java) { policy.copy(alignment="old").classify(1f,"hash") }
    }
    @Test fun transformRecoversScaleRotationTranslationFromAllFivePoints() {
        val target=EdgeFaceMath.template
        val source=DoubleArray(10)
        for(i in 0..4) { val x=target[2*i]; val y=target[2*i+1]; source[2*i]=2*x-0.3*y+80; source[2*i+1]=0.3*x+2*y+20 }
        val fit=EdgeFaceMath.fit(source)
        for(i in 0..4) {
            assertEquals(target[2*i],fit[0]*source[2*i]-fit[1]*source[2*i+1]+fit[2],1e-8)
            assertEquals(target[2*i+1],fit[1]*source[2*i]+fit[0]*source[2*i+1]+fit[3],1e-8)
        }
        assertThrows(IllegalArgumentException::class.java) { EdgeFaceMath.fit(DoubleArray(10)) }
    }
    @Test fun planarRgbOrderAndNormalizationAreExact() {
        val red=IntArray(112*112) { 0xffff0000.toInt() }
        val tensor=EdgeFaceMath.alignedTensor(red,112,112,EdgeFaceMath.template)
        assertEquals(1f,tensor[56*112+56],1e-6f)
        assertEquals(-1f,tensor[12544+56*112+56],1e-6f)
        assertEquals(-1f,tensor[25088+56*112+56],1e-6f)
    }
    @Test fun pythonGoldenPreprocessingMatchesKotlin() {
        val pixels=IntArray(160*160) { i ->
            val x=i%160; val y=i/160
            (255 shl 24) or (((x*3+y)%256) shl 16) or (((y*5+x)%256) shl 8) or ((x*7+y*11)%256)
        }
        val points=EdgeFaceMath.template.mapIndexed { i,v -> v*1.1+if(i%2==0) 8 else 4 }.toDoubleArray()
        val tensor=EdgeFaceMath.alignedTensor(pixels,160,160,points)
        val bytes=javaClass.getResourceAsStream("/preprocessing-golden.f32")!!.readBytes()
        val reference=java.nio.ByteBuffer.wrap(bytes).order(java.nio.ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
        assertEquals(tensor.size,reference.remaining())
        tensor.forEach { assertEquals(reference.get(),it,2e-6f) }
    }
    @Test fun failureResultsCannotCarryScoresOrFaceImages() {
        val result=FaceVerificationResult.notRun("MODEL_UNAVAILABLE").toMap()
        assertEquals("NOT_RUN",result["status"])
        assertNull(result["similarityScore"])
        assertFalse(result.keys.any { it.contains("crop",true) || it.contains("embedding",true) })
    }
    @Test fun aggregationRejectsInvalidScores() {
        assertEquals(0.4f,EdgeFaceMath.median(listOf(0.9f,0.1f,0.4f)),0f)
        assertThrows(IllegalArgumentException::class.java) { EdgeFaceMath.median(listOf(Float.NaN)) }
    }
}
