package com.sih188.borderdoc.face

import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.nio.ByteBuffer
import java.nio.ByteOrder
import android.os.SystemClock

/** Local engineering test only. Model/fixtures live in the test APK, never main assets. */
@RunWith(AndroidJUnit4::class)
class LocalEdgeFaceModelTest {
    @Test fun bundledDetectorAndFivePointPipelineProcessSyntheticFace() {
        val context=InstrumentationRegistry.getInstrumentation().context
        val image=context.assets.open("edgeface/synthetic-portrait.jpg").use {
            android.graphics.BitmapFactory.decodeStream(it)
        }
        val detector=com.google.mlkit.vision.face.FaceDetection.getClient(
            com.google.mlkit.vision.face.FaceDetectorOptions.Builder()
                .setPerformanceMode(com.google.mlkit.vision.face.FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
                .setLandmarkMode(com.google.mlkit.vision.face.FaceDetectorOptions.LANDMARK_MODE_ALL)
                .setMinFaceSize(0.02f).build())
        try {
            val faces=com.google.android.gms.tasks.Tasks.await(
                detector.process(com.google.mlkit.vision.common.InputImage.fromBitmap(image,0)),
                15,java.util.concurrent.TimeUnit.SECONDS)
            assertEquals(1,faces.size)
            val document=FaceQualityGate.tensor(image,faces,true)
            val selfie=FaceQualityGate.tensor(image,faces,false)
            EdgeFaceEmbeddingRunner.forLocalValidation(context, InstrumentationRegistry.getArguments().getString("modelAssets") ?: "ml").use { runner ->
                val a=runner.embed(document); val b=runner.embed(selfie)
                assertTrue(EdgeFaceMath.cosine(a,b)>=0.9999f)
                // Diagnostic only: detector alignment difference on ONE fictional portrait.
                val bytes=context.assets.open("${InstrumentationRegistry.getArguments().getString("fixtureAssets") ?: "edgeface"}/parity-embedding.f32").use { it.readBytes() }
                val buffer=ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
                val reference=FloatArray(buffer.remaining()).also { buffer.get(it) }
                InstrumentationRegistry.getInstrumentation().addResults(android.os.Bundle().apply {
                    putString("edgeface_alignment_synthetic", "cosineToOfficialReference=${EdgeFaceMath.cosine(a,reference)} faces=1")
                })
            }
        } finally { detector.close(); image.recycle() }
    }

    @Test fun officialModelMatchesDesktopAndRunsRepeatedly() {
        val context=InstrumentationRegistry.getInstrumentation().context
        fun floats(name: String): FloatArray {
            val bytes=context.assets.open("${InstrumentationRegistry.getArguments().getString("fixtureAssets") ?: "edgeface"}/$name").use { it.readBytes() }
            val buffer=ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
            return FloatArray(buffer.remaining()).also { buffer.get(it) }
        }
        val input=floats("parity-input.f32")
        val expected=EdgeFaceMath.normalized(floats("parity-embedding.f32"))
        val startup=SystemClock.elapsedRealtimeNanos()
        EdgeFaceEmbeddingRunner.forLocalValidation(context, InstrumentationRegistry.getArguments().getString("modelAssets") ?: "ml").use { runner ->
            val startupMs=(SystemClock.elapsedRealtimeNanos()-startup)/1e6
            val actual=runner.embed(input)
            val cosine=EdgeFaceMath.cosine(expected,actual)
            val error=expected.indices.maxOf { kotlin.math.abs(expected[it]-actual[it]) }
            assertTrue("Desktop/Android cosine $cosine",cosine>=0.9999f)
            assertTrue("Normalized max absolute error $error",error<=0.0001f)
            val durations=(1..20).map {
                val start=SystemClock.elapsedRealtimeNanos()
                assertTrue(EdgeFaceMath.cosine(actual,runner.embed(input))>=0.9999f)
                (SystemClock.elapsedRealtimeNanos()-start)/1e6
            }.sorted()
            InstrumentationRegistry.getInstrumentation().addResults(android.os.Bundle().apply {
                putString("edgeface_local", "model=${runner.modelVersion} hash=${runner.modelHash} cosine=$cosine maxAbs=$error startupAndWarmupMs=$startupMs embedP50Ms=${durations[9]} embedP95Ms=${durations[18]} runs=20")
            })
        }
    }
}
