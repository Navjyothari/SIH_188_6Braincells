package com.sih188.borderdoc.face

import android.graphics.Bitmap
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceLandmark
import kotlin.math.abs

internal class CaptureRejected(val reason: String) : Exception()

/** Engineering defaults only. A release must evaluate and freeze this entire policy. */
internal object FaceQualityGate {
    const val VERSION="quality-provisional-v1"
    private val region=IntArray(72*64) { index -> (24+index/64)*112+24+index%64 }
    fun tensor(bitmap: Bitmap, faces: List<Face>, document: Boolean, detectionWidth: Int = bitmap.width, detectionHeight: Int = bitmap.height): FloatArray {
        require(detectionWidth in 1..bitmap.width && detectionHeight in 1..bitmap.height)
        val sx=bitmap.width.toDouble()/detectionWidth
        val sy=bitmap.height.toDouble()/detectionHeight
        if(faces.size!=1) throw CaptureRejected(if(faces.isEmpty()) "NO_FACE" else "MULTIPLE_FACES")
        val face=faces.single(); val box=face.boundingBox
        val minSize=if(document) 80 else 112
        if(box.width()*sx<minSize || box.height()*sy<minSize) throw CaptureRejected("FACE_TOO_SMALL")
        if(box.left<0 || box.top<0 || box.right>detectionWidth || box.bottom>detectionHeight) throw CaptureRejected("FACE_CLIPPED")
        if(!face.headEulerAngleX.isFinite() || !face.headEulerAngleY.isFinite() || !face.headEulerAngleZ.isFinite()) throw CaptureRejected("POSE")
        if(abs(face.headEulerAngleY)>20 || abs(face.headEulerAngleX)>20 || abs(face.headEulerAngleZ)>25) throw CaptureRejected("POSE")
        fun point(type: Int)=face.getLandmark(type)?.position ?: throw CaptureRejected("LANDMARKS_MISSING")
        val eyes=listOf(point(FaceLandmark.LEFT_EYE),point(FaceLandmark.RIGHT_EYE)).sortedBy { it.x }
        val mouth=listOf(point(FaceLandmark.MOUTH_LEFT),point(FaceLandmark.MOUTH_RIGHT)).sortedBy { it.x }
        val points=(eyes+listOf(point(FaceLandmark.NOSE_BASE))+mouth).flatMap { listOf(it.x.toDouble()*sx,it.y.toDouble()*sy) }.toDoubleArray()
        val pixels=IntArray(bitmap.width*bitmap.height)
        bitmap.getPixels(pixels,0,bitmap.width,0,0,bitmap.width,bitmap.height)
        val aligned=try { EdgeFaceMath.alignedTensor(pixels,bitmap.width,bitmap.height,points) }
            catch(e: IllegalArgumentException) { throw CaptureRejected("ALIGNMENT") }
        // Measure only central facial pixels, avoiding document paper and crop borders.
        val luminance=DoubleArray(112*112) { i ->
            ((aligned[i]+1)*0.299+(aligned[12544+i]+1)*0.587+(aligned[25088+i]+1)*0.114)*127.5
        }
        val mean=region.sumOf { luminance[it] }/region.size
        val clipped=region.count { luminance[it]>=250 }/region.size.toDouble()
        if(mean<35 || mean>225) throw CaptureRejected("EXPOSURE")
        if(clipped > if(document) 0.08 else 0.15) throw CaptureRejected(if(document) "DOCUMENT_GLARE" else "EXPOSURE")
        val lap=region.map { i -> 4*luminance[i]-luminance[i-1]-luminance[i+1]-luminance[i-112]-luminance[i+112] }
        val average=lap.average(); val variance=lap.sumOf { (it-average)*(it-average) }/lap.size
        if(variance<20) throw CaptureRejected("BLUR")
        return aligned
    }
}
