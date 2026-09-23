package com.sih188.borderdoc

import android.graphics.BitmapFactory
import android.os.Bundle
import com.sih188.borderdoc.face.FaceVerificationModule
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — hosts the Flutter UI and registers the face verification
 * platform channel.
 *
 * INTEGRATION NOTE (M3 owner):
 * The face_verification channel is the ONLY touch-point between this module
 * and the Flutter layer. Disabling the module requires no changes to
 * MainActivity; FaceVerificationModule.verifyFace() returns NOT_RUN when
 * the module is toggled off or fails to initialise.
 */
class MainActivity : FlutterActivity() {

    // Channel name agreed with the Flutter side (face_verification_service.dart)
    private val FACE_CHANNEL = "com.sih188.borderdoc/face_verification"

    private lateinit var faceModule: FaceVerificationModule

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        faceModule = FaceVerificationModule(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FACE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // -------------------------------------------------------
                    // verifyFace
                    // Args:
                    //   liveImagePath      : String  — absolute path to JPEG
                    //   referenceImagePath : String? — absolute path or null
                    //                        (null → use bundled synthetic ref)
                    // Returns: Map<String, Any?> matching FaceVerificationResult
                    // -------------------------------------------------------
                    "verifyFace" -> {
                        val livePath = call.argument<String>("liveImagePath")
                        val refPath  = call.argument<String?>("referenceImagePath")

                        if (livePath == null) {
                            result.error("INVALID_ARGS", "liveImagePath is required", null)
                            return@setMethodCallHandler
                        }

                        // Run on a background thread — TFLite inference blocks
                        Thread {
                            try {
                                val liveBitmap = livePath?.let { decodeAndRotateBitmap(it) }
                                val refBitmap  = refPath?.let { decodeAndRotateBitmap(it) }

                                val verificationResult = faceModule.verifyFace(liveBitmap, refBitmap)

                                // Post back to the platform thread
                                runOnUiThread {
                                    result.success(verificationResult.toMap())
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("VERIFICATION_ERROR", e.message, null)
                                }
                            }
                        }.start()
                    }

                    // -------------------------------------------------------
                    // isModuleAvailable — lightweight check before showing UI
                    // -------------------------------------------------------
                    "isModuleAvailable" -> {
                        result.success(faceModule.isAvailable())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun decodeAndRotateBitmap(path: String): android.graphics.Bitmap? =
        com.sih188.borderdoc.face.CaptureBitmapDecoder.decode(path)
}
