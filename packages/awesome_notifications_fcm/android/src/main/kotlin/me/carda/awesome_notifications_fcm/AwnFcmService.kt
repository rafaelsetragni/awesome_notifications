package me.carda.awesome_notifications_fcm

import android.net.Uri
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import me.carda.android_awn_core.AwesomeNotifications
import kotlin.math.abs

/**
 * The FirebaseMessagingService that receives every push. Registered in the
 * plugin manifest, so it runs in all app states (foreground / background /
 * terminated) for data messages.
 *
 * Displayable messages are turned into a core payload and posted through the
 * Flutter-free [AwesomeNotifications] engine (no Flutter engine required). Pure
 * data messages are routed to the silent handler — to the attached plugin if the
 * app is alive, otherwise to a headless Dart isolate.
 */
class AwnFcmService : FirebaseMessagingService() {

    private val parser = FcmMessageParser()

    override fun onNewToken(token: String) {
        FcmDefaultsManager.setLastToken(this, token)
        FcmEventsReceiver.notifyFcmToken(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        val notification = remoteMessage.notification?.let {
            FcmMessageParser.StandardNotification(
                title = it.title,
                body = it.body,
                channelId = it.channelId,
                imageUrl = it.imageUrl?.let(Uri::toString),
                sticky = it.sticky
            )
        }

        val notificationId = messageIdToInt(remoteMessage)

        if (parser.isDisplayable(data, notification)) {
            val lifeCycle = FcmLifecycle.current(applicationContext)
            val model = parser.buildAwesomeMap(
                applicationContext, notificationId, data, notification, lifeCycle
            )
            AwesomeNotifications(applicationContext).createNotification(model) { /* posted */ }
        } else {
            val silentData = SilentDataModel().apply {
                createdLifeCycle = FcmLifecycle.current(applicationContext)
            }.fromData(data)
            // A foreground plugin consumes it directly; otherwise a headless
            // isolate runs the registered background handler.
            if (!FcmEventsReceiver.notifySilentData(silentData)) {
                FcmBackgroundExecutor.enqueue(applicationContext, silentData)
            }
        }
    }

    /** Derives a stable notification id from the FCM message id, else random. */
    private fun messageIdToInt(remoteMessage: RemoteMessage): Int {
        val messageId = remoteMessage.messageId
        if (!messageId.isNullOrEmpty()) {
            Regex("^.*:(\\d{1,8})%").find(messageId)?.groupValues?.getOrNull(1)?.toIntOrNull()
                ?.let { return it }
            return abs(messageId.hashCode())
        }
        return abs((System.nanoTime()).toInt())
    }
}
