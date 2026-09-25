package com.sih188.borderdoc.face

import kotlin.math.*

/** Pure numerical code shared by production and regression tests. */
internal object EdgeFaceMath {
    const val ALIGNMENT_VERSION = "five-point-similarity-bilinear-v1"
    val template = doubleArrayOf(38.2946,51.6963,73.5318,51.5014,56.0252,71.7366,41.5493,92.3655,70.7299,92.2041)

    // [a,-b,tx; b,a,ty], minimizing all five point residuals without reflection.
    fun fit(source: DoubleArray, target: DoubleArray = template): DoubleArray {
        require(source.size == 10 && target.size == 10)
        require(source.all { it.isFinite() } && target.all { it.isFinite() })
        val sx = (0..4).sumOf { source[it*2] } / 5
        val sy = (0..4).sumOf { source[it*2+1] } / 5
        val dx = (0..4).sumOf { target[it*2] } / 5
        val dy = (0..4).sumOf { target[it*2+1] } / 5
        var variance=0.0; var aa=0.0; var bb=0.0
        for (i in 0..4) {
            val x=source[i*2]-sx; val y=source[i*2+1]-sy
            val u=target[i*2]-dx; val v=target[i*2+1]-dy
            variance+=x*x+y*y; aa+=x*u+y*v; bb+=x*v-y*u
        }
        require(variance > 1e-8)
        val a=aa/variance; val b=bb/variance
        require(a*a+b*b > 1e-12)
        return doubleArrayOf(a,b,dx-a*sx+b*sy,dy-b*sx-a*sy)
    }

    /** Returns planar RGB [-1,1]. Black border, integer-centered bilinear samples. */
    fun alignedTensor(pixels: IntArray, width: Int, height: Int, points: DoubleArray): FloatArray {
        require(width > 0 && height > 0 && pixels.size == width*height)
        require(points.size == 10 && points.indices.all {
            points[it].isFinite() && points[it] >= 0 && points[it] < if(it%2==0) width else height
        })
        val m=fit(points); val a=m[0]; val b=m[1]; val det=a*a+b*b
        val output=FloatArray(3*112*112)
        fun pixel(x: Int,y: Int): Int =
            if(x in 0 until width && y in 0 until height) pixels[y*width+x] else 0
        for(y in 0 until 112) for(x in 0 until 112) {
            val xx=x-m[2]; val yy=y-m[3]
            val sx=(a*xx+b*yy)/det; val sy=(-b*xx+a*yy)/det
            val ix=floor(sx).toInt(); val iy=floor(sy).toInt(); val fx=sx-ix; val fy=sy-iy
            val p00=pixel(ix,iy); val p10=pixel(ix+1,iy)
            val p01=pixel(ix,iy+1); val p11=pixel(ix+1,iy+1)
            for(c in 0..2) {
                val shift=16-c*8
                val value=((p00 ushr shift) and 255).toDouble()*(1-fx)*(1-fy)+((p10 ushr shift) and 255).toDouble()*fx*(1-fy)+
                    ((p01 ushr shift) and 255).toDouble()*(1-fx)*fy+((p11 ushr shift) and 255).toDouble()*fx*fy
                output[c*112*112+y*112+x]=(value/127.5-1.0).toFloat()
            }
        }
        return output
    }

    fun normalized(values: FloatArray): FloatArray {
        require(values.isNotEmpty() && values.all { it.isFinite() })
        val norm=sqrt(values.sumOf { it.toDouble()*it })
        require(norm.isFinite() && norm > 1e-12)
        return FloatArray(values.size) { (values[it]/norm).toFloat() }
    }
    fun cosine(a: FloatArray,b: FloatArray): Float {
        require(a.size==b.size)
        val na=normalized(a); val nb=normalized(b)
        return na.indices.sumOf { na[it].toDouble()*nb[it] }.coerceIn(-1.0,1.0).toFloat()
    }
    fun median(scores: List<Float>): Float {
        require(scores.isNotEmpty() && scores.all { it.isFinite() && it in -1f..1f })
        val s=scores.sorted(); val middle=s.size/2
        return if(s.size%2==1) s[middle] else (s[middle-1]+s[middle])/2
    }
}

internal data class DecisionPolicy(val modelHash: String, val alignment: String,
    val version: String, val noMatch: Float, val match: Float, val approved: Boolean) {
    fun classify(score: Float, actualHash: String): String {
        require(score.isFinite() && score in -1f..1f)
        require(approved && modelHash==actualHash && alignment==EdgeFaceMath.ALIGNMENT_VERSION && version.isNotBlank())
        require(noMatch.isFinite() && match.isFinite() && noMatch >= -1f && match <= 1f && noMatch < match)
        return when { score>=match -> "MATCH"; score<noMatch -> "NO_MATCH"; else -> "UNCERTAIN" }
    }
}
