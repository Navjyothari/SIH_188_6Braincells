package org.example.fictionalscreen.fictional_screen

import android.content.Intent
import android.graphics.BitmapFactory
import android.util.Log
import com.google.mlkit.common.MlKitException
import android.view.WindowManager
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var captureReply: MethodChannel.Result? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val recognizer by lazy { TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS) }
    private val store by lazy { EvidenceStore(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fictional_screen/device")
            .setMethodCallHandler { call, reply ->
                when (call.method) {
                    "capture" -> {
                        if (captureReply != null) reply.error("BUSY", "Camera already active", null)
                        else {
                            CaptureMemory.value = null
                            captureReply = reply
                            startActivityForResult(Intent(this, CaptureActivity::class.java), 41)
                        }
                    }
                    "recognize" -> {
                        try {
                            val bytes = call.argument<ByteArray>("bytes")!!
                            if (bytes.size > 24 * 1024 * 1024) {
                                reply.error("CAPTURE_TOO_LARGE", "Capture exceeds 24 MiB", null)
                                return@setMethodCallHandler
                            }
                            val rotation = call.argument<Int>("rotation")!!
                            require(rotation in listOf(0, 90, 180, 270))
                            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                            if (bitmap == null) {
                                reply.error("IMAGE_DECODE_FAILED", "Cannot decode capture", null)
                                return@setMethodCallHandler
                            }
                            recognizer.process(InputImage.fromBitmap(bitmap, rotation))
                                .addOnSuccessListener { text ->
                                    reply.success(mapOf("text" to text.text, "engine" to "bundled-mlkit-latin/16.0.1",
                                        "blocks" to text.textBlocks.map { block ->
                                            val box = block.boundingBox
                                            mapOf("text" to block.text, "box" to listOf(box?.left, box?.top, box?.right, box?.bottom))
                                        }))
                                }
                                .addOnFailureListener { error ->
                                    val code = if (error is MlKitException) "OCR_MLKIT_${error.errorCode}" else "OCR_${error.javaClass.simpleName}"
                                    Log.e("FictionalScreen", code)
                                    reply.error(code, "Local recognition failed", null)
                                }
                                .addOnCompleteListener { bitmap.recycle() }
                        } catch (error: Exception) {
                            val code = "OCR_${error.javaClass.simpleName}"
                            Log.e("FictionalScreen", code)
                            reply.error(code, "Local recognition setup failed", null)
                        }
                    }
                    "save", "load", "list" -> worker.execute {
                        try {
                            val output: Any = when (call.method) {
                                "save" -> store.save(call.argument<String>("envelope")!!)
                                "load" -> store.load(call.argument<String>("id")!!)
                                else -> store.list()
                            }
                            runOnUiThread { reply.success(output) }
                        } catch (_: Exception) {
                            runOnUiThread { reply.error("STORAGE_FAILED", "Evidence storage operation failed", null) }
                        }
                    }
                    else -> reply.notImplemented()
                }
            }
    }

    @Deprecated("Android activity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 41) {
            val value = CaptureMemory.value
            CaptureMemory.value = null
            if (resultCode == RESULT_OK && value != null) {
                captureReply?.success(mapOf("bytes" to value.first, "rotation" to value.second))
            } else if (data?.getBooleanExtra("failed", false) == true) {
                captureReply?.error(data.getStringExtra("code") ?: "CAMERA_CAPTURE_FAILED", "Camera operation failed", null)
            } else captureReply?.success(null)
            captureReply = null
        }
    }
}
