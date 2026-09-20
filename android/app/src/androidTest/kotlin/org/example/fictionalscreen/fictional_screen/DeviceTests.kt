package org.example.fictionalscreen.fictional_screen

import android.graphics.BitmapFactory
import android.content.Intent
import android.util.Base64
import androidx.test.core.app.ActivityScenario
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Until
import android.provider.Settings
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.FixMethodOrder
import org.junit.runners.MethodSorters
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class DeviceTests {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private val directory get() = File(context.noBackupFilesDir, "evidence-v1")
    private val payload by lazy {
        val original = instrumentation.context.assets.open("01-altered.png").use { it.readBytes() }
        val raw = instrumentation.context.assets.open("01-altered.txt").bufferedReader().use { it.readText() }
        JSONObject().put("envelopeVersion", 1).put("synthetic", true)
            .put("source", "INSTRUMENTATION_FIXTURE").put("capturedAt", "2026-09-18T00:00:00Z")
            .put("original", JSONObject().put("base64", Base64.encodeToString(original, Base64.NO_WRAP)).put("mimeType", "image/png").put("rotation", 0))
            .put("ocr", JSONObject().put("text", raw))
            .put("result", JSONObject().put("schemaVersion", 1).put("synthetic", true)
                .put("policyVersion", "number-consistency/1").put("layout", "FICTIONAL PASSPORT ALPHA")
                .put("governmentVerification", "NOT_CONFIGURED").put("state", "REVIEW_REQUIRED")
                .put("explanation", "Synthetic storage fixture: TEST558198 differs from TEST558199.")
                .put("fields", JSONObject().put("documentNumber", "TEST558198").put("repeatedNumber", "TEST558199"))
                .put("findings", org.json.JSONArray()))
            .toString()
    }

    @Test fun cameraCapturesOriginalJpegInMemory() {
        instrumentation.uiAutomation.executeShellCommand("pm grant ${context.packageName} android.permission.CAMERA").close()
        CaptureMemory.value = null
        val device = UiDevice.getInstance(instrumentation)
        ActivityScenario.launch<CaptureActivity>(Intent(context, CaptureActivity::class.java)).use {
            val button = device.wait(Until.findObject(By.text("CAPTURE SPECIMEN")), 15000)
                ?: device.wait(Until.findObject(By.text("Capture specimen")), 5000)
            assertNotNull("Camera capture button must appear", button)
            assertTrue(device.wait(Until.hasObject(By.textContains("CAPTURE").enabled(true)), 15000)
                || device.wait(Until.hasObject(By.text("Capture specimen").enabled(true)), 5000))
            button.click()
            val deadline = System.currentTimeMillis() + 15000
            while (CaptureMemory.value == null && System.currentTimeMillis() < deadline) Thread.sleep(100)
            val captured = CaptureMemory.value
            assertNotNull("Camera must deliver an in-memory capture", captured)
            assertEquals(0xff, captured!!.first[0].toInt() and 0xff)
            assertEquals(0xd8, captured.first[1].toInt() and 0xff)
            assertTrue(captured.second in listOf(0, 90, 180, 270))
            assertNotNull(BitmapFactory.decodeByteArray(captured.first, 0, captured.first.size))
            CaptureMemory.value = null
        }
    }

    @Test fun flutterHomeLaunchesOffline() {
        ActivityScenario.launch<MainActivity>(Intent(context, MainActivity::class.java)).use {
            assertTrue(UiDevice.getInstance(instrumentation).wait(
                Until.hasObject(By.desc("Capture fictional specimen")), 20000))
        }
    }

    @Test fun captureThroughFlutterCompletes() {
        instrumentation.uiAutomation.executeShellCommand("pm grant ${context.packageName} android.permission.CAMERA").close()
        ActivityScenario.launch<MainActivity>(Intent(context, MainActivity::class.java)).use {
            val device = UiDevice.getInstance(instrumentation)
            val launch = device.wait(Until.findObject(By.desc("Capture fictional specimen")), 20000)
            assertNotNull("Flutter capture control missing", launch)
            launch.click()
            val selector = By.text(java.util.regex.Pattern.compile("capture specimen", java.util.regex.Pattern.CASE_INSENSITIVE)).enabled(true)
            val shutter = device.wait(Until.findObject(selector), 15000)
            assertNotNull("Camera unavailable", shutter)
            shutter.click()
            val done = device.wait(Until.hasObject(By.desc("Result & evidence")), 30000)
            if (!done) {
                val error = device.findObject(By.descContains("Error code:"))?.contentDescription
                    ?: device.findObject(By.descContains("NOT SAVED"))?.contentDescription
                fail("Capture-to-OCR-to-save failed: $error")
            }
        }
    }

    @Test fun bundledOcrReadsAllTenImagesInAirplaneMode() {
        assertEquals("Enable airplane mode before the test", 1,
            Settings.Global.getInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0))
        val manifest = JSONObject(instrumentation.context.assets.open("manifest.json").bufferedReader().readText())
        val specimens = manifest.getJSONArray("specimens")
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        try {
            for (i in 0 until specimens.length()) {
                val specimen = specimens.getJSONObject(i)
                val bitmap = instrumentation.context.assets.open(specimen.getString("image")).use { BitmapFactory.decodeStream(it) }
                try {
                    val text = Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0)), 30, TimeUnit.SECONDS).text
                    assertTrue(text, text.contains("FICTIONAL PASSPORT ALPHA"))
                    assertTrue(text, text.contains("SPECIMEN - NOT VALID FOR TRAVEL"))
                    val fields = specimen.getJSONObject("expectedFields")
                    assertTrue(text, text.contains("DOCUMENT NUMBER: " + fields.getString("documentNumber")))
                    assertTrue(text, text.contains("REPEATED NUMBER: " + fields.getString("repeatedNumber")))
                } finally { bitmap.recycle() }
            }
        } finally { recognizer.close() }
    }

    @Test fun encryptedRoundTripAndFreshStore() {
        val id = EvidenceStore(context).save(payload)
        try {
            val bytes = File(directory, "$id.enc").readBytes()
            assertFalse(String(bytes, Charsets.ISO_8859_1).contains("NOT_CONFIGURED"))
            assertEquals(payload, EvidenceStore(context).load(id))
            assertTrue(EvidenceStore(context).list().contains(id))
        } finally { File(directory, "$id.enc").delete() }
    }

    @Test fun corruptionAndFilenameSwappingAreRejected() {
        val store = EvidenceStore(context)
        val id = store.save(payload)
        val original = File(directory, "$id.enc")
        val otherId = UUID.randomUUID().toString()
        val swapped = File(directory, "$otherId.enc")
        try {
            original.copyTo(swapped)
            assertThrows(Exception::class.java) { store.load(otherId) }
            val bytes = original.readBytes()
            bytes[bytes.lastIndex] = (bytes.last().toInt() xor 1).toByte()
            original.writeBytes(bytes)
            assertThrows(Exception::class.java) { store.load(id) }
            assertTrue(store.list().contains(id))
        } finally { original.delete(); swapped.delete() }
    }

    @Test fun incompleteWriteIsNotListed() {
        val store = EvidenceStore(context)
        val id = UUID.randomUUID().toString()
        val pending = File(directory, "$id.enc.new")
        try {
            pending.writeBytes(byteArrayOf(70, 83, 69))
            assertFalse(store.list().contains(id))
            assertThrows(Exception::class.java) { store.load("../outside") }
        } finally { pending.delete() }
    }

    // Run these methods in separate instrumentation processes, with force-stop between.
    @Test fun prepareRestartEvidence() {
        val id = EvidenceStore(context).save(payload)
        assertTrue(context.getSharedPreferences("restart-test", 0).edit().putString("id", id).commit())
    }

    @Test fun verifyRestartEvidence() {
        val id = context.getSharedPreferences("restart-test", 0).getString("id", null)
        assertNotNull("Run prepareRestartEvidence first", id)
        assertEquals(payload, EvidenceStore(context).load(id!!))
        ActivityScenario.launch<MainActivity>(Intent(context, MainActivity::class.java)).use {
            val device = UiDevice.getInstance(instrumentation)
            val record = device.wait(Until.findObject(By.descContains(id)), 20000)
            assertNotNull("Saved evidence must appear after restart", record)
            record.click()
            assertTrue(device.wait(Until.hasObject(By.desc("REVIEW REQUIRED")), 15000))
        }
    }
}
