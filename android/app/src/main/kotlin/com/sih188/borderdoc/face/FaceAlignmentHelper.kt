package com.sih188.borderdoc.face

import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.PointF
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceLandmark
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * FaceAlignmentHelper
 * ===================
 * Crops and affine-aligns a detected face to a canonical 112×112 patch.
 *
 * Algorithm:
 *   1. Read the left-eye and right-eye landmark centres from ML Kit.
 *   2. Compute the roll angle (eye-line angle relative to horizontal).
 *   3. Build an affine transform: rotate to zero roll, then scale/translate
 *      so the eye centres land at the canonical positions used by MobileFaceNet
 *      (approximately (38.29, 51.69) and (73.53, 51.50) in a 112×112 frame).
 *   4. Apply the transform via Android's Matrix API (no native code).
 *   5. Crop to 112×112 for embedding input.
 *
 * If landmarks are unavailable (rare with LANDMARK_MODE_ALL), falls back to
 * a simple bounding-box crop padded by 20 %.
 *
 * OUTPUT: 112×112 ARGB_8888 Bitmap — does NOT escape to disk or logs.
 */
class FaceAlignmentHelper {

    companion object {
        // Canonical eye positions for MobileFaceNet 112×112 input
        // Source: ArcFace alignment standard (CVPR 2019 supplementary)
        private val CANONICAL_LEFT_EYE  = PointF(38.2946f, 51.6963f)
        private val CANONICAL_RIGHT_EYE = PointF(73.5318f, 51.5014f)
        private const val OUTPUT_SIZE = 112
        private const val BBOX_PAD_RATIO = 0.20f  // 20 % padding on fallback crop
    }

    /**
     * Crops and aligns the face region from [source] using ML Kit's [face] metadata.
     *
     * @param source  Original full-frame bitmap.
     * @param face    ML Kit Face object with bounding box and landmarks.
     * @return        112×112 aligned crop, or a padded bounding-box crop if
     *                landmarks are unavailable.
     */
    fun cropAndAlign(source: Bitmap, face: Face): Bitmap {
        // ML Kit uses subject-centric labels.
        // FaceLandmark.LEFT_EYE is the subject's left eye (appears on viewer's right).
        // Our affineAlignedCrop expects (viewerLeft, viewerRight).
        val subjectLeftEyeLm  = face.getLandmark(FaceLandmark.LEFT_EYE)
        val subjectRightEyeLm = face.getLandmark(FaceLandmark.RIGHT_EYE)

        return if (subjectLeftEyeLm != null && subjectRightEyeLm != null) {
            affineAlignedCrop(
                source, 
                subjectRightEyeLm.position, // Viewer's left
                subjectLeftEyeLm.position   // Viewer's right
            )
        } else {
            bboxFallbackCrop(source, face)
        }
    }

    // -----------------------------------------------------------------------
    // Private: landmark-based affine alignment
    // -----------------------------------------------------------------------

    private fun affineAlignedCrop(
        source:    Bitmap,
        leftEye:   PointF,
        rightEye:  PointF
    ): Bitmap {
        // 1. Compute rotation angle to level the eye line
        val dx    = rightEye.x - leftEye.x
        val dy    = rightEye.y - leftEye.y
        val angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()

        // 2. Compute scale: ratio of canonical eye distance to actual eye distance
        val actualDist    = sqrt((dx * dx + dy * dy).toDouble()).toFloat()
        val canonicalDist = sqrt(
            ((CANONICAL_RIGHT_EYE.x - CANONICAL_LEFT_EYE.x).let { it * it } +
             (CANONICAL_RIGHT_EYE.y - CANONICAL_LEFT_EYE.y).let { it * it }).toDouble()
        ).toFloat()
        val scale = if (actualDist > 0f) canonicalDist / actualDist else 1f

        // 3. Build transform: rotate around the left-eye point, then translate
        val matrix = Matrix()
        // Step A: rotate around the source left-eye centre (keeps leftEye at leftEye)
        matrix.postRotate(-angle, leftEye.x, leftEye.y)
        // Step B: scale relative to the origin (moves leftEye to leftEye * scale)
        matrix.postScale(scale, scale)
        // Step C: translate so the scaled left-eye lands on canonical position
        val tx = CANONICAL_LEFT_EYE.x - leftEye.x * scale
        val ty = CANONICAL_LEFT_EYE.y - leftEye.y * scale
        matrix.postTranslate(tx, ty)

        // 4. Create full transformed bitmap, then crop to OUTPUT_SIZE × OUTPUT_SIZE
        val transformed = Bitmap.createBitmap(
            source, 0, 0, source.width, source.height, matrix, true
        )
        return Bitmap.createBitmap(transformed, 0, 0,
            minOf(OUTPUT_SIZE, transformed.width),
            minOf(OUTPUT_SIZE, transformed.height)
        ).let {
            if (it.width == OUTPUT_SIZE && it.height == OUTPUT_SIZE) it
            else Bitmap.createScaledBitmap(it, OUTPUT_SIZE, OUTPUT_SIZE, true)
        }
    }

    // -----------------------------------------------------------------------
    // Private: simple padded bounding-box fallback
    // -----------------------------------------------------------------------

    private fun bboxFallbackCrop(source: Bitmap, face: Face): Bitmap {
        val box = face.boundingBox
        val padW = (box.width()  * BBOX_PAD_RATIO).toInt()
        val padH = (box.height() * BBOX_PAD_RATIO).toInt()

        val left   = (box.left   - padW).coerceAtLeast(0)
        val top    = (box.top    - padH).coerceAtLeast(0)
        val right  = (box.right  + padW).coerceAtMost(source.width)
        val bottom = (box.bottom + padH).coerceAtMost(source.height)

        val crop = Bitmap.createBitmap(source, left, top, right - left, bottom - top)
        return Bitmap.createScaledBitmap(crop, OUTPUT_SIZE, OUTPUT_SIZE, true)
    }
}
