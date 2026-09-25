package com.sih188.borderdoc.face

import android.os.Bundle
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import org.json.JSONObject
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.concurrent.TimeUnit

/** Explicit local capture evaluation. Never changes approval flags or produces identity verdicts. */
@RunWith(AndroidJUnit4::class)
class CapturedPairDiagnosticTest {
    @Test fun evaluatePair() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val args = InstrumentationRegistry.getArguments()
        val target = instrumentation.targetContext
        val maxEdge = args.getString("maxEdge")?.toInt() ?: 0
        require(maxEdge == 0 || maxEdge in 640..2048)
        val liveCopies = args.getString("liveCopies")?.toInt() ?: 1
        val sustainSeconds = args.getString("sustainSeconds")?.toInt() ?: 0
        require(liveCopies in 1..3 && sustainSeconds in 0..600)
        val fixture = args.getString("synthetic") == "true"
        var temporary: File? = null
        fun input(name: String): String {
            val file = File(requireNotNull(args.getString(name)) { "Supply explicit $name capture path" }).canonicalFile
            val cache = target.cacheDir.canonicalFile
            require(file.path.startsWith(cache.path + File.separator) && file.isFile) { "Capture must be in this app's cache" }
            return file.path
        }
        val detector = FaceDetection.getClient(FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL).setMinFaceSize(0.02f).build())
        val report = JSONObject().put("identityVerdict", "NOT_RUN")
            .put("liveCopies", liveCopies).put("reusesSameLivePhoto", liveCopies > 1).put("sustainSeconds", sustainSeconds).put("detectionMaxEdge", maxEdge).put("purpose", "capture-quality-and-timing-only").put("synthetic", fixture)
        val memorySamples = org.json.JSONArray()
        val power = target.getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
        fun sample(label: String) {
            val info = android.os.Debug.MemoryInfo()
            android.os.Debug.getMemoryInfo(info)
            memorySamples.put(JSONObject().put("phase", label).put("elapsedMs", SystemClock.elapsedRealtime())
                .put("totalPssKb", info.totalPss).put("nativeHeapAllocatedBytes", android.os.Debug.getNativeHeapAllocatedSize())
                .put("javaHeapUsedBytes", Runtime.getRuntime().totalMemory()-Runtime.getRuntime().freeMemory())
                .put("thermalStatus", if(android.os.Build.VERSION.SDK_INT >= 29) power.currentThermalStatus else -1))
        }
        report.put("processMemorySamples", memorySamples)
        sample("before-model")
        try {
            val document: String
            val selfie: String
            if (fixture) {
                temporary = File.createTempFile("edgeface-diagnostic-", ".jpg", target.cacheDir)
                instrumentation.context.assets.open("edgeface/synthetic-portrait.jpg").use { source ->
                    temporary!!.outputStream().use { source.copyTo(it) }
                }
                document = temporary!!.path
                selfie = document
            } else {
                document = input("document")
                selfie = input("selfie")
                require(document != selfie) { "Select distinct document and live captures" }
            }
            val startup = SystemClock.elapsedRealtimeNanos()
            EdgeFaceEmbeddingRunner.forLocalValidation(instrumentation.context).use { runner ->
                report.put("model", runner.modelVersion).put("sha256", runner.modelHash)
                    .put("startupAndWarmupMs", (SystemClock.elapsedRealtimeNanos()-startup)/1e6)
                sample("model-loaded")
                val referenceEmbeddings = mutableMapOf<String, FloatArray>()
                val alignmentCosines = JSONObject()
                report.put("alignmentCosinesToFullResolution", alignmentCosines)
                fun pair(edge: Int, reference: Boolean = false): JSONObject {
                    val start = SystemClock.elapsedRealtimeNanos()
                    val stages = JSONObject()
                    fun process(path: String, role: String) {
                        val timing = JSONObject()
                        stages.put(role, timing)
                        var t = SystemClock.elapsedRealtimeNanos()
                        val bitmap = CaptureBitmapDecoder.decode(path) ?: throw CaptureRejected("${role}_IMAGE_UNREADABLE")
                        timing.put("decodeMs", (SystemClock.elapsedRealtimeNanos()-t)/1e6)
                        val ratio = if(edge > 0) minOf(1.0, edge.toDouble()/maxOf(bitmap.width, bitmap.height)) else 1.0
                        val detectionBitmap = if(ratio < 1.0) android.graphics.Bitmap.createScaledBitmap(bitmap, (bitmap.width*ratio).toInt().coerceAtLeast(1), (bitmap.height*ratio).toInt().coerceAtLeast(1), true) else bitmap
                        var recycle = true
                        try {
                            t = SystemClock.elapsedRealtimeNanos()
                            val task = detector.process(InputImage.fromBitmap(detectionBitmap, 0))
                            val faces = try { Tasks.await(task, 15, TimeUnit.SECONDS) }
                            catch (e: java.util.concurrent.TimeoutException) {
                                recycle = false
                                task.addOnCompleteListener(java.util.concurrent.Executor { it.run() }) { detectionBitmap.recycle() }
                                throw e
                            }
                            timing.put("detectMs", (SystemClock.elapsedRealtimeNanos()-t)/1e6)
                                .put("detectionWidth", detectionBitmap.width).put("detectionHeight", detectionBitmap.height).put("faces", faces.size).put("width", bitmap.width).put("height", bitmap.height)
                            t = SystemClock.elapsedRealtimeNanos()
                            val tensor = try { FaceQualityGate.tensor(bitmap, faces, role == "document", detectionBitmap.width, detectionBitmap.height) }
                                catch (e: CaptureRejected) { throw CaptureRejected("${role}_${e.reason}") }
                            timing.put("alignAndQualityMs", (SystemClock.elapsedRealtimeNanos()-t)/1e6)
                            t = SystemClock.elapsedRealtimeNanos()
                            val embedding = runner.embed(tensor)
                            assertTrue(embedding.size == 512 && embedding.all { it.isFinite() })
                            if(reference) referenceEmbeddings[role] = embedding
                            else if(edge > 0) {
                                val cosine = EdgeFaceMath.cosine(referenceEmbeddings.getValue(role), embedding)
                                alignmentCosines.put(role, cosine.toDouble())
                                assertTrue("$role downscaled detection changed embedding: $cosine", cosine >= 0.98f)
                            }
                            timing.put("embedMs", (SystemClock.elapsedRealtimeNanos()-t)/1e6)
                        } finally {
                            if (recycle && detectionBitmap !== bitmap) detectionBitmap.recycle()
                            if (recycle || detectionBitmap !== bitmap) bitmap.recycle()
                        }
                    }
                    process(document, "document")
                    for(index in 1..liveCopies) process(selfie, "selfie$index")
                    return stages.put("totalMs", (SystemClock.elapsedRealtimeNanos()-start)/1e6)
                }
                if(maxEdge > 0) report.put("fullResolutionReferencePair", pair(0, true))
                report.put("firstPair", pair(maxEdge))
                fun batch(label: String): List<Double> {
                    return (1..20).map { index ->
                        val time = pair(maxEdge).getDouble("totalMs")
                        if(index % 5 == 0) {
                            sample("$label-$index")
                            instrumentation.sendStatus(2, Bundle().apply { putString("edgeface_progress", "$label $index/20") })
                        }
                        time
                    }.sorted()
                }
                val sustainedStart = SystemClock.elapsedRealtime()
                val runs = batch("initial")
                if(sustainSeconds > 0) {
                    var completed = 0
                    var nextProgress = SystemClock.elapsedRealtime()+30000
                    while(SystemClock.elapsedRealtime()-sustainedStart < sustainSeconds*1000L) {
                        pair(maxEdge)
                        completed++
                        if(completed % 10 == 0) sample("sustained-$completed")
                        if(SystemClock.elapsedRealtime() >= nextProgress) {
                            instrumentation.sendStatus(2, Bundle().apply { putString("edgeface_progress", "Sustained processing ${(SystemClock.elapsedRealtime()-sustainedStart)/1000}s") })
                            nextProgress = SystemClock.elapsedRealtime()+30000
                        }
                    }
                    val after = batch("after-sustained")
                    report.put("sustainedAdditionalRuns", completed).put("afterSustainedP50Ms", after[9])
                        .put("afterSustainedP95Ms", after[18]).put("afterSustainedRuns", after.size)
                        .put("sustainedAndFinalBatchMs", SystemClock.elapsedRealtime()-sustainedStart)
                }
                sample("before-model-close")
                report.put("qualityStatus", "ACCEPTED_BY_PROVISIONAL_GATES")
                    .put("alignmentCosinesToFullResolution", alignmentCosines).put("warmPairP50Ms", runs[9]).put("warmPairP95Ms", runs[18]).put("runs", runs.size)
            }
            sample("after-model-close")
        } catch (e: CaptureRejected) {
            report.put("qualityStatus", "RECAPTURE").put("reason", e.reason)
            if (fixture) throw AssertionError("Synthetic smoke fixture failed: ${e.reason}")
        } finally {
            instrumentation.addResults(Bundle().apply { putString("edgeface_capture_diagnostic", report.toString()) })
            detector.close()
            temporary?.delete()
        }
    }
}
