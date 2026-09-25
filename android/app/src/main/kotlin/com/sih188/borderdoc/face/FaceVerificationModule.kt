package com.sih188.borderdoc.face

import android.content.Context
import android.os.SystemClock
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import com.google.android.gms.tasks.Tasks
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/** Serialized, fail-closed EdgeFace pipeline. No reference fallback or inherited thresholds. */
class FaceVerificationModule(private val context: Context) : AutoCloseable {
    companion object { const val MODEL_VERSION="edgeface_s_gamma_05-ce86851cfc37" }
    private var runner: EdgeFaceEmbeddingRunner?=null
    private var closed=false
    private val detector=FaceDetection.getClient(FaceDetectorOptions.Builder()
        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
        .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
        .setMinFaceSize(0.02f).build())

    @Synchronized fun isAvailable(): Boolean {
        if(closed) return false
        return try {
            if(runner==null) runner=EdgeFaceEmbeddingRunner(context)
            true
        } catch(e: Exception) { false } catch(e: LinkageError) { false }
    }

    private fun policy(model: EdgeFaceEmbeddingRunner): DecisionPolicy {
        val config=JSONObject(context.assets.open("ml/edgeface_evaluation.json").bufferedReader().use { it.readText() })
        require(config.getBoolean("approved"))
        require(config.getString("qualityVersion")==FaceQualityGate.VERSION)
        require(config.getString("documentPortraitVersion")==PassportPortraitLayout.VERSION)
        require(config.getString("detectorVersion")=="mlkit-bundled-16.1.5")
        require(config.getString("aggregation")=="median-all-accepted-v1")
        require(config.getBoolean("androidParityPassed") && config.getBoolean("heldOutEvaluationPassed"))
        require(config.getString("reportId").isNotBlank())
        return DecisionPolicy(config.getString("onnxSha256"),config.getString("alignmentVersion"),
            config.getString("thresholdVersion"),config.getDouble("noMatchBelow").toFloat(),
            config.getDouble("matchAtOrAbove").toFloat(),true).also { it.classify(0f,model.modelHash) }
    }

    @Synchronized fun verifyFace(documentPath: String?, selfiePaths: List<String>): FaceVerificationResult {
        val start=SystemClock.elapsedRealtime()
        val timings=mutableMapOf("decode" to 0L,"detect" to 0L,"align" to 0L,"embed" to 0L)
        fun finish(r: FaceVerificationResult)=r.copy(timingMs=timings.toMap()+mapOf("total" to SystemClock.elapsedRealtime()-start))
        if(closed) return finish(FaceVerificationResult.notRun("CLOSED"))
        if(documentPath.isNullOrBlank()) return finish(FaceVerificationResult.notRun("DOCUMENT_REQUIRED"))
        if(selfiePaths.size !in 1..3 || selfiePaths.any { it.isBlank() }) return finish(FaceVerificationResult.notRun("INVALID_INPUT"))
        if(!isAvailable()) return finish(FaceVerificationResult.notRun("MODEL_UNAVAILABLE"))
        val model=runner!!
        val policy=try { policy(model) } catch(e: Exception) {
            return finish(FaceVerificationResult.notRun("EVALUATION_PENDING").copy(modelVersion=model.modelVersion))
        }
        fun embed(path: String, document: Boolean): FloatArray {
            var t=SystemClock.elapsedRealtime()
            val image=CaptureBitmapDecoder.decode(path) ?: throw CaptureRejected("IMAGE_UNREADABLE")
            timings["decode"]=timings.getValue("decode")+SystemClock.elapsedRealtime()-t
            var recycleOnExit=true
            try {
                t=SystemClock.elapsedRealtime()
                val detection=detector.process(InputImage.fromBitmap(image,0))
                val faces=try { Tasks.await(detection,15,TimeUnit.SECONDS) }
                catch(e: java.util.concurrent.TimeoutException) {
                    // ML Kit may still read the bitmap after the bounded wait expires.
                    recycleOnExit=false
                    detection.addOnCompleteListener(java.util.concurrent.Executor { it.run() }) { image.recycle() }
                    throw e
                }
                timings["detect"]=timings.getValue("detect")+SystemClock.elapsedRealtime()-t
                t=SystemClock.elapsedRealtime()
                val selected=if(document) DocumentPortraitLocator.select(image,faces) else faces
                val tensor=FaceQualityGate.tensor(image,selected,document)
                timings["align"]=timings.getValue("align")+SystemClock.elapsedRealtime()-t
                t=SystemClock.elapsedRealtime()
                return model.embed(tensor).also { timings["embed"]=timings.getValue("embed")+SystemClock.elapsedRealtime()-t }
            } finally { if(recycleOnExit) image.recycle() }
        }
        return try {
            val doc=try { embed(documentPath,true) } catch(e: CaptureRejected) {
                return finish(FaceVerificationResult.notRun("DOCUMENT_${e.reason}").copy(modelVersion=model.modelVersion))
            }
            val scores=selfiePaths.map { EdgeFaceMath.cosine(doc,embed(it,false)) }
            val score=EdgeFaceMath.median(scores)
            finish(FaceVerificationResult(policy.classify(score,model.modelHash),score,policy.match,
                model.modelVersion,"COMPLETED",policy.version))
        } catch(e: CaptureRejected) {
            finish(FaceVerificationResult("RECAPTURE",modelVersion=model.modelVersion,reasonCode="SELFIE_${e.reason}"))
        } catch(e: Exception) {
            finish(FaceVerificationResult.notRun("INFERENCE_FAILED").copy(modelVersion=model.modelVersion))
        } catch(e: LinkageError) {
            finish(FaceVerificationResult.notRun("RUNTIME_UNAVAILABLE"))
        }
    }

    @Synchronized override fun close() {
        if(closed) return
        closed=true
        try { runner?.close() } finally { runner=null; detector.close() }
    }
}
