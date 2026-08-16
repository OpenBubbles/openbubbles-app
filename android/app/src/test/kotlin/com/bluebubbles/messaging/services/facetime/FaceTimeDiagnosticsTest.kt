package com.bluebubbles.messaging.services.facetime

import org.junit.Assert.assertFalse
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FaceTimeDiagnosticsTest {
    @Test
    fun diagnosticsRequireDeveloperModeAndExplicitOptIn() {
        assertFalse(FaceTimeDiagnostics.shouldEnable(false, false))
        assertFalse(FaceTimeDiagnostics.shouldEnable(false, true))
        assertFalse(FaceTimeDiagnostics.shouldEnable(true, false))
        assertTrue(FaceTimeDiagnostics.shouldEnable(true, true))
    }

    @Test
    fun resourceLabelsOmitQueryAndPageDetails() {
        assertEquals("example.com/main.js", FaceTimeDiagnostics.safeResourceLabel("https://example.com/assets/main.js?token=secret#fragment"))
        assertEquals("example.com/page-or-media", FaceTimeDiagnostics.safeResourceLabel("https://example.com/call/private-room?token=secret"))
    }
}
