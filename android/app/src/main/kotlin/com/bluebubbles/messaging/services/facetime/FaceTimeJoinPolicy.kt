package com.bluebubbles.messaging.services.facetime

internal enum class FaceTimeJoinOutcome {
    CLICKED,
    ALREADY_JOINED,
    MISSING,
    DISABLED,
    HIDDEN,
    UNKNOWN,
}

internal data class FaceTimeJoinDecision(
    val outcome: FaceTimeJoinOutcome,
    val joined: Boolean,
    val revealManualRecovery: Boolean,
    val retry: Boolean,
)

internal class FaceTimeJoinPolicy(
    private val manualRecoveryAttempt: Int = 20,
    private val maxAttempts: Int = 80,
) {
    var attempts: Int = 0
        private set

    var joined: Boolean = false
        private set

    fun record(rawResult: String?): FaceTimeJoinDecision {
        attempts += 1
        val outcome = parseOutcome(rawResult)
        if (outcome == FaceTimeJoinOutcome.CLICKED || outcome == FaceTimeJoinOutcome.ALREADY_JOINED) {
            joined = true
        }

        return FaceTimeJoinDecision(
            outcome = outcome,
            joined = joined,
            revealManualRecovery = joined || attempts >= manualRecoveryAttempt,
            retry = !joined && attempts < maxAttempts,
        )
    }

    companion object {
        fun parseOutcome(rawResult: String?): FaceTimeJoinOutcome {
            val normalized = rawResult
                ?.trim()
                ?.removeSurrounding("\"")
                ?.lowercase()

            return when (normalized) {
                "clicked" -> FaceTimeJoinOutcome.CLICKED
                "already-joined" -> FaceTimeJoinOutcome.ALREADY_JOINED
                "missing" -> FaceTimeJoinOutcome.MISSING
                "disabled" -> FaceTimeJoinOutcome.DISABLED
                "hidden" -> FaceTimeJoinOutcome.HIDDEN
                else -> FaceTimeJoinOutcome.UNKNOWN
            }
        }
    }
}
