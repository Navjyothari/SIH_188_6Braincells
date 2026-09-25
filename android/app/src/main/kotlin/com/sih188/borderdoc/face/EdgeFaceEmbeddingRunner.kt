package com.sih188.borderdoc.face

import android.content.Context
import ai.onnxruntime.*
import org.json.JSONObject
import java.nio.FloatBuffer
import java.security.MessageDigest

/** No downloads, delegates or alternative model fallback. Owns one native session. */
internal class EdgeFaceEmbeddingRunner private constructor(context: Context, enforceReleaseApproval: Boolean, assetRoot: String = "ml") : AutoCloseable {
    constructor(context: Context) : this(context, true)
    companion object {
        /** Only instrumentation's separate APK may load a local evaluation checkpoint. */
        fun forLocalValidation(testContext: Context, assetRoot: String = "ml"): EdgeFaceEmbeddingRunner {
            check(com.sih188.borderdoc.BuildConfig.DEBUG && testContext.packageName=="com.sih188.borderdoc.test")
            require(assetRoot in setOf("ml", "ml/s", "ml/xs"))
            return EdgeFaceEmbeddingRunner(testContext, false, assetRoot)
        }
    }
    val manifest = JSONObject(context.assets.open("$assetRoot/edgeface_manifest.json").bufferedReader().use { it.readText() })
    val modelHash: String
    val modelVersion: String = manifest.getString("modelVersion")
    private val inputName=manifest.getJSONObject("input").getString("name")
    private val outputName=manifest.getJSONObject("output").getString("name")
    private val env=OrtEnvironment.getEnvironment()
    private val session: OrtSession

    init {
        require(manifest.getString("modelId") in setOf("edgeface-xs-gamma-06", "edgeface-s-gamma-05"))
        require(manifest.getString("alignmentVersion")==EdgeFaceMath.ALIGNMENT_VERSION)
        if(enforceReleaseApproval) require(manifest.getString("redistributionStatus")=="approved")
        require(manifest.getJSONObject("input").getString("dtype")=="float32")
        require(manifest.getJSONObject("input").getString("normalization")=="(rgb/255 - 0.5) / 0.5")
        require(manifest.getJSONObject("output").getString("dtype")=="float32")
        val bytes=context.assets.open("$assetRoot/edgeface.onnx").use { it.readBytes() }
        modelHash=MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
        require(modelHash==manifest.getString("onnxSha256")) { "Model checksum mismatch" }
        session=OrtSession.SessionOptions().use { options ->
            options.setIntraOpNumThreads(2)
            options.setInterOpNumThreads(1)
            options.setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL)
            options.addConfigEntry("session.intra_op.allow_spinning","0")
            env.createSession(bytes,options)
        }
        try {
            require(session.inputNames==setOf(inputName) && session.outputNames==setOf(outputName))
            fun checkInfo(info: NodeInfo?, key: String, expected: LongArray) {
                val tensor=info?.info as? TensorInfo ?: error("Not a tensor")
                val shape=manifest.getJSONObject(key).getJSONArray("shape")
                require(shape.length()==expected.size && expected.indices.all { shape.getLong(it)==expected[it] })
                require(tensor.type==OnnxJavaType.FLOAT && tensor.shape.contentEquals(expected))
            }
            checkInfo(session.inputInfo[inputName],"input",longArrayOf(1,3,112,112))
            checkInfo(session.outputInfo[outputName],"output",longArrayOf(1,512))
            embed(FloatArray(3*112*112)) // Warm up off the UI thread; never a recognition result.
        } catch(e: Exception) { session.close(); throw e }
    }

    @Synchronized fun embed(input: FloatArray): FloatArray {
        require(input.size==3*112*112 && input.all { it.isFinite() && it in -1f..1f })
        OnnxTensor.createTensor(env,FloatBuffer.wrap(input),longArrayOf(1,3,112,112)).use { tensor ->
            session.run(mapOf(inputName to tensor)).use { result ->
                val out=result.get(outputName).get() as OnnxTensor
                val values=FloatArray(512)
                out.floatBuffer.get(values)
                return EdgeFaceMath.normalized(values)
            }
        }
    }
    @Synchronized override fun close() { session.close() }
}
