package com.sih188.borderdoc.face

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

/**
 * FaceEmbeddingRunner
 * ===================
 * Loads the MobileFaceNet TFLite model from assets and runs inference
 * on a 112×112 RGB bitmap to produce a 128-dimensional face embedding.
 *
 * MODEL: MobileFaceNet
 *   License  : Apache 2.0 — free to redistribute inside an APK.
 *   Format   : TFLite FlatBuffer (.tflite)
 *   Input    : [1, 112, 112, 3] float32, normalised to [−1, 1]
 *   Output   : [1, 128] float32, L2-normalised embedding vector
 *   Size     : ~1.9 MB
 *   CPU time : ~15–30 ms on a mid-range Android device (Snapdragon 665)
 *
 * BUNDLING:
 *   The model ships inside assets/ml/mobilefacenet.tflite.
 *   aaptOptions { noCompress "tflite" } in build.gradle keeps it uncompressed
 *   so the Interpreter can mmap it directly without extracting to disk.
 *   Zero network calls are made at any point.
 *
 * PRIVACY:
 *   Embedding vectors are kept in-memory FloatArrays only and are discarded
 *   after the comparison is complete. They are never written to disk, logs,
 *   or any exported file.
 */
class FaceEmbeddingRunner(context: Context, modelAssetPath: String) {

    companion object {
        private const val INPUT_SIZE      = 112     // pixels per side
        private const val CHANNELS        = 3       // RGB
        private const val EMBEDDING_SIZE  = 128     // output vector dimension
        private const val BYTES_PER_FLOAT = 4
        // MobileFaceNet expects pixel values normalised to [−1, 1]
        private const val PIXEL_NORM_MEAN  = 127.5f
        private const val PIXEL_NORM_SCALE = 127.5f
    }

    private val interpreter: Interpreter

    init {
        val model = loadModelFromAssets(context, modelAssetPath)
        val options = Interpreter.Options().apply {
            setNumThreads(2)   // 2 threads is the sweet spot for MobileFaceNet on mobile
            setUseXNNPACK(true) // XNNPACK accelerates float32 ops on ARM — no extra lib
        }
        interpreter = Interpreter(model, options)
    }

    /**
     * Computes a 128-dimensional L2-normalised embedding for the given
     * [bitmap]. The bitmap MUST be exactly 112×112 ARGB_8888.
     *
     * @param bitmap  Aligned 112×112 face crop (from FaceAlignmentHelper).
     * @return        FloatArray(128) — L2-normalised embedding vector.
     */
    fun computeEmbedding(bitmap: Bitmap): FloatArray {
        val inputBuffer  = bitmapToInputBuffer(bitmap)
        val outputBuffer = Array(1) { FloatArray(EMBEDDING_SIZE) }

        interpreter.run(inputBuffer, outputBuffer)
        return outputBuffer[0]
    }

    /**
     * Releases the TFLite interpreter. Call when the module is no longer needed
     * (e.g. app goes to background for an extended period).
     */
    fun close() {
        interpreter.close()
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    /**
     * Memory-maps the TFLite model directly from the APK asset for efficient
     * loading without copying the full file into heap memory.
     */
    private fun loadModelFromAssets(context: Context, assetPath: String): MappedByteBuffer {
        val assetFileDescriptor = context.assets.openFd(assetPath)
        val fileInputStream     = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel         = fileInputStream.channel
        return fileChannel.map(
            FileChannel.MapMode.READ_ONLY,
            assetFileDescriptor.startOffset,
            assetFileDescriptor.declaredLength
        )
    }

    /**
     * Converts a 112×112 ARGB Bitmap to a [1, 112, 112, 3] float32 ByteBuffer
     * normalised to [−1, 1] as required by MobileFaceNet.
     *
     * Pixel layout: row-major, channel order R → G → B.
     */
    private fun bitmapToInputBuffer(bitmap: Bitmap): ByteBuffer {
        val buf = ByteBuffer.allocateDirect(
            1 * INPUT_SIZE * INPUT_SIZE * CHANNELS * BYTES_PER_FLOAT
        ).apply { order(ByteOrder.nativeOrder()) }

        val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
        bitmap.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        for (pixel in pixels) {
            val r = ((pixel shr 16) and 0xFF)
            val g = ((pixel shr  8) and 0xFF)
            val b = ( pixel         and 0xFF)
            buf.putFloat((r - PIXEL_NORM_MEAN) / PIXEL_NORM_SCALE)
            buf.putFloat((g - PIXEL_NORM_MEAN) / PIXEL_NORM_SCALE)
            buf.putFloat((b - PIXEL_NORM_MEAN) / PIXEL_NORM_SCALE)
        }

        buf.rewind()
        return buf
    }
}
