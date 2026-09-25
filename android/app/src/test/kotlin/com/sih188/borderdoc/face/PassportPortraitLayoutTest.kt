package com.sih188.borderdoc.face
import org.junit.Assert.*
import org.junit.Test
class PassportPortraitLayoutTest {
    private val labels=listOf(
        PassportPortraitLayout.Label("Republic of India",.3,.05,.7,.1),
        PassportPortraitLayout.Label("Passport No.",.7,.12,.9,.15),
        PassportPortraitLayout.Label("Surname",.35,.23,.5,.27),
        PassportPortraitLayout.Label("Given Names",.35,.33,.5,.37))
    private val main=doubleArrayOf(.08,.2,.3,.55)
    private val ghost=doubleArrayOf(.6,.15,.95,.65)
    @Test fun supportedAnchorsSelectMainEvenWhenSecondaryIsLarger() {
        assertEquals(0,PassportPortraitLayout.select(listOf(main,ghost),labels))
        assertEquals(1,PassportPortraitLayout.select(listOf(ghost,main),labels))
    }
    @Test fun singularGivenNameLabelUsesSameGeometryChecks() {
        val singular=labels.map { if(it.text=="Given Names") it.copy(text="Given Name") else it }
        assertEquals(0,PassportPortraitLayout.select(listOf(main,ghost),singular))
        assertThrows(CaptureRejected::class.java) { PassportPortraitLayout.select(listOf(main,main),singular) }
    }
    @Test fun unknownOrAmbiguousLayoutAbstains() {
        assertThrows(CaptureRejected::class.java) { PassportPortraitLayout.select(listOf(main,ghost),emptyList()) }
        assertThrows(CaptureRejected::class.java) { PassportPortraitLayout.select(listOf(main,main),labels) }
        assertThrows(CaptureRejected::class.java) { PassportPortraitLayout.select(listOf(ghost),labels) }
        assertThrows(CaptureRejected::class.java) { PassportPortraitLayout.select(listOf(main,ghost),labels+labels.last()) }
    }
}
