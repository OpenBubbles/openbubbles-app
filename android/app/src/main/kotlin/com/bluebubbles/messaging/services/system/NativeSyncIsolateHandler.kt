package com.bluebubbles.messaging.services.system

import android.content.Context
import android.util.Log
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.models.MethodCallHandlerImpl
import com.bluebubbles.messaging.services.backend_ui_interop.MethodCallHandler
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.ApplicationInfoLoader
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import io.flutter.FlutterInjector
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class NativeSyncIsolateHandler : MethodCallHandlerImpl() {
    companion object {
        const val tag = "native-sync-isolate"

        var engine: FlutterEngine? = null
    }

    override fun handleMethodCall(
        call: MethodCall,
        mainresult: MethodChannel.Result,
        mainContext: Context
    ) {
        val context = mainContext.applicationContext

        var param = call.argument<Boolean>("close") ?: false
        if (param) {
            engine?.destroy()
            engine = null
            mainresult.success(null)
            return
        }

        if (engine != null) {
            mainresult.success(null)
            return
        }

        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)

        Log.d(Constants.logTag, "Loading callback info")
        val info = ApplicationInfoLoader.load(context)
        val workerEngine = FlutterEngine(context)
        engine = workerEngine
        MethodChannel(workerEngine.dartExecutor.binaryMessenger, Constants.methodChannel).setMethodCallHandler {
                call, result -> run {
            if (call.method == "ready") {
                Log.d(Constants.logTag, "Dart engine is ready!")
                mainresult.success(null)
            } else if (call.method == "exit") {
                workerEngine.destroy()
                engine = null
            } else {
                MethodCallHandler().methodCallHandler(call, result, context)
            }
        }
        }
        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(context.getSharedPreferences("FlutterSharedPreferences", 0).getLong("flutter.backgroundSyncIsolate", -1))
        val callback = DartExecutor.DartCallback(context.assets, info.flutterAssetsDir, callbackInfo)

        Log.d(Constants.logTag, "Executing Dart callback")
        workerEngine.dartExecutor.executeDartCallback(callback)
    }
}