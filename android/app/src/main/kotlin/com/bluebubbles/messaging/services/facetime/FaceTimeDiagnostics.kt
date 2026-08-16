package com.bluebubbles.messaging.services.facetime

import android.content.Context
import android.net.Uri

internal object FaceTimeDiagnostics {
    private const val preferencesName = "FlutterSharedPreferences"
    private const val developerModeKey = "flutter.developerEnabled"
    private const val diagnosticsKey = "flutter.faceTimeDiagnosticsEnabled"

    fun isEnabled(context: Context): Boolean {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        return shouldEnable(
            developerModeEnabled = preferences.getBoolean(developerModeKey, false),
            diagnosticsEnabled = preferences.getBoolean(diagnosticsKey, false),
        )
    }

    internal fun shouldEnable(
        developerModeEnabled: Boolean,
        diagnosticsEnabled: Boolean,
    ): Boolean = developerModeEnabled && diagnosticsEnabled

    internal fun safeResourceLabel(requestUrl: String?): String {
        if (requestUrl == null) return "unknown"
        return try {
            val uri = Uri.parse(requestUrl)
            val segment = uri.lastPathSegment.orEmpty()
            val resource = when {
                segment.endsWith(".js", ignoreCase = true) -> segment.substringAfterLast('/')
                segment.endsWith(".css", ignoreCase = true) -> segment.substringAfterLast('/')
                else -> "page-or-media"
            }
            "${uri.host ?: "unknown"}/$resource"
        } catch (_: Exception) {
            "unparseable"
        }
    }
}
