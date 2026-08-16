package com.bluebubbles.messaging.services.facetime

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.database.ContentObserver
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Rect
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Rational
import android.view.View
import android.view.ViewGroup.MarginLayoutParams
import android.view.WindowInsets
import android.view.WindowManager
import android.webkit.PermissionRequest
import android.webkit.WebView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.marginTop
import androidx.core.view.updateLayoutParams
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.R
import com.bluebubbles.messaging.databinding.ActivityFaceTimeBinding
import com.bluebubbles.messaging.services.notifications.CreateIncomingFaceTimeNotification
import com.bluebubbles.messaging.services.notifications.DeleteNotificationHandler
import com.bluebubbles.messaging.services.rustpush.APNClient
import com.bluebubbles.messaging.services.rustpush.APNService
import com.bluebubbles.messaging.utils.getStreamMinVolumeCompat
import com.google.android.material.math.MathUtils
import kotlin.math.roundToInt

class FaceTimeActivity : Activity() {
    private lateinit var binding: ActivityFaceTimeBinding

    private var permissionRequests = ArrayList<PermissionRequest>()
    private val permissionMap = mapOf(
        PermissionRequest.RESOURCE_VIDEO_CAPTURE to listOf(Manifest.permission.CAMERA),
        PermissionRequest.RESOURCE_AUDIO_CAPTURE to listOf(Manifest.permission.RECORD_AUDIO),
    )
    var isCall = false
    var answered = false
    private var mirrorReady = false
    private var notificationId = 0
    var callUuid: String? = null
    private lateinit var cached: CachedWebview

    private lateinit var webView: WebView
    private var initialMediaVolume: Int? = null;

    private fun diagnosticsEnabled(): Boolean = FaceTimeDiagnostics.isEnabled(this)

    companion object {
        var activeFaceTimeActivity: FaceTimeActivity? = null
        var cachedWebview: CachedWebview? = null
    }

    fun endCall() {
        webView.loadUrl("javascript:document.getElementById(\"callcontrols-leave-button-session-banner\").click()")
    }

    private fun hideControlsForPIP() {
        webView.loadUrl("javascript:if (document.querySelector(\".session-banner\").style.opacity == 1) { document.getElementById(\"canvas-layout-container\").click() }")
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (isInPictureInPictureMode) {
            hideControlsForPIP()
        }
    }

    private fun decline() {
        // delete notification
        if (notificationId != 0) {
            DeleteNotificationHandler().deleteNotification(this, notificationId, Constants.newFaceTimeNotificationTag)
        }
        callUuid?.let { callUuid ->
            val client = APNClient(applicationContext)
            client.bind { service: APNService ->
                try {
                    service.pushState?.declineFacetime(callUuid)
                } finally {
                    client.destroy()
                }
            }
        }
        finishAndRemoveTask()
    }

    private fun invLerp(a: Int, b: Int, x: Int): Float {
        return (x - a).toFloat() / (b - a).toFloat()
    }

