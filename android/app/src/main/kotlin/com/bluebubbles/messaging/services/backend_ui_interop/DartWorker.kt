package com.bluebubbles.messaging.services.backend_ui_interop

import android.content.Context
import android.util.Log
import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.core.app.NotificationCompat
import androidx.work.ForegroundInfo
import androidx.work.ListenableWorker
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.MainActivity.Companion.engine
import com.bluebubbles.messaging.R
import com.bluebubbles.messaging.services.rustpush.APNService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.google.gson.GsonBuilder
import com.google.gson.ToNumberPolicy
import com.google.gson.reflect.TypeToken
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.ApplicationInfoLoader
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import io.flutter.FlutterInjector
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.Timer
import kotlin.concurrent.schedule
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.guava.future
import java.util.TimerTask
import java.util.concurrent.atomic.AtomicInteger

class DartWorker(context: Context, workerParams: WorkerParameters): ListenableWorker(context, workerParams) {

    companion object {
        var workerEngine: FlutterEngine? = null
        var engineReady = Mutex()



        /// Code idea taken from https://github.com/flutter/flutter/wiki/Experimental:-Reuse-FlutterEngine-across-screens
        private suspend fun initNewEngine(applicationContext: Context) {
            Log.d(Constants.logTag, "Ensuring Flutter is initialized before creating engine")
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)

            Log.d(Constants.logTag, "Loading callback info")
            val info = ApplicationInfoLoader.load(applicationContext)
            workerEngine = FlutterEngine(applicationContext)

            currentJobs.set(0)

            workerEngine!!.addEngineLifecycleListener ( object : FlutterEngine.EngineLifecycleListener {
                override fun onPreEngineRestart() {
                    Log.d(Constants.logTag, "Engine is restarting")
                }

                override fun onEngineWillDestroy() {
                    Log.d(Constants.logTag, "Engine is being destroyed")
                }
            })
            suspendCoroutine { cont ->
                // set up the method channel to receive events from Dart
                MethodChannel(workerEngine!!.dartExecutor.binaryMessenger, Constants.methodChannel).setMethodCallHandler {
                        call, result -> run {
                    if (call.method == "ready") {
                        Log.d(Constants.logTag, "Dart engine is ready!")
                        cont.resume(Unit)
                    } else {
                        MethodCallHandler().methodCallHandler(call, result, applicationContext)
                    }
                }
                }
                val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(applicationContext.getSharedPreferences("FlutterSharedPreferences", 0).getLong("flutter.backgroundCallbackHandle", -1))
                val callback = DartExecutor.DartCallback(applicationContext.assets, info.flutterAssetsDir, callbackInfo)

                Log.d(Constants.logTag, "Executing Dart callback")
                workerEngine!!.dartExecutor.executeDartCallback(callback)
            }
        }

        var currentCancelTask: TimerTask? = null
        private fun closeEngineIfNeeded(applicationContext: Context) {
            currentJobs.getAndDecrement()
            // Delay 30 seconds so Dart has a chance to complete everything and in case new work comes in shortly after
            currentCancelTask?.cancel()
            currentCancelTask = Timer().schedule(30000) {
                currentCancelTask = null
                Log.d(Constants.logTag, "$currentJobs worker(s) still queued")
                if (currentJobs.get() == 0 && workerEngine != null) {
                    Log.d(Constants.logTag, "Closing ${Constants.dartWorkerTag} engine")
                    // This must be run on main thread
                    CoroutineScope(Dispatchers.Main).launch {
                        workerEngine?.destroy()
                        workerEngine = null
                    }
                }
            }
        }

        var currentJobs = AtomicInteger(0)

        suspend fun callMethod(applicationContext: Context, method: String, arguments: Map<String, Any>) {
            engineReady.withLock {
                if (engine == null && workerEngine == null) {
                    Log.d(Constants.logTag, "Initializing engine for worker with method $method")
                    initNewEngine(applicationContext)
                }
            }
            Log.d(Constants.logTag, "Sending event, '$method' to Dart")

            try {
                var engineToUse: FlutterEngine? = engine ?: workerEngine
                if (engineToUse == null) {
                    Log.d(Constants.logTag, "Engine is null, cannot send method $method to Dart")
                    throw Exception("No engine")
                }

                Log.d(Constants.logTag, "Registering engine lifecycle listener")

                Log.d(Constants.logTag, "Invoking method channel...")
                suspendCoroutine { cont ->
                    currentJobs.getAndIncrement()
                    MethodChannel(engineToUse!!.dartExecutor.binaryMessenger, Constants.methodChannel).invokeMethod(method, arguments, object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            Log.d(Constants.logTag, "Worker with method $method completed successfully")
                            cont.resume(Result.success())
                            closeEngineIfNeeded(applicationContext)
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            Log.e(Constants.logTag, "Worker with method $method failed!")
                            cont.resume(Result.failure())
                            closeEngineIfNeeded(applicationContext)
                        }

                        override fun notImplemented() {
                            Log.e(Constants.logTag, "Worker with method $method not implemented on Dart side")
                            cont.resume(Result.failure())
                            closeEngineIfNeeded(applicationContext)
                        }
                    })
                }

                Log.d(Constants.logTag, "Worker with method $method completed successfully")
            } catch (e: Exception) {
                Log.d(Constants.logTag, "Error sending method $method to Dart: ${e.message}")
                throw e
            }
        }
    }

    override fun startWork(): ListenableFuture<Result> {
        val method = inputData.getString("method")!!
        var data = inputData.getString("data")!!
        val gson = GsonBuilder()
                .setObjectToNumberStrategy(ToNumberPolicy.LONG_OR_DOUBLE)
                .create()
        if (method == "SMSMsg") {
            val json: HashMap<String, Any> = gson.fromJson(data, TypeToken.getParameterized(HashMap::class.java, String::class.java, Any::class.java).type)
            val pointer: Int = (json["id"] as Long).toInt()
            if (MethodCallHandler.queuedMessages.contains(pointer)) {
                data = MethodCallHandler.queuedMessages.remove(pointer)!!
            } else {
                // bail
                return Futures.immediateFuture(Result.success())
            }
        }

        if (engine != null) {
            Log.d(Constants.logTag, "Using MainActivity engine to send to Dart")
        } else {
            Log.d(Constants.logTag, "Using DartWorker engine to send to Dart")
        }
        return CoroutineScope(Dispatchers.Main).future {
            val arguments: HashMap<String, Any> = gson.fromJson(data, TypeToken.getParameterized(HashMap::class.java, String::class.java, Any::class.java).type)
            try {
                callMethod(applicationContext, method, arguments)
                Result.success()
            } catch (e: Exception) {
                Log.d(Constants.logTag, "Error sending method $method to Dart: ${e.message}")
                Result.failure()
            }
        }
    }

    // Dumb thing that appears to be necessary for Android 11 and under (see https://stackoverflow.com/questions/69684656/upgrading-to-workmanager-2-7-0-how-to-implement-getforegroundinfoasync-for-rxwo)
    override fun getForegroundInfoAsync(): ListenableFuture<ForegroundInfo> {
        val notification = NotificationCompat.Builder(applicationContext, "com.bluebubbles.foreground_service")
            .setSmallIcon(R.mipmap.ic_stat_icon)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentTitle("BlueBubbles DartWorker")
            .setContentText("BlueBubbles is performing short work in the background")
            .setColor(4888294)
            .build()
        return Futures.immediateFuture(ForegroundInfo(Constants.dartWorkerNotificationId, notification))
    }
}