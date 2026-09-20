package org.example.fictionalscreen.fictional_screen

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat

/** Capture bytes only in memory. No camera app, gallery, or plaintext temp files. */
object CaptureMemory { @Volatile var value: Pair<ByteArray, Int>? = null }

class CaptureActivity : ComponentActivity() {
    private lateinit var preview: PreviewView
    private lateinit var button: Button
    private var provider: ProcessCameraProvider? = null
    private var imageCapture: ImageCapture? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        val layout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        layout.addView(TextView(this).apply {
            text = "TEST DATA — FICTIONAL SPECIMEN ONLY\nInclude the entire card. Keep text sharp and avoid glare."
            textSize = 18f; setPadding(24, 24, 24, 24)
        })
        preview = PreviewView(this)
        layout.addView(preview, LinearLayout.LayoutParams(-1, 0, 1f))
        button = Button(this).apply {
            text = "Capture specimen"; isEnabled = false
            setOnClickListener { capture() }
        }
        layout.addView(button)
        layout.addView(Button(this).apply { text = "Cancel"; setOnClickListener { finish() } })
        setContentView(layout)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) startCamera()
        else requestPermissions(arrayOf(Manifest.permission.CAMERA), 42)
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<String>, grants: IntArray) {
        super.onRequestPermissionsResult(code, permissions, grants)
        if (code == 42 && grants.firstOrNull() == PackageManager.PERMISSION_GRANTED) startCamera() else fail("CAMERA_PERMISSION_DENIED")
    }

    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            try {
                provider = future.get()
                val live = Preview.Builder().build().also { it.setSurfaceProvider(preview.surfaceProvider) }
                imageCapture = ImageCapture.Builder().setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY).build()
                provider!!.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, live, imageCapture)
                button.isEnabled = true
            } catch (_: Exception) { fail("CAMERA_START_FAILED") }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun capture() {
        button.isEnabled = false
        val capture = imageCapture ?: return fail()
        capture.targetRotation = preview.display.rotation
        capture.takePicture(ContextCompat.getMainExecutor(this), object : ImageCapture.OnImageCapturedCallback() {
            override fun onCaptureSuccess(image: ImageProxy) {
                try {
                    if (image.format != ImageFormat.JPEG) {
                        fail("CAMERA_FORMAT_UNSUPPORTED")
                        return
                    }
                    val buffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    CaptureMemory.value = bytes to image.imageInfo.rotationDegrees
                    setResult(RESULT_OK)
                    finish()
                } catch (_: Exception) { fail() } finally { image.close() }
            }
            override fun onError(exception: ImageCaptureException) { fail() }
        })
    }

    private fun fail(code: String = "CAMERA_CAPTURE_FAILED") {
        android.util.Log.e("FictionalScreen", code)
        setResult(RESULT_CANCELED, Intent().putExtra("failed", true).putExtra("code", code))
        finish()
    }
    override fun onDestroy() { provider?.unbindAll(); super.onDestroy() }
}
