package me.carda.android_awn_core

import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat
import java.util.concurrent.ConcurrentHashMap

/**
 * The `Messaging` / `MessagingGroup` layouts of 0.12 (NotificationBuilder
 * `setMessagingLayout`), ported as they were, quirks included:
 *  - the conversation is the notification's group (its `groupKey`, the
 *    channel's when the content has none); a new message is shown under the
 *    id of the FIRST notification of that group still on screen, so the whole
 *    conversation stacks in one notification;
 *  - the history lives in memory, per group (".Gr" for MessagingGroup), and
 *    restarts when no notification of the group is on screen (or the process
 *    dies); a `messages` list sent in the content replaces it;
 *  - the MessagingStyle user is the sender (`title`), and every message of the
 *    history is drawn under the CURRENT sender's name, with its own large icon;
 *  - `summary` is the conversation title (MessagingGroup, Android 9+);
 *  - without a `title` the layout is not applied (the default one is).
 *
 * A messaging add-on (awesome_notifications_chat) replaces this through the
 * decorator chain.
 */
internal object MessagingLayout {

    /** Extras every core notification carries so its group can be found on screen. */
    const val EXTRA_GROUP_KEY = "awn.groupKey"
    const val EXTRA_REGISTERED_AT = "awn.registeredAt"

    private const val KEY_MESSAGE = "messages"  // 0.12 serialized the text under "messages"
    private const val KEY_TIMESTAMP = "timestamp"
    private const val KEY_SUMMARY = "summary"
    private const val KEY_MESSAGES = "messages"
    private const val KEY_ROUNDED_LARGE_ICON = "roundedLargeIcon"

    /** 0.12 `messagingQueue`. */
    private val queue = ConcurrentHashMap<String, MutableList<Map<String, Any?>>>()

    fun isMessaging(layout: NotificationLayout) =
        layout == NotificationLayout.Messaging || layout == NotificationLayout.MessagingGroup

    /**
     * The model step of 0.12 `setMessagingLayout`: the id the message is shown
     * under and the accumulated history (`content.messages`). Returns the model
     * unchanged when the layout does not apply.
     */
    fun prepare(context: Context, model: Map<String, Any?>): Map<String, Any?> {
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>) ?: return model
        val layout = NotificationLayout.from(content[Definitions.NOTIFICATION_LAYOUT] as? String)
        if (!isMessaging(layout)) return model
        val title = content[Definitions.NOTIFICATION_TITLE] as? String
        if (title.isNullOrEmpty()) return model

        val groupKey = content[Definitions.NOTIFICATION_GROUP_KEY] as? String
        val isGrouping = layout == NotificationLayout.MessagingGroup
        // Java string concatenation: a null group key is the "null" queue.
        val queueKey = groupKey + (if (isGrouping) ".Gr" else "")

        var firstId = MapUtils.getInstance().getInt(content[Definitions.NOTIFICATION_ID]) ?: return model
        val groupIds = activeIdsOfGroup(context, groupKey)
        if (groupIds.isEmpty()) queue.remove(queueKey) else firstId = groupIds.first()

        val current = mapOf<String, Any?>(
            Definitions.NOTIFICATION_TITLE to title,
            KEY_SUMMARY to content[KEY_SUMMARY],
            KEY_MESSAGE to content[Definitions.NOTIFICATION_BODY],
            Definitions.NOTIFICATION_LARGE_ICON to content[Definitions.NOTIFICATION_LARGE_ICON],
            KEY_TIMESTAMP to System.currentTimeMillis()
        )

        @Suppress("UNCHECKED_CAST")
        val sent = (content[KEY_MESSAGES] as? List<Map<String, Any?>>)?.takeIf { it.isNotEmpty() }
        val messages = sent?.toMutableList() ?: queue[queueKey] ?: mutableListOf()
        messages.add(current)
        queue[queueKey] = messages

