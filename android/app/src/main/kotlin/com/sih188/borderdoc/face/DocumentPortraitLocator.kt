package com.sih188.borderdoc.face

import android.graphics.Bitmap
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.util.concurrent.TimeUnit

/** Full image remains OCR input; only the chosen detected face goes to alignment. */
internal object DocumentPortraitLocator {
    fun select(image: Bitmap, faces: List<Face>, diagnostic: ((Map<String, Any>)->Unit)? = null): List<Face> {
        if(faces.size<=1) return faces
        val recognizer=TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        // Own this copy so a timeout cannot recycle an image still being read by OCR.
        val input=image.copy(Bitmap.Config.ARGB_8888,false) ?: throw CaptureRejected("IMAGE_UNREADABLE")
        var closeOnExit=true
        try {
            val task=recognizer.process(InputImage.fromBitmap(input,0))
            val text=try { Tasks.await(task,15,TimeUnit.SECONDS) }
            catch(e: java.util.concurrent.TimeoutException) {
                closeOnExit=false
                task.addOnCompleteListener(java.util.concurrent.Executor { it.run() }) { input.recycle(); recognizer.close() }
                throw e
            }
            val labels=text.textBlocks.flatMap { it.lines }.mapNotNull { line ->
                line.boundingBox?.let { b -> PassportPortraitLayout.Label(line.text,
                    b.left.toDouble()/image.width,b.top.toDouble()/image.height,
                    b.right.toDouble()/image.width,b.bottom.toDouble()/image.height) }
            }
            fun normalized(text: String)=text.uppercase(java.util.Locale.ROOT).replace(Regex("[^A-Z]"), "")
            val cues=listOf("REPUBLICOFINDIA","REPUBLIC","INDIA","PASSPORT","SURNAME","SUMAME","GIVENNAMES","GIVENNAME","GIVEN")
            diagnostic?.invoke(cues.associateWith { cue -> labels.count { normalized(it.text).contains(cue) } } + mapOf("lineCount" to labels.size, "faceCount" to faces.size))
            val boxes=faces.map { face -> face.boundingBox.let { b -> doubleArrayOf(
                b.left.toDouble()/image.width,b.top.toDouble()/image.height,
                b.right.toDouble()/image.width,b.bottom.toDouble()/image.height) } }
            return listOf(faces[PassportPortraitLayout.select(boxes,labels)])
        } finally { if(closeOnExit) { input.recycle(); recognizer.close() } }
    }
}
