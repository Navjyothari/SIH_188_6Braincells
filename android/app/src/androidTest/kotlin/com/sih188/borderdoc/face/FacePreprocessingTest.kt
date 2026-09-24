package com.sih188.borderdoc.face

import android.graphics.*
import android.media.ExifInterface
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class FacePreprocessingTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @Test fun translatedScaledRolledAndReversedEyesStayUpright() {
        for (angle in listOf(-30f, 0f, 30f)) for (scale in listOf(1f, 3f)) {
            val source = Bitmap.createBitmap(1000, 1000, Bitmap.Config.ARGB_8888)
            val transform = Matrix().apply {
                postScale(scale, scale)
                postRotate(angle)
                postTranslate(450f, 350f)
            }
            val points = floatArrayOf(38.2946f,51.6963f,73.5318f,51.5014f,56f,80f)
            transform.mapPoints(points)
            Canvas(source).apply {
                drawColor(Color.BLACK)
                val colors = listOf(Color.RED, Color.GREEN, Color.BLUE)
                for (i in 0..2) drawCircle(points[2*i], points[2*i+1], 6f*scale,
                    Paint().apply { color=colors[i] })
            }
            val a = PointF(points[0],points[1]); val b = PointF(points[2],points[3])
            for ((first,second) in listOf(a to b,b to a)) {
                val crop = FaceAlignmentHelper().alignEyes(source,first,second)!!
                assertEquals("left eye angle=$angle scale=$scale",Color.RED,crop.getPixel(38,52))
                assertEquals("right eye",Color.GREEN,crop.getPixel(74,52))
                assertEquals("lower face stays below eyes",Color.BLUE,crop.getPixel(56,80))
                assertEquals(112,crop.width); assertEquals(112,crop.height)
            }
        }
    }

    @Test fun invalidLandmarksAbstain() {
        val source = Bitmap.createBitmap(200,200,Bitmap.Config.ARGB_8888)
        val helper=FaceAlignmentHelper()
        assertNull(helper.alignEyes(source,PointF(30f,30f),PointF(30f,30f)))
        assertNull(helper.alignEyes(source,PointF(Float.NaN,30f),PointF(80f,30f)))
        assertNull(helper.alignEyes(source,PointF(-1f,30f),PointF(80f,30f)))
    }

    @Test fun allEightExifOrientationsDecodeCorrectly() {
        val source=Bitmap.createBitmap(80,60,Bitmap.Config.ARGB_8888)
        Canvas(source).apply {
            val paint=Paint()
            for ((rect,color) in listOf(
                Rect(0,0,40,30) to Color.RED,Rect(40,0,80,30) to Color.GREEN,
                Rect(0,30,40,60) to Color.BLUE,Rect(40,30,80,60) to Color.YELLOW)) {
                paint.color=color; drawRect(rect,paint)
            }
        }
        val expected=listOf(
            listOf(Color.RED,Color.GREEN,Color.BLUE,Color.YELLOW),
            listOf(Color.GREEN,Color.RED,Color.YELLOW,Color.BLUE),
            listOf(Color.YELLOW,Color.BLUE,Color.GREEN,Color.RED),
            listOf(Color.BLUE,Color.YELLOW,Color.RED,Color.GREEN),
            listOf(Color.RED,Color.BLUE,Color.GREEN,Color.YELLOW),
            listOf(Color.BLUE,Color.RED,Color.YELLOW,Color.GREEN),
            listOf(Color.YELLOW,Color.GREEN,Color.BLUE,Color.RED),
            listOf(Color.GREEN,Color.YELLOW,Color.RED,Color.BLUE))
        for (orientation in 1..8) {
            val file=File.createTempFile("synthetic-exif-", ".jpg",context.cacheDir)
            try {
                file.outputStream().use { source.compress(Bitmap.CompressFormat.JPEG,100,it) }
                ExifInterface(file.path).apply {
                    setAttribute(ExifInterface.TAG_ORIENTATION,orientation.toString()); saveAttributes()
                }
                val result=CaptureBitmapDecoder.decode(file.path)!!
                assertEquals(if(orientation>=5)60 else 80,result.width)
                val coords=listOf(0.25f to 0.25f,0.75f to 0.25f,0.25f to 0.75f,0.75f to 0.75f)
                for ((i,xy) in coords.withIndex()) {
                    val actual=result.getPixel((xy.first*result.width).toInt(),(xy.second*result.height).toInt())
                    val want=expected[orientation-1][i]
                    assertTrue("EXIF $orientation corner $i",
                        kotlin.math.abs(Color.red(actual)-Color.red(want))<10 &&
                        kotlin.math.abs(Color.green(actual)-Color.green(want))<10 &&
                        kotlin.math.abs(Color.blue(actual)-Color.blue(want))<10)
                }
            } finally { file.delete() }
        }
    }

    @Test fun actualDetectorAndBundledModelComparePortraitAcrossCanvasOffsets() {
        val portrait=context.assets.open("ml/synthetic_reference_face.jpg").use {
            BitmapFactory.decodeStream(it)
        }
        val canvasImage=Bitmap.createBitmap(900,1000,Bitmap.Config.ARGB_8888)
        Canvas(canvasImage).apply {
            drawColor(Color.WHITE)
            drawBitmap(portrait,180f,220f,null)
        }
        val testCache=File(context.cacheDir,"synthetic-alignment-test-${System.nanoTime()}")
        check(testCache.mkdir())
        val testContext=object : android.content.ContextWrapper(context) {
            override fun getCacheDir() = testCache
        }
        try {
            val result=FaceVerificationModule(testContext).verifyFace(canvasImage,portrait)
            assertEquals(result.debugInfo,"MATCH",result.status)
            assertTrue(result.similarityScore!! >= 0.75f)
            println("Synthetic offset comparison score: ${result.similarityScore}")
        } finally {
            File(testCache,"debug_live_crop.jpg").delete()
            File(testCache,"debug_ref_crop.jpg").delete()
            testCache.delete()
        }
    }
}
