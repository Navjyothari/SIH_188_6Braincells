package com.sih188.borderdoc.face

import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Release gate: fails (does not skip) until approved real model and desktop fixtures exist. */
@RunWith(AndroidJUnit4::class)
class EdgeFaceModelParityTest {
    @Test fun actualShippedModelMatchesDesktopEmbedding() {
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        fun floats(name: String): FloatArray {
            val bytes=instrumentation.context.assets.open(name).use { it.readBytes() }
            require(bytes.size%4==0)
            val buf=ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
            return FloatArray(buf.remaining()).also { buf.get(it) }
        }
        val input=floats("edgeface/parity-input.f32")
        val expected=EdgeFaceMath.normalized(floats("edgeface/parity-embedding.f32"))
        EdgeFaceEmbeddingRunner(instrumentation.targetContext).use { runner ->
            val actual=runner.embed(input)
            assertTrue("Desktop/Android cosine",EdgeFaceMath.cosine(expected,actual)>=0.9999f)
            for(i in expected.indices) assertEquals("Normalized component $i",expected[i],actual[i],0.0001f)
        }
    }
}
