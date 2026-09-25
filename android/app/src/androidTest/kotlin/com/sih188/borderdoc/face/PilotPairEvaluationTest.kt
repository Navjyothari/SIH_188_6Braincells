package com.sih188.borderdoc.face

import android.os.Bundle
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.concurrent.TimeUnit

/** Explicit development-pair measurement. Never grants an identity verdict or stores embeddings. */
@RunWith(AndroidJUnit4::class)
class PilotPairEvaluationTest {
    @Test fun evaluateExplicitPair() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val args = InstrumentationRegistry.getArguments()
        val synthetic = args.getString("synthetic") == "true"
        val report = JSONObject().put("identityVerdict", "NOT_RUN").put("split", "development")
            .put("synthetic", synthetic).put("qualityVersion", FaceQualityGate.VERSION)
            .put("documentPortraitVersion", PassportPortraitLayout.VERSION).put("alignmentVersion", EdgeFaceMath.ALIGNMENT_VERSION).put("detectorVersion", "mlkit-bundled-16.1.5")
        val temporary = mutableListOf<File>()
        val detector = FaceDetection.getClient(FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL).setMinFaceSize(0.02f).build())
        try {
            fun id(key: String): String {
                val value = requireNotNull(args.getString(key)) { "Missing $key" }
                require(value.matches(Regex("[A-Z][A-Z0-9_-]{1,31}"))) { "Use anonymous IDs" }
                return value
            }
            fun path(key: String): String {
                val file = File(requireNotNull(args.getString(key))).canonicalFile
                val cache = instrumentation.targetContext.cacheDir.canonicalFile
                require(file.isFile && file.path.startsWith(cache.path + File.separator)) { "Input must be an explicit app-cache capture" }
                return file.path
            }
            val doc: String
            val live: String
            if(synthetic) {
                val fixture = File.createTempFile("pilot-smoke-", ".jpg", instrumentation.targetContext.cacheDir)
                temporary.add(fixture)
                instrumentation.context.assets.open("edgeface/synthetic-portrait.jpg").use { source ->
                    fixture.outputStream().use { source.copyTo(it) }
                }
                doc = fixture.path; live = doc
                report.put("pairId", "SYNTHETIC-SMOKE").put("pairType", "synthetic-self-comparison")
            } else {
                require(args.getString("consent") == "confirmed") { "Record participant consent before collecting a pair" }
                val documentSubject = id("documentSubject")
                val liveSubject = id("liveSubject")
                val cross = documentSubject != liveSubject
                require(!cross || args.getString("crossPersonConsent") == "confirmed") { "Cross-person evaluation requires that scope of consent" }
                report.put("pairId", id("pairId")).put("documentSubject", documentSubject).put("liveSubject", liveSubject)
                    .put("pairType", if(cross) "different-person" else "same-person")
                doc = path("document"); live = path("selfie")
                require(doc != live) { "Document and live image must be distinct" }
            }
            EdgeFaceEmbeddingRunner.forLocalValidation(instrumentation.context, args.getString("modelAssets") ?: "ml").use { model ->
                report.put("modelVersion", model.modelVersion).put("onnxSha256", model.modelHash)
                fun embed(path: String, role: String): FloatArray {
                    val image = CaptureBitmapDecoder.decode(path) ?: throw CaptureRejected("${role}_IMAGE_UNREADABLE")
                    var recycle = true
                    try {
                        val task = detector.process(InputImage.fromBitmap(image, 0))
                        val faces = try { Tasks.await(task, 15, TimeUnit.SECONDS) }
                        catch (e: java.util.concurrent.TimeoutException) {
                            recycle = false
                            task.addOnCompleteListener(java.util.concurrent.Executor { it.run() }) { image.recycle() }
                            throw e
                        }
                        val tensor = try {
                            val selected=if(role == "document") DocumentPortraitLocator.select(image,faces) { cues -> report.put("documentLayoutCues",JSONObject(cues)) } else faces
                            FaceQualityGate.tensor(image, selected, role == "document")
                        }
                            catch(e: CaptureRejected) { throw CaptureRejected("${role}_${e.reason}") }
                        return model.embed(tensor)
                    } finally { if(recycle) image.recycle() }
                }
                val count=(args.getString("runs") ?: "1").toInt().also { require(it in 1..30) }
                val durations=mutableListOf<Double>()
                val scores=mutableListOf<Float>()
                repeat(count + if(count>1) 1 else 0) { index ->
                    val start=android.os.SystemClock.elapsedRealtimeNanos()
                    val value=EdgeFaceMath.cosine(embed(doc,"document"),embed(live,"live"))
                    if(count==1 || index>0) {
                        durations.add((android.os.SystemClock.elapsedRealtimeNanos()-start)/1e6)
                        scores.add(value)
                    }
                }
                val sorted=durations.sorted()
                report.put("warmRuns",count).put("pipelineMs",org.json.JSONArray(durations))
                    .put("pipelineP50Ms",sorted[kotlin.math.ceil(count*0.5).toInt()-1])
                    .put("pipelineP95Ms",sorted[kotlin.math.ceil(count*0.95).toInt()-1])
                    .put("scoreMin",scores.min().toDouble()).put("scoreMax",scores.max().toDouble())
                val score = scores.last()
                assertTrue(score.isFinite() && score in -1f..1f)
                if(synthetic) assertTrue(score >= 0.9999f)
                report.put("qualityStatus", "ACCEPTED_BY_PROVISIONAL_GATES").put("developmentCosine", score.toDouble())
            }
        } catch(e: CaptureRejected) {
            report.put("qualityStatus", "RECAPTURE").put("reason", e.reason)
            if(synthetic) throw AssertionError("Synthetic fixture rejected: ${e.reason}")
        } catch(e: Exception) {
            report.put("qualityStatus", "ERROR").put("reason", e.javaClass.simpleName)
            throw e
        } finally {
            instrumentation.addResults(Bundle().apply { putString("edgeface_pilot_pair", report.toString()) })
            detector.close()
            temporary.forEach { it.delete() }
        }
    }
}