        val updated = content.toMutableMap()
        updated[Definitions.NOTIFICATION_ID] = firstId
        updated[KEY_MESSAGES] = messages.toList()
        return model.toMutableMap().apply { this[Definitions.NOTIFICATION_CONTENT] = updated }
    }

    /** The style step of 0.12 `setMessagingLayout`, on a prepared content. */
    fun applyStyle(
        context: Context,
        content: Map<String, Any?>,
        builder: NotificationCompat.Builder,
        bitmapUtils: BitmapUtils
    ): Boolean {
        val layout = NotificationLayout.from(content[Definitions.NOTIFICATION_LAYOUT] as? String)
        if (!isMessaging(layout)) return false
        val username = content[Definitions.NOTIFICATION_TITLE] as? String
        if (username.isNullOrEmpty()) return false
        val groupName = content[KEY_SUMMARY] as? String
        val rounded = MapUtils.getInstance().getBool(content[KEY_ROUNDED_LARGE_ICON]) ?: false

        @Suppress("UNCHECKED_CAST")
        val messages = (content[KEY_MESSAGES] as? List<Map<String, Any?>>) ?: emptyList()

        @Suppress("DEPRECATION")
        val style = NotificationCompat.MessagingStyle(username)
        for (message in messages) {
            val text = message[KEY_MESSAGE] as? String
            val timestamp = (message[KEY_TIMESTAMP] as? Number)?.toLong() ?: System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val person = Person.Builder().setName(username)
                val iconPath = (message[Definitions.NOTIFICATION_LARGE_ICON] as? String)
                    ?: (content[Definitions.NOTIFICATION_LARGE_ICON] as? String)
                if (!iconPath.isNullOrEmpty()) {
                    bitmapUtils.getBitmapFromSource(context, iconPath)
                        ?.let { if (rounded) circle(it) else it }
                        ?.let { person.setIcon(IconCompat.createWithBitmap(it)) }
                }
                style.addMessage(text, timestamp, person.build())
            } else {
                @Suppress("DEPRECATION")
                style.addMessage(text, timestamp, message[Definitions.NOTIFICATION_TITLE] as? String)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            layout == NotificationLayout.MessagingGroup
        ) {
            style.setConversationTitle(groupName)
            style.setGroupConversation(true)
        }
        builder.setStyle(style)
        return true
    }

    /**
     * Group bookkeeping extras for a notification about to be posted: its group
     * key and when it was first registered (kept when the same id is reposted),
     * which orders the group as 0.12's registry did.
     */
    fun groupExtras(context: Context, id: Int, groupKey: String?): Bundle {
        val extras = Bundle()
        if (groupKey.isNullOrEmpty()) return extras
        extras.putString(EXTRA_GROUP_KEY, groupKey)
        val existing = notificationManager(context).activeNotifications
            .firstOrNull { it.id == id }
            ?.notification?.extras
            ?.takeIf { it.getString(EXTRA_GROUP_KEY) == groupKey }
            ?.getLong(EXTRA_REGISTERED_AT, 0L)
            ?.takeIf { it > 0L }
        extras.putLong(EXTRA_REGISTERED_AT, existing ?: System.currentTimeMillis())
        return extras
    }

    /** Ids of the group's notifications on screen, first registered first. */
    private fun activeIdsOfGroup(context: Context, groupKey: String?): List<Int> {
        if (groupKey.isNullOrEmpty()) return emptyList()
        return notificationManager(context).activeNotifications
            .filter { it.notification.extras?.getString(EXTRA_GROUP_KEY) == groupKey }
            .sortedBy { it.notification.extras.getLong(EXTRA_REGISTERED_AT, it.postTime) }
            .map { it.id }
    }

    private fun circle(source: Bitmap): Bitmap {
        val size = minOf(source.width, source.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = BitmapShader(source, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }
        Canvas(output).drawCircle(size / 2f, size / 2f, size / 2f, paint)
        return output
    }

    private fun notificationManager(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
}
