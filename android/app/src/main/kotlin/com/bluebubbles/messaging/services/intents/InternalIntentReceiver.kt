package com.bluebubbles.messaging.services.intents

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationManager
import android.app.Person
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.services.backend_ui_interop.DartWorkManager
import com.bluebubbles.messaging.services.facetime.FaceTimeActivity
import com.bluebubbles.messaging.services.notifications.DeleteNotificationHandler
import com.bluebubbles.messaging.services.rustpush.APNClient
import com.bluebubbles.messaging.services.rustpush.APNService
import com.bluebubbles.messaging.utils.Utils
import java.io.BufferedInputStream
import java.io.DataInputStream
import java.io.File
import java.io.FileInputStream
import java.io.IOException


class InternalIntentReceiver: BroadcastReceiver() {
    @SuppressLint("NewApi")
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        Log.d(Constants.logTag, "Received internal intent ${intent.type}, handling...")
        when (intent.type) {
            "DeleteNotification" -> {
                val notificationId: Int = intent.getIntExtra("notificationId", 0)
                val tag: String? = intent.getStringExtra("tag")
                DeleteNotificationHandler().deleteNotification(context, notificationId, tag)
            }
            "MarkChatRead" -> {
                val notificationId: Int = intent.getIntExtra("notificationId", 0)
                val chatGuid: String? = intent.getStringExtra("chatGuid")
                val tag: String? = intent.getStringExtra("tag")
                DeleteNotificationHandler().deleteNotification(context, notificationId, tag)
                DartWorkManager.createWorker(context, intent.type!!, hashMapOf("chatGuid" to chatGuid)) {}
            }
            "DeclineFaceTime" -> {
                val callUuid: String? = intent.getStringExtra("callUuid")
                val notificationId: Int = intent.getIntExtra("notificationId", 0)
                DeleteNotificationHandler().deleteNotification(context, notificationId, null)
                FaceTimeActivity.cachedWebview?.let {
                    it.webView.destroy()
                    FaceTimeActivity.cachedWebview = null
                }
                callUuid?.let { callUuid ->
                    val service = (peekService(context, Intent(context, APNService::class.java)) as APNService.APNBinder).getService()
                    service.pushState?.declineFacetime(callUuid)
                }
            }
            "ReplyChat" -> {
                val notificationId: Int = intent.getIntExtra("notificationId", 0)
                val chatGuid: String? = intent.getStringExtra("chatGuid")
                val messageGuid: String? = intent.getStringExtra("messageGuid")
                val replyText = RemoteInput.getResultsFromIntent(intent)?.getString("text_reply") ?: return

                DartWorkManager.createWorker(context, intent.type!!, hashMapOf("chatGuid" to chatGuid, "messageGuid" to messageGuid, "text" to replyText)) {
                    val notificationManager = context.getSystemService(NotificationManager::class.java)
                    // this is used to copy the style, since the notification already exists
                    Log.d(Constants.logTag, "Fetching existing notification values")
                    val chatNotification = notificationManager.activeNotifications.lastOrNull { it.id == notificationId }
                        ?: return@createWorker // notification no longer exists
                    val oldBuilder = Notification.Builder.recoverBuilder(context, chatNotification.notification)
                    val oldStyle = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        oldBuilder.style as Notification.MessagingStyle
                    } else {
                        val temp = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(chatNotification.notification)
                        Notification.MessagingStyle(Person.Builder()
                            .setName(temp!!.user.name)
                            .setIcon(temp.user.icon?.toIcon(context))
                            .setImportant(true)
                            .build()
                        )
                    }

                    Log.d(Constants.logTag, "Creating message object for the user-created reply")
                    oldStyle.addMessage(Notification.MessagingStyle.Message(
                        replyText,
                        System.currentTimeMillis(),
                        null as Person?
                    ))

                    Log.d(Constants.logTag, "Posting the user-created reply")
                    oldBuilder.setStyle(oldStyle)
                    oldBuilder.setOnlyAlertOnce(true)
                    oldBuilder.setGroupAlertBehavior(Notification.GROUP_ALERT_SUMMARY)
                    notificationManager.notify(Constants.newMessageNotificationTag, notificationId, oldBuilder.build())
                }
            }
        }
    }
}