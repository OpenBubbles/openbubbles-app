package com.bluebubbles.messaging

import android.util.Log
import android.app.Activity
import android.content.ComponentCallbacks2
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import com.bluebubbles.messaging.services.backend_ui_interop.MethodCallHandler
import com.bluebubbles.messaging.services.foreground.ForegroundServiceBroadcastReceiver
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.services.extension.KeyboardViewFactory
import com.bluebubbles.messaging.services.extension.LiveExtensionFactory
import com.bluebubbles.messaging.services.rustpush.APNService
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability

class MainActivity : FlutterFragmentActivity(), ComponentCallbacks2 {
    companion object {
        var engine: FlutterEngine? = null
        var engine_ready = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(Intent(this, APNService::class.java))
        } else {
            startService(Intent(this, APNService::class.java))
        }
        checkForUpdate()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        engine_ready = false
        engine = flutterEngine
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.methodChannel).setMethodCallHandler { call, result ->
            if (call.method == "engine-done") {
                Log.i("BBEngine", "Destroyed");
                // this must be here in case another engine has been spawned in the meantime
                flutterEngine.destroy()
                if (engine == flutterEngine)
                    engine = null
            }
            MethodCallHandler().methodCallHandler(call, result, this)
        }
        flutterEngine.platformViewsController.registry.registerViewFactory("extension-keyboard", KeyboardViewFactory())
        flutterEngine.platformViewsController.registry.registerViewFactory("extension-live", LiveExtensionFactory())
    }

    override fun onDestroy() {
        Log.d(Constants.logTag, "BlueBubbles MainActivity is being destroyed")
        engine = null

        // If we are finishing "gracefully", the dart code would have started the foreground service.
        // If we are finishing because the system is destroying the activity, we need to start the foreground service
        // via a broadcast intent.
        if (isFinishing) {
            Log.d(Constants.logTag, "BlueBubbles activity is finishing")
        } else {
            Log.d(Constants.logTag, "BlueBubbles activity is being destroyed by the system")

            val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", 0)
            val keepAppAlive: Boolean = prefs.getBoolean("flutter.keepAppAlive", false)

            // Create an intent to start the foreground service
            if (keepAppAlive) {
                Log.d(Constants.logTag, "Creating broadcast intent to restart the foreground service...")
                val broadcastIntent = Intent(this, ForegroundServiceBroadcastReceiver::class.java)
                broadcastIntent.setAction("restartservice");
                sendBroadcast(broadcastIntent);
            }
        }

        try {
            super.onDestroy()
        } catch (e: ConcurrentModificationException) {
            Log.d(Constants.logTag, "Caught ConcurrentModificationException when destroying MainActivity")
            Log.e(Constants.logTag, e.stackTraceToString())
        } catch (e: Exception) {
            Log.d(Constants.logTag, "Caught unhandled Exception when destroying MainActivity")
            Log.e(Constants.logTag, e.stackTraceToString())
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == Constants.notificationListenerRequestCode) {
            MethodCallHandler.getNotificationListenerResult?.success(resultCode == Activity.RESULT_OK)
        }
    }

    private fun checkForUpdate() {
        val appUpdateManager = AppUpdateManagerFactory.create(this)
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo

        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                appUpdateManager.startUpdateFlowForResult(
                    appUpdateInfo,
                    AppUpdateType.IMMEDIATE,
                    this,
                    1001
                )
            }
        }
    }
}
