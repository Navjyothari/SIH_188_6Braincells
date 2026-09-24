package com.sih188.borderdoc.face

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PointF
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceLandmark

/** Align upright decoded images into a fixed output canvas, never a rebased full frame. */
class FaceAlignmentHelper {
    fun cropAndAlign(source: Bitmap, face: Face): Bitmap? {
        val first = face.getLandmark(FaceLandmark.LEFT_EYE)?.position ?: return null
        val second = face.getLandmark(FaceLandmark.RIGHT_EYE)?.position ?: return null
        return alignEyes(source, first, second)
    }

    internal fun alignEyes(source: Bitmap, first: PointF, second: PointF): Bitmap? {
        val eyes = listOf(first, second).sortedBy { it.x }
        val left = eyes[0]
        val right = eyes[1]
        if (eyes.any { !it.x.isFinite() || !it.y.isFinite() ||
                    it.x < 0 || it.y < 0 || it.x >= source.width || it.y >= source.height } ||
            right.x - left.x < 1f) return null
        // Use image-space ordering after EXIF normalization. Reversing the two
        // eye correspondences introduces a 180-degree rotation.
        val transform = Matrix()
        if (!transform.setPolyToPoly(
                floatArrayOf(left.x, left.y, right.x, right.y), 0,
                floatArrayOf(38.2946f, 51.6963f, 73.5318f, 51.5014f), 0, 2)) return null
        val output = Bitmap.createBitmap(112, 112, Bitmap.Config.ARGB_8888)
        // Bitmap.createBitmap(source, ..., matrix) rebases its bounds and loses
        // the translation. Drawing directly preserves the canonical positions.
        Canvas(output).drawBitmap(source, transform,
            Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
        return output
    }
}
