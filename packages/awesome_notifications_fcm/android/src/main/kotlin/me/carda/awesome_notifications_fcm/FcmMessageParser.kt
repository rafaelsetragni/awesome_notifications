package me.carda.awesome_notifications_fcm

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationLayout
import me.carda.android_awn_core.NotificationLifeCycle
import me.carda.android_awn_core.NotificationSource

/**
 * Turns a Firebase message into the serialized notification map the core engine
 * consumes (`{content:{…}, actionButtons?, schedule?, localizations?}`), and
 * decides whether a message should be displayed or handed to the silent handler.
 *
 * The awesome payload can arrive three (composable) ways in an FCM data message:
 *  1. a standard FCM `notification` block (title / body / channel / image),
 *  2. structured JSON strings under `content` / `schedule` / `actionButtons` /
 *     `localizations` / `Android`,
 *  3. dot-flattened keys (`content.title`, `actionButtons.0.key`, …).
 *
 * Kept free of Firebase types so it is unit-testable on the plain JVM: the
 * service extracts the notification block into a [StandardNotification].
 */
class FcmMessageParser {

    /** The standard FCM `notification` block, already extracted from RemoteMessage. */
    data class StandardNotification(
        val title: String?,
        val body: String?,
        val channelId: String?,
        val imageUrl: String?,
        val sticky: Boolean
    )

    /** True when the message carries something to display (vs. pure silent data). */
    fun isDisplayable(data: Map<String, String>, notification: StandardNotification?): Boolean {
        if (data[FcmDefinitions.FLAG_IS_SILENT_DATA] == "true") return false
        if (notification != null) return true
        if (data.containsKey(FcmDefinitions.MODEL_CONTENT)) return true
        if (data.keys.any { it.startsWith(FcmDefinitions.MODEL_CONTENT + ".") }) return true
        return false
    }

    fun buildAwesomeMap(
        context: Context,
        notificationId: Int,
        data: Map<String, String>,
        notification: StandardNotification?,
        lifeCycle: NotificationLifeCycle
    ): Map<String, Any?> {
        val remoteData = data.toMutableMap().apply { remove(FcmDefinitions.MODEL_IOS) }

        // (1) baseline content from the FCM notification block + full data as payload.
        val standardContent = standardContent(context, notificationId, remoteData, notification)

        // (2) awesome content: structured JSON strings, or dot-flattened.
        val awesomeContent: MutableMap<String, Any?>
        var androidOverrides: Map<String, Any?>? = null
        if (remoteData.containsKey(FcmDefinitions.MODEL_CONTENT)) {
            awesomeContent = structuredContent(notificationId, remoteData)
            (FcmJson.parseObjectOrNull(remoteData[FcmDefinitions.MODEL_ANDROID]) as? Map<String, Any?>)
                ?.let { androidOverrides = it }
        } else {
            awesomeContent = JsonFlattener.decode(remoteData)
            (awesomeContent[FcmDefinitions.MODEL_ANDROID] as? Map<String, Any?>)
                ?.let { androidOverrides = it }
        }

        var merged = deepMerge(standardContent, awesomeContent)
        androidOverrides?.let { merged = deepMerge(merged, it) }

        // (3) stamp the FCM origin + created date so a tapped push reports the
        // correct createdSource/createdDate (the core only stamps if absent).
        stampCreated(merged, lifeCycle)
        return merged
    }

    // ---- content assembly ---------------------------------------------------

    private fun standardContent(
        context: Context,
        notificationId: Int,
        data: Map<String, String>,
        notification: StandardNotification?
    ): MutableMap<String, Any?> {
        val content = fcmNotificationIntoContent(notificationId, data, notification)
        if (!content.containsKey(Definitions.NOTIFICATION_CHANNEL_KEY)) {
            firstOsChannelKey(context)?.let { content[Definitions.NOTIFICATION_CHANNEL_KEY] = it }
        }
        if (data.isNotEmpty()) content[Definitions.NOTIFICATION_PAYLOAD] = HashMap(data)
        return mutableMapOf(FcmDefinitions.MODEL_CONTENT to content)
    }