    private fun updateMediaVolume(audioManager: AudioManager) {
        try {
            val progress = invLerp(
                audioManager.getStreamMinVolumeCompat(AudioManager.STREAM_VOICE_CALL),
                audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL),
                audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL),
            )
            val volume = MathUtils.lerp(
                audioManager.getStreamMinVolumeCompat(AudioManager.STREAM_MUSIC).toFloat(),
                audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toFloat(),
                progress
            ).roundToInt()
            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                volume,
                0
            )
        } catch (e: SecurityException) {
            Log.w("FaceTime", "Unable to set stream volume!")
        }

    }

    var contentObserver: ContentObserver? = null

    private fun handlePermissionRequests() {
        for (request in cached.deferredRequests) {
            handlePermissionRequest(request)
        }
        cached.deferredRequests.clear()
        cached.deferredRequestsUpdated = {
            for (request in cached.deferredRequests) {
                handlePermissionRequest(request)
            }
            cached.deferredRequests.clear()
        }

        // weird bug where it uses the Music stream but the default stream is set to call
        // you want it maxed. Trust me. And if you don't the UI will open so you know :)
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        initialMediaVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        updateMediaVolume(audioManager)
        val observer = object : ContentObserver(
            Handler(Looper.getMainLooper())
        ) {
            override fun deliverSelfNotifications(): Boolean {
                return false
            }

            override fun onChange(selfChange: Boolean) {
                updateMediaVolume(audioManager)
            }
        }
        applicationContext.contentResolver.registerContentObserver(android.provider.Settings.System.CONTENT_URI, true, observer)
        contentObserver = observer
    }

    private fun answerCall() {
        answered = true

        if (diagnosticsEnabled()) Log.i("FaceTimeDiag", "answer requested mirrorReady=$mirrorReady deferredPermissions=${cached.deferredRequests.size}")

        handlePermissionRequests()

        if (notificationId != 0) {
            DeleteNotificationHandler().deleteNotification(this, notificationId, Constants.newFaceTimeNotificationTag)
        }

        if (mirrorReady) {
            binding.mainFrame.visibility = View.VISIBLE
            binding.splashLayout.visibility = View.GONE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                window.setBackgroundBlurRadius(0)
            }
            webView.loadUrl("javascript:document.getElementById(\"callcontrols-join-button-session-banner\").click()")
        } else {
            connecting()
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityFaceTimeBinding.inflate(layoutInflater)

        activeFaceTimeActivity = this

        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        WindowCompat.setDecorFitsSystemWindows(window, false)


        // show when locked
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                        or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        handleConfig(intent.extras!!)
        binding.mainFrame.addView(webView)

        binding.accept.setOnClickListener {
            answerCall()
        }

        binding.reject.setOnClickListener {
            decline()
        }



        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val sourceRectHint = Rect()
            webView.getGlobalVisibleRect(sourceRectHint)

            val intentWithData = Intent(
                this,
                FaceTimeActionReceiver::class.java
            )

            setPictureInPictureParams(
                PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(1, 1))
                    .setActions(listOf(
                        RemoteAction(
                            Icon.createWithResource(this, R.drawable.call_end),
                            "End Call",
                            "End this FaceTime Call",
                            PendingIntent.getBroadcast(this, 1, intentWithData,
                                PendingIntent.FLAG_IMMUTABLE)
                        )
                    ))
                    .setSourceRectHint(sourceRectHint)
                    .setAutoEnterEnabled(true)
                    .build())

            val mOnLayoutChangeListener =
                View.OnLayoutChangeListener { v: View?, oldLeft: Int,
                                              oldTop: Int, oldRight: Int, oldBottom: Int, newLeft: Int, newTop:
                                              Int, newRight: Int, newBottom: Int ->
                    val sourceRectHint = Rect()
                    webView.getGlobalVisibleRect(sourceRectHint)
                    val builder = PictureInPictureParams.Builder()
                        .setSourceRectHint(sourceRectHint)
                    setPictureInPictureParams(builder.build())
                }

            webView.addOnLayoutChangeListener(mOnLayoutChangeListener)
        }

        val view = binding.root
        setContentView(view)
    }

    var serviceStarted: Boolean = false

    fun startService() {
        if (serviceStarted) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(this, FaceTimeInCallService::class.java)
            startForegroundService(intent)
        }
        serviceStarted = true
    }

    fun handlePermissionRequest(request: PermissionRequest) {
        val permissions = request.resources.flatMap { i -> permissionMap[i] ?: listOf() }
        if (diagnosticsEnabled()) Log.i("FaceTimeDiag", "handling WebView permission resources=${request.resources.sorted().joinToString()} androidPermissions=${permissions.joinToString()} alreadyGranted=${permissions.all { checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }}")
        if (permissions.all { checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }) {
            request.grant(request.resources)
            startService()
            return
        }
        permissionRequests.add(request)
        requestPermissions(permissions.toTypedArray(), 1)
    }

    override fun onDestroy() {
        webView.destroy()
        activeFaceTimeActivity = null

        val intent = Intent(this, FaceTimeInCallService::class.java)
        stopService(intent)
        serviceStarted = false

        // restore default media volume
        initialMediaVolume?.let {
            try {
                val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                audioManager.setStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    it,
                    0
                )
            } catch (e: SecurityException) {
                Log.w("FaceTime", "Unable to set stream volume!")
            }
        }

        contentObserver?.let {
            applicationContext.contentResolver.unregisterContentObserver(it)
        }

        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode != 1) return
        if (diagnosticsEnabled()) {
            val permissionResults = permissions.zip(grantResults.toTypedArray()).joinToString { (permission, result) -> "$permission=${result == PackageManager.PERMISSION_GRANTED}" }
            Log.i("FaceTimeDiag", "Android permission result $permissionResults")
        }
        for (request in permissionRequests) {
            request.grant(request.resources.filter { i ->
                (permissionMap[i] ?: listOf()).all {
                    val permissionIdx = permissions.indexOf(it)
                    grantResults[permissionIdx] == PackageManager.PERMISSION_GRANTED
                }
            }.toTypedArray())
        }
        permissionRequests = arrayListOf()
        startService()
    }

    private fun connecting() {
        if (diagnosticsEnabled()) Log.i("FaceTimeDiag", "waiting for mirrorReady")
        binding.acceptButtons.visibility = View.GONE
        binding.loadingBanner.text = "Connecting..."
        Handler(Looper.getMainLooper()).postDelayed({
            binding.mainFrame.visibility = View.VISIBLE
            binding.splashLayout.visibility = View.GONE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                window.setBackgroundBlurRadius(0)
            }
        }, 15000)
    }

    private fun handleConfig(extras: Bundle) {
        val link = extras.getString("link")!!
        val name = extras.getString("name")
        // sanitize desc
        val desc = extras.getString("desc")?.replace("[^a-zA-Z0-9, +.@:&]+".toRegex(), "") ?: "FaceTime Call"
        if (cachedWebview != null) {
            // take control of a pre-rendered webview
            cached = cachedWebview!!
            cachedWebview = null
        } else {
            cached = CachedWebview(this, name, desc, link)
        }

        cached.endTask = {
            finishAndRemoveTask()
        }
        mirrorReady = cached.mirrorReady
        cached.mirrorReadyCall = {
            mirrorReady = true
            if (diagnosticsEnabled()) Log.i("FaceTimeDiag", "mirrorReady callback answered=$answered")
            if (answered) {
                binding.mainFrame.visibility = View.VISIBLE
                binding.splashLayout.visibility = View.GONE
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    window.setBackgroundBlurRadius(0)
                }
                webView.loadUrl("javascript:document.getElementById(\"callcontrols-join-button-session-banner\").click()")
            }
        }

        webView = cached.webView

        val isAnsweringCall = extras.containsKey("answer")
        notificationId = extras.getString("notificationId")?.toInt() ?: 0
        callUuid = extras.getString("callUuid")

        if (CreateIncomingFaceTimeNotification.avatarCache.containsKey(callUuid)) {
            val bitmap = CreateIncomingFaceTimeNotification.avatarCache.remove(callUuid)!!
            binding.avatarView.setImageBitmap(bitmap)
        }

        if (diagnosticsEnabled()) Log.i("FaceTimeDiag", "started activity hasCallUuid=${callUuid != null}")

        val poster = extras.getString("poster")
        if (poster != null) {
            binding.posterView.setImageBitmap(BitmapFactory.decodeFile(poster))
            binding.callDescription.visibility = View.GONE
            // no background blur because we are occluded
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                window.setBackgroundBlurRadius(0)
            }
        } else {
            binding.posterView.visibility = View.GONE
        }

        if (isAnsweringCall) {
            isCall = true
            binding.callTitle.text = desc
            binding.splashLayout.visibility = View.VISIBLE
            if (extras.getBoolean("answer")) {
                answerCall()
            }
        } else {
            binding.splashLayout.visibility = View.GONE
            binding.mainFrame.visibility = View.VISIBLE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                window.setBackgroundBlurRadius(0)
            }
            handlePermissionRequests()
        }
    }
}
