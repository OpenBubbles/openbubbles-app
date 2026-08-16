package com.bluebubbles.messaging.services.facetime

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FaceTimeJoinPolicyTest {
    @Test
    fun clickedStopsRetryAndRevealsCall() {
        val decision = FaceTimeJoinPolicy().record("\"clicked\"")

        assertEquals(FaceTimeJoinOutcome.CLICKED, decision.outcome)
        assertTrue(decision.joined)
        assertTrue(decision.revealManualRecovery)
        assertFalse(decision.retry)
    }

    @Test
    fun alreadyJoinedIsIdempotent() {
        val decision = FaceTimeJoinPolicy().record("\"already-joined\"")

        assertTrue(decision.joined)
        assertFalse(decision.retry)
    }

    @Test
    fun manualRecoveryAppearsWhileRetriesContinue() {
        val policy = FaceTimeJoinPolicy(manualRecoveryAttempt = 2, maxAttempts = 4)

        val first = policy.record("\"missing\"")
        val second = policy.record("\"hidden\"")

        assertFalse(first.revealManualRecovery)
        assertTrue(first.retry)
        assertTrue(second.revealManualRecovery)
        assertTrue(second.retry)
    }

    @Test
    fun retriesEventuallyStop() {
        val policy = FaceTimeJoinPolicy(manualRecoveryAttempt = 1, maxAttempts = 2)

        policy.record("\"disabled\"")
        val finalDecision = policy.record(null)

        assertEquals(FaceTimeJoinOutcome.UNKNOWN, finalDecision.outcome)
        assertTrue(finalDecision.revealManualRecovery)
        assertFalse(finalDecision.retry)
    }
}
