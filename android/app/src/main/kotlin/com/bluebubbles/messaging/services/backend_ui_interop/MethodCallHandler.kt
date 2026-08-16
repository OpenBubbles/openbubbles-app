package com.bluebubbles.messaging.services.backend_ui_interop

import android.content.Context
import android.util.Log
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.MainActivity
import com.bluebubbles.messaging.MainActivity.Companion.engine
import com.bluebubbles.messaging.services.extension.DevExtensionHandler
import com.bluebubbles.messaging.services.extension.MessageUpdateHandler
import com.bluebubbles.messaging.services.extension.StatusQuery
import com.bluebubbles.messaging.services.extension.TemplateTapHandler
import com.bluebubbles.messaging.services.facetime.FaceTimeCallStateHandler
import com.bluebubbles.messaging.services.facetime.FaceTimeGetActiveCallHandler
import com.bluebubbles.messaging.services.facetime.FaceTimeLaunchHandler
import com.bluebubbles.messaging.services.filesystem.GetContentUriPathHandler
import com.bluebubbles.messaging.services.firebase.FirebaseAuthHandler
import com.bluebubbles.messaging.services.firebase.FirebaseDeleteTokenHandler
import com.bluebubbles.messaging.services.firebase.ServerUrlRequestHandler
import com.bluebubbles.messaging.services.firebase.UpdateNextRestartHandler
import com.bluebubbles.messaging.services.notifications.CreateIncomingFaceTimeNotification
import com.bluebubbles.messaging.services.notifications.CreateIncomingMessageNotification
import com.bluebubbles.messaging.services.notifications.DeleteNotificationHandler
import com.bluebubbles.messaging.services.notifications.NotificationChannelHandler
import com.bluebubbles.messaging.services.notifications.NotificationListenerPermissionRequestHandler
import com.bluebubbles.messaging.services.notifications.StartNotificationListenerHandler
import com.bluebubbles.messaging.services.notifications.UnifiedPushHandler
import com.bluebubbles.messaging.services.rustpush.NotifyNativeConfiguredHandler
import com.bluebubbles.messaging.services.rustpush.SIMInfoQuery
import com.bluebubbles.messaging.services.rustpush.SMSAuthGateway
import com.bluebubbles.messaging.services.system.BrowserLaunchRequestHandler
import com.bluebubbles.messaging.services.system.CheckChromeOsHandler
import com.bluebubbles.messaging.services.system.NewContactFormRequestHandler
import com.bluebubbles.messaging.services.system.OpenCalendarRequestHandler
import com.bluebubbles.messaging.services.credentials.OpenAutofillProviderSettingsHandler
import com.bluebubbles.messaging.services.system.OpenConversationNotificationSettingsHandler
import com.bluebubbles.messaging.services.system.OpenExistingContactRequestHandler
import com.bluebubbles.messaging.services.system.PushShareTargetsHandler
import com.bluebubbles.messaging.services.system.StartGoogleDuoRequestHandler
import com.bluebubbles.messaging.services.foreground.StartForegroundServiceHandler
import com.bluebubbles.messaging.services.foreground.StopForegroundServiceHandler
import com.bluebubbles.messaging.services.notifications.CreateMissedFaceTimeNotification
import com.bluebubbles.messaging.services.rustpush.AppleAccountLoginHandler
import com.bluebubbles.messaging.services.rustpush.EAPAKAGateway
import com.bluebubbles.messaging.services.rustpush.GetNativeHandleHandler
import com.bluebubbles.messaging.services.rustpush.KeystoreUnlockHandler
import com.bluebubbles.messaging.services.rustpush.ProvisionNative
import com.bluebubbles.messaging.services.rustpush.SMSLessAuthGateway
import com.bluebubbles.messaging.services.system.EnableBTHandler
import com.bluebubbles.messaging.services.system.CircleProximitySessionHandler
import com.bluebubbles.messaging.services.system.ConversationExemptHandler
import com.bluebubbles.messaging.services.system.CreateDocumentHandler
import com.bluebubbles.messaging.services.system.GetFullResolution
import com.bluebubbles.messaging.services.system.GetZenMode
import com.bluebubbles.messaging.services.system.HeifDecoder
import com.bluebubbles.messaging.services.system.HeifEncoder
import com.bluebubbles.messaging.services.system.NativeSyncIsolateHandler
import com.bluebubbles.messaging.services.system.NearbyFindMyAccessoryHandler
import com.bluebubbles.messaging.services.system.OpenSMSAppHandler
import com.bluebubbles.messaging.services.system.RecentContactsRequestHandler
import com.bluebubbles.messaging.services.system.ShizukuGrantPermissionHandler
import com.bluebubbles.messaging.services.system.ZenModeSetupHandler
import com.bluebubbles.messaging.services.system.ZenModeUUIDHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MethodCallHandler {
    companion object {
        var getNotificationListenerResult: MethodChannel.Result? = null

        var queueId = 0
        var queuedMessages = HashMap<Int, String>()

        /// Send a method call back to Dart (app must be launched, otherwise use the DartWorker!)
        fun invokeMethod(method: String, arguments: Map<String, Any>) {
            if (engine != null) {
                MethodChannel(engine!!.dartExecutor.binaryMessenger, Constants.methodChannel).invokeMethod(method, arguments)
            }
        }

        fun invokeMethodCb(method: String, arguments: Map<String, Any>, callback: MethodChannel.Result) {
            if (engine != null) {
                MethodChannel(engine!!.dartExecutor.binaryMessenger, Constants.methodChannel).invokeMethod(method, arguments, callback)
            }
        }
    }

    fun methodCallHandler(call: MethodCall, result: MethodChannel.Result, context: Context) {
        Log.d(Constants.logTag, "Received new method call from Dart with method ${call.method}")
        when(call.method) {
            UnifiedPushHandler.tag -> UnifiedPushHandler().handleMethodCall(call, result, context)
            FirebaseAuthHandler.tag -> FirebaseAuthHandler().handleMethodCall(call, result, context)
            FirebaseDeleteTokenHandler.tag -> FirebaseDeleteTokenHandler().handleMethodCall(call, result, context)
            NotificationChannelHandler.tag -> NotificationChannelHandler().handleMethodCall(call, result, context)
            ServerUrlRequestHandler.tag -> ServerUrlRequestHandler().handleMethodCall(call, result, context)
            UpdateNextRestartHandler.tag -> UpdateNextRestartHandler().handleMethodCall(call, result, context)
            BrowserLaunchRequestHandler.tag -> BrowserLaunchRequestHandler().handleMethodCall(call, result, context)
            PushShareTargetsHandler.tag -> PushShareTargetsHandler().handleMethodCall(call, result, context)
            NewContactFormRequestHandler.tag -> NewContactFormRequestHandler().handleMethodCall(call, result, context)
            OpenExistingContactRequestHandler.tag -> OpenExistingContactRequestHandler().handleMethodCall(call, result, context)
            OpenCalendarRequestHandler.tag -> OpenCalendarRequestHandler().handleMethodCall(call, result, context)
            OpenAutofillProviderSettingsHandler.tag -> OpenAutofillProviderSettingsHandler().handleMethodCall(call, result, context)
            StartGoogleDuoRequestHandler.tag -> StartGoogleDuoRequestHandler().handleMethodCall(call, result, context)
            CheckChromeOsHandler.tag -> CheckChromeOsHandler().handleMethodCall(call, result, context)
            NotificationListenerPermissionRequestHandler.tag -> {
                getNotificationListenerResult = result
                NotificationListenerPermissionRequestHandler().handleMethodCall(call, result, context)
            }
            StartNotificationListenerHandler.tag -> StartNotificationListenerHandler().handleMethodCall(call, result, context)
            OpenConversationNotificationSettingsHandler.tag -> OpenConversationNotificationSettingsHandler().handleMethodCall(call, result, context)
            GetContentUriPathHandler.tag -> GetContentUriPathHandler().handleMethodCall(call, result, context)
            CreateIncomingMessageNotification.tag -> CreateIncomingMessageNotification().handleMethodCall(call, result, context)
            CreateIncomingFaceTimeNotification.tag -> CreateIncomingFaceTimeNotification().handleMethodCall(call, result, context)
            DeleteNotificationHandler.tag -> DeleteNotificationHandler().handleMethodCall(call, result, context)
            StartForegroundServiceHandler.tag -> StartForegroundServiceHandler().handleMethodCall(call, result, context)
            StopForegroundServiceHandler.tag -> StopForegroundServiceHandler().handleMethodCall(call, result, context)
            GetNativeHandleHandler.tag -> GetNativeHandleHandler().handleMethodCall(call, result, context)
            NotifyNativeConfiguredHandler.tag -> NotifyNativeConfiguredHandler().handleMethodCall(call, result, context)
            SMSAuthGateway.tag -> SMSAuthGateway().handleMethodCall(call, result, context)
            StatusQuery.tag -> StatusQuery().handleMethodCall(call, result, context)
            TemplateTapHandler.tag -> TemplateTapHandler().handleMethodCall(call, result, context)
            MessageUpdateHandler.tag -> MessageUpdateHandler().handleMethodCall(call, result, context)
            DevExtensionHandler.tag -> DevExtensionHandler().handleMethodCall(call, result, context)
            SIMInfoQuery.tag -> SIMInfoQuery().handleMethodCall(call, result, context)
            FaceTimeLaunchHandler.tag -> FaceTimeLaunchHandler().handleMethodCall(call, result, context)
            FaceTimeCallStateHandler.tag -> FaceTimeCallStateHandler().handleMethodCall(call, result, context)
            CreateMissedFaceTimeNotification.tag -> CreateMissedFaceTimeNotification().handleMethodCall(call, result, context)
            FaceTimeGetActiveCallHandler.tag -> FaceTimeGetActiveCallHandler().handleMethodCall(call, result, context)
            RecentContactsRequestHandler.tag -> RecentContactsRequestHandler().handleMethodCall(call, result, context)
            ConversationExemptHandler.tag -> ConversationExemptHandler().handleMethodCall(call, result, context)
            ZenModeSetupHandler.tag -> ZenModeSetupHandler().handleMethodCall(call, result, context)
            ZenModeUUIDHandler.tag -> ZenModeUUIDHandler().handleMethodCall(call, result, context)
            GetZenMode.tag -> GetZenMode().handleMethodCall(call, result, context)
            HeifDecoder.tag -> HeifDecoder().handleMethodCall(call, result, context)
            GetFullResolution.tag -> GetFullResolution().handleMethodCall(call, result, context)
            OpenSMSAppHandler.tag -> OpenSMSAppHandler().handleMethodCall(call, result, context)
            CreateDocumentHandler.tag -> CreateDocumentHandler().handleMethodCall(call, result, context)
            AppleAccountLoginHandler.tag -> AppleAccountLoginHandler().handleMethodCall(call, result, context)
            HeifEncoder.tag -> HeifEncoder().handleMethodCall(call, result, context)
            CircleProximitySessionHandler.tag -> CircleProximitySessionHandler().handleMethodCall(call, result, context)
            EnableBTHandler.tag -> EnableBTHandler().handleMethodCall(call, result, context)
            NativeSyncIsolateHandler.tag -> NativeSyncIsolateHandler().handleMethodCall(call, result, context)
            NearbyFindMyAccessoryHandler.scanTag,
            NearbyFindMyAccessoryHandler.playTag -> NearbyFindMyAccessoryHandler.instance.handleMethodCall(call, result, context)
            SMSLessAuthGateway.tag -> SMSLessAuthGateway().handleMethodCall(call, result, context)
            ShizukuGrantPermissionHandler.tag -> ShizukuGrantPermissionHandler().handleMethodCall(call, result, context)
            ProvisionNative.tag -> ProvisionNative().handleMethodCall(call, result, context)
            EAPAKAGateway.tag -> EAPAKAGateway().handleMethodCall(call, result, context)
            KeystoreUnlockHandler.tag -> KeystoreUnlockHandler().handleMethodCall(call, result, context)
            "ready" -> { MainActivity.engine_ready = true }
            else -> {
                val error = "Could not find method call handler for ${call.method}!"
                Log.d(Constants.logTag, error)
                result.error("500", error, null)
            }
        }
    }
}
