package com.sih188.borderdoc

import com.sih188.borderdoc.face.FaceVerificationModule
import com.sih188.borderdoc.face.FaceVerificationResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.RejectedExecutionException

class MainActivity : FlutterActivity() {
    private val worker=ThreadPoolExecutor(1,1,0L,TimeUnit.MILLISECONDS,ArrayBlockingQueue<Runnable>(1))
    private var module: FaceVerificationModule?=null
    private var channel: MethodChannel?=null
    private fun faceModule()=module ?: FaceVerificationModule(applicationContext).also { module=it }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel=MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"com.sih188.borderdoc/face_verification")
        channel!!.setMethodCallHandler { call, result ->
            if(call.method !in setOf("verifyFace","isModuleAvailable")) {
                result.notImplemented(); return@setMethodCallHandler
            }
            try {
                worker.execute {
                    val response: Any = try {
                        if(call.method=="isModuleAvailable") faceModule().isAvailable()
                        else {
                            val document=call.argument<String>("documentImagePath") ?: call.argument<String>("referenceImagePath")
                            val selfies=call.argument<List<String>>("selfieImagePaths") ?:
                                listOfNotNull(call.argument<String>("liveImagePath"))
                            faceModule().verifyFace(document,selfies).toMap()
                        }
                    } catch(e: Exception) {
                        if(call.method=="isModuleAvailable") false else FaceVerificationResult.notRun("INVALID_INPUT").toMap()
                    } catch(e: LinkageError) {
                        if(call.method=="isModuleAvailable") false else FaceVerificationResult.notRun("RUNTIME_UNAVAILABLE").toMap()
                    }
                    runOnUiThread { if(!isDestroyed) result.success(response) }
                }
            } catch(e: RejectedExecutionException) {
                result.success(if(call.method=="isModuleAvailable") false else FaceVerificationResult.notRun("BUSY").toMap())
            }
        }
        worker.execute {
            try { faceModule().isAvailable() }
            catch (_: Exception) { /* Requests return a neutral unavailable result. */ }
            catch (_: LinkageError) { /* Unsupported runtime must not crash startup. */ }
        }
    }
    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        // Let the running request release its images, then close resources off the UI thread.
        worker.queue.clear()
        worker.execute { module?.close(); module=null }
        worker.shutdown()
        super.onDestroy()
    }
}
