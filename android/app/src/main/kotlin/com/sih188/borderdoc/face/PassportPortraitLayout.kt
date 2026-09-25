package com.sih188.borderdoc.face

/** Conservative adapter for the observed Indian passport data-page layout; not document authentication. */
internal object PassportPortraitLayout {
    const val VERSION="single-face-or-indian-passport-ocr-anchors-v1"
    data class Label(val text: String, val left: Double, val top: Double, val right: Double, val bottom: Double)
    fun select(boxes: List<DoubleArray>, labels: List<Label>): Int {
        fun cleaned(text: String)=text.uppercase(java.util.Locale.ROOT).replace(Regex("[^A-Z]"), "")
        val header=labels.filter { cleaned(it.text).contains("REPUBLICOFINDIA") }
        val passport=labels.any { cleaned(it.text).contains("PASSPORT") }
        val surname=labels.filter { cleaned(it.text).contains("SURNAME") }
        val given=labels.filter { cleaned(it.text).contains("GIVENNAME") }
        if(header.size!=1 || !passport || surname.size!=1 || given.size!=1)
            throw CaptureRejected("PORTRAIT_LAYOUT_UNSUPPORTED")
        val a=surname.single(); val b=given.single(); val h=header.single()
        if(a.top<=h.top || b.top<=a.top || kotlin.math.abs(a.left-b.left)>0.1)
            throw CaptureRejected("PORTRAIT_LAYOUT_UNSUPPORTED")
        val fieldLeft=minOf(a.left,b.left)
        val candidates=boxes.indices.filter { i ->
            val face=boxes[i]
            face.size==4 && face.all { it.isFinite() && it in 0.0..1.0 } &&
                face[0]<face[2] && face[1]<face[3] &&
                face[2]<fieldLeft && face[1]>h.bottom && face[3]>b.top && face[1]<b.bottom
        }
        if(candidates.size!=1) throw CaptureRejected("PORTRAIT_LAYOUT_AMBIGUOUS")
        return candidates.single()
    }
}
