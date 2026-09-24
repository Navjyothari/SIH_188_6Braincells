package com.sih188.borderdoc.face

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface

/** Decode pixels and apply all eight JPEG EXIF orientations exactly once. */
internal object CaptureBitmapDecoder {
    fun decode(path: String): Bitmap? {
        val bitmap = BitmapFactory.decodeFile(path) ?: return null
        val orientation = try {
            ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1)
        } catch (_: java.io.IOException) { 1 }
        return orient(bitmap, orientation)
    }

    internal fun orient(bitmap: Bitmap, orientation: Int): Bitmap {
        val values = when (orientation) {
            2 -> floatArrayOf(-1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
            3 -> floatArrayOf(-1f, 0f, 0f, 0f, -1f, 0f, 0f, 0f, 1f)
            4 -> floatArrayOf(1f, 0f, 0f, 0f, -1f, 0f, 0f, 0f, 1f)
            5 -> floatArrayOf(0f, 1f, 0f, 1f, 0f, 0f, 0f, 0f, 1f)
            6 -> floatArrayOf(0f, -1f, 0f, 1f, 0f, 0f, 0f, 0f, 1f)
            7 -> floatArrayOf(0f, -1f, 0f, -1f, 0f, 0f, 0f, 0f, 1f)
            8 -> floatArrayOf(0f, 1f, 0f, -1f, 0f, 0f, 0f, 0f, 1f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height,
            Matrix().apply { setValues(values) }, true)
    }
}