    private fun structuredContent(
        notificationId: Int,
        remoteData: Map<String, String>
    ): MutableMap<String, Any?> {
        val content = (FcmJson.parseObjectOrNull(remoteData[FcmDefinitions.MODEL_CONTENT])
            as? Map<String, Any?>)?.toMutableMap() ?: mutableMapOf()
        // Honour an explicit id in the content, else keep the generated one.
        val id = (content[Definitions.NOTIFICATION_ID] as? Number)?.toInt()
            ?: (content[Definitions.NOTIFICATION_ID] as? String)?.toIntOrNull()
            ?: notificationId
        content[Definitions.NOTIFICATION_ID] = id

        val out = mutableMapOf<String, Any?>(FcmDefinitions.MODEL_CONTENT to content)
        (FcmJson.parseObjectOrNull(remoteData[FcmDefinitions.MODEL_SCHEDULE]) as? Map<String, Any?>)
            ?.let { if (it.isNotEmpty()) out[FcmDefinitions.MODEL_SCHEDULE] = it }
        (FcmJson.parseListOrNull(remoteData[FcmDefinitions.MODEL_BUTTONS]))
            ?.let { if (it.isNotEmpty()) out[FcmDefinitions.MODEL_BUTTONS] = it }
        (FcmJson.parseObjectOrNull(remoteData[FcmDefinitions.MODEL_LOCALIZATIONS]) as? Map<String, Any?>)
            ?.let { if (it.isNotEmpty()) out[FcmDefinitions.MODEL_LOCALIZATIONS] = it }
        return out
    }

    private fun fcmNotificationIntoContent(
        notificationId: Int,
        data: Map<String, String>,
        notification: StandardNotification?
    ): MutableMap<String, Any?> {
        val content = mutableMapOf<String, Any?>(Definitions.NOTIFICATION_ID to notificationId)
        if (notification != null) {
            notification.channelId?.takeIf { it.isNotBlank() }
                ?.let { content[Definitions.NOTIFICATION_CHANNEL_KEY] = it }
            notification.title?.takeIf { it.isNotBlank() }
                ?.let { content[Definitions.NOTIFICATION_TITLE] = it }
            notification.body?.takeIf { it.isNotBlank() }
                ?.let { content[Definitions.NOTIFICATION_BODY] = it }
            content[Definitions.NOTIFICATION_AUTO_DISMISSIBLE] = !notification.sticky
            notification.imageUrl?.takeIf { it.isNotBlank() }?.let {
                content[Definitions.NOTIFICATION_BIG_PICTURE] = it
                content[Definitions.NOTIFICATION_LAYOUT] = NotificationLayout.BigPicture.name
            }
        }
        return content
    }

    private fun stampCreated(model: MutableMap<String, Any?>, lifeCycle: NotificationLifeCycle) {
        @Suppress("UNCHECKED_CAST")
        val content = (model[FcmDefinitions.MODEL_CONTENT] as? MutableMap<String, Any?>)
            ?: mutableMapOf<String, Any?>().also { model[FcmDefinitions.MODEL_CONTENT] = it }
        if (content[Definitions.NOTIFICATION_CREATED_DATE] == null) {
            content[Definitions.NOTIFICATION_CREATED_DATE] = FcmDateUtils.nowUtc()
            content[Definitions.NOTIFICATION_CREATED_SOURCE] = NotificationSource.Firebase.name
            content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = lifeCycle.name
        }
    }

    // ---- helpers ------------------------------------------------------------

    private fun firstOsChannelKey(context: Context): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        return nm?.notificationChannels?.firstOrNull()?.id
    }

    companion object {
        /** Recursive map merge; values from [override] win, nested maps are merged. */
        @Suppress("UNCHECKED_CAST")
        fun deepMerge(
            base: Map<String, Any?>,
            override: Map<String, Any?>
        ): MutableMap<String, Any?> {
            val result = base.toMutableMap()
            for ((key, value) in override) {
                val existing = result[key]
                result[key] = if (existing is Map<*, *> && value is Map<*, *>) {
                    deepMerge(existing as Map<String, Any?>, value as Map<String, Any?>)
                } else {
                    value
                }
            }
            return result
        }
    }
}
