package me.carda.awesome_notifications_chat

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.content.LocusIdCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import me.carda.android_awn_core.BitmapUtils
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilder

/**
 * Takes over the `Messaging` / `MessagingGroup` layouts: the notification is an
 * Android conversation (MessagingStyle with Persons, a long-lived conversation
 * shortcut, the history read back from the notification on screen) instead of
 * the core's 0.12 rendering.
 *
 * `build` validates and marks the model (the core then skips its built-in
 * layout); `decorate` renders the conversation on the Android builder, both for
 * an immediate notification and at a schedule's fire time.
 */
internal class ChatBuilder(inner: NotificationBuilder) : NotificationBuilder(inner) {

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        val content = contentMap(model)
        val layout = content[Definitions.NOTIFICATION_LAYOUT] as? String
        val isMessaging = layout == LAYOUT_MESSAGING || layout == LAYOUT_MESSAGING_GROUP
        val block = model[ChatKeys.CONVERSATION]

        if (block == null) {
            return if (isMessaging) invalid(
                "The $layout layout requires a NotificationConversation",
                ".notificationConversation"
            ) else next(context, model)
        }
        if (!isMessaging) return invalid(
            "A NotificationConversation requires the Messaging or MessagingGroup layout",
            ".notificationConversation.layout"
        )

        val isGroup = layout == LAYOUT_MESSAGING_GROUP
        val (conversation, error) = ChatConversation.parse(block, isGroup)
        if (conversation == null) return invalid(error!!, ".notificationConversation")

        // What platforms without a conversation UI show, and the collapsed view.
        val updated = content.toMutableMap()
        if ((updated[Definitions.NOTIFICATION_TITLE] as? String).isNullOrEmpty())
            updated[Definitions.NOTIFICATION_TITLE] = conversation.displayName(isGroup)
        if ((updated[Definitions.NOTIFICATION_BODY] as? String).isNullOrEmpty())
            updated[Definitions.NOTIFICATION_BODY] = conversation.message.text
        @Suppress("UNCHECKED_CAST")
        val payload = (updated[Definitions.NOTIFICATION_PAYLOAD] as? Map<String, Any?>)
            ?.toMutableMap() ?: mutableMapOf()
        payload.putIfAbsent(ChatKeys.CONVERSATION_ID, conversation.id)
        updated[Definitions.NOTIFICATION_PAYLOAD] = payload

        return next(context, model.toMutableMap().apply {
            this[Definitions.NOTIFICATION_CONTENT] = updated
            this[CUSTOM_LAYOUT] = true
        })
    }

    override fun decorate(
        context: Context,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        val content = contentMap(model)
        val isGroup = content[Definitions.NOTIFICATION_LAYOUT] == LAYOUT_MESSAGING_GROUP
        val conversation = model[ChatKeys.CONVERSATION]
            ?.let { ChatConversation.parse(it, isGroup).first }
        if (conversation != null && hasCustomLayout(model)) {
            val id = content[Definitions.NOTIFICATION_ID] as? Number
            ChatRenderer(context).render(conversation, isGroup, id?.toInt(), builder)
        }
        super.decorate(context, model, builder)
    }

    private fun invalid(message: String, detail: String) = BuildOutcome.Failed(
        ChatKeys.CODE_INVALID_ARGUMENTS, message, ChatKeys.DETAILED_INVALID_ARGUMENTS + detail
    )

    companion object {
        const val LAYOUT_MESSAGING = "Messaging"
        const val LAYOUT_MESSAGING_GROUP = "MessagingGroup"
    }
}

/** Renders a conversation on an Android builder, and finds conversations on screen. */
internal class ChatRenderer(private val context: Context) {

    private val bitmaps = BitmapUtils.getInstance()

    fun render(
        conversation: ChatConversation,
        isGroup: Boolean,
        notificationId: Int?,
        builder: NotificationCompat.Builder
    ) {
        val me = person(conversation.me)
        val style = NotificationCompat.MessagingStyle(me)

        // The history is what the notification on screen already shows.
        val previous = if (conversation.replaceHistory || notificationId == null) emptyList()
        else activeStyle(notificationId)?.messages.orEmpty()
        val messages = previous + NotificationCompat.MessagingStyle.Message(
            conversation.message.text,
            conversation.message.timestampMillis,
            if (conversation.message.sender.key == conversation.me.key) null
            else person(conversation.message.sender)
        )
        messages.takeLast(ChatKeys.MAX_MESSAGES).forEach { style.addMessage(it) }

        if (isGroup) {
            style.setConversationTitle(conversation.title)
            style.setGroupConversation(true)
        }
        builder.setStyle(style)
        builder.setCategory(NotificationCompat.CATEGORY_MESSAGE)
        builder.addExtras(Bundle().apply {
            putString(ChatKeys.EXTRA_CONVERSATION_ID, conversation.id)
        })
        markReplyActions(builder)

        if (conversation.shortcut && publishShortcut(conversation, isGroup)) {
            builder.setShortcutId(conversation.id)
            builder.setLocusId(LocusIdCompat(conversation.id))
        }
    }

    /** Adds the user's reply to the conversation on screen (no new alert). */
    fun addReply(conversationId: String, message: ChatMessage): Boolean {
        val active = activeConversation(conversationId) ?: return false
        val style = NotificationCompat.MessagingStyle
            .extractMessagingStyleFromNotification(active.notification) ?: return false
        style.addMessage(NotificationCompat.MessagingStyle.Message(message.text, message.timestampMillis, null as Person?))
        while (style.messages.size > ChatKeys.MAX_MESSAGES) style.messages.removeAt(0)
        val builder = NotificationCompat.Builder(context, active.notification)
            .setStyle(style)
            .setOnlyAlertOnce(true)
        manager().notify(active.id, builder.build())
        return true
    }

    fun activeConversationIds(): List<String> =
        manager().activeNotifications
            .mapNotNull { it.notification.extras?.getString(ChatKeys.EXTRA_CONVERSATION_ID) }
            .distinct()

    fun dismissConversation(conversationId: String) {
        manager().activeNotifications
            .filter { it.notification.extras?.getString(ChatKeys.EXTRA_CONVERSATION_ID) == conversationId }
            .forEach { manager().cancel(it.id) }
    }

    fun removeShortcut(conversationId: String) {
        // Long-lived (cached) and dynamic: the conversation's data goes too.
        ShortcutManagerCompat.removeLongLivedShortcuts(context, listOf(conversationId))
        ShortcutManagerCompat.removeDynamicShortcuts(context, listOf(conversationId))
    }

    // MARK: - Helpers

    private fun activeConversation(conversationId: String) =
        manager().activeNotifications.firstOrNull {
            it.notification.extras?.getString(ChatKeys.EXTRA_CONVERSATION_ID) == conversationId
        }

    private fun activeStyle(id: Int): NotificationCompat.MessagingStyle? {
        val notification = manager().activeNotifications.firstOrNull { it.id == id }?.notification
            ?: return null
        return NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification)
    }

    private fun person(person: ChatPerson): Person {
        val builder = Person.Builder()
            .setKey(person.key)
            .setName(person.name)
            .setBot(person.isBot)
            .setImportant(person.isImportant)
        person.uri?.let { builder.setUri(it) }
        avatar(person.avatar)?.let { builder.setIcon(IconCompat.createWithBitmap(it)) }
        return builder.build()
    }

    private fun avatar(source: String?): Bitmap? {
        if (source.isNullOrEmpty()) return null
        return bitmaps.getBitmapFromSource(context, source)?.let { circle(it) }
    }

    /** Publishes (or updates) the long-lived conversation shortcut. */
    private fun publishShortcut(conversation: ChatConversation, isGroup: Boolean): Boolean {
        return try {
            val label = conversation.displayName(isGroup)
            val people = (if (isGroup) conversation.participants
            else listOf(conversation.message.sender).filter { it.key != conversation.me.key })
                .map { person(it) }
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent()
            launch.action = Intent.ACTION_VIEW
            launch.data = Uri.parse("awn-chat://conversation/" + Uri.encode(conversation.id))
            val icon = avatar(if (isGroup) conversation.image else conversation.message.sender.avatar)
            val shortcut = ShortcutInfoCompat.Builder(context, conversation.id)
                .setShortLabel(label)
                .setLongLived(true)
                .setIntent(launch)
                .setLocusId(LocusIdCompat(conversation.id))
                .setPersons(people.toTypedArray())
                .setIsConversation()
                .apply { icon?.let { setIcon(IconCompat.createWithAdaptiveBitmap(it)) } }
                .build()
            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
            true
        } catch (_: Exception) {
            // A shortcut limit or an OEM restriction: still a MessagingStyle notification.
            false
        }
    }

    /** Typed-reply buttons are marked as replies (smart replies, Wear OS). */
    private fun markReplyActions(builder: NotificationCompat.Builder) {
        val actions = builder.mActions
        for (i in actions.indices) {
            val action = actions[i]
            if (action.remoteInputs.isNullOrEmpty()) continue
            actions[i] = NotificationCompat.Action.Builder(action)
                .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_REPLY)
                .setShowsUserInterface(false)
                .build()
        }
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

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Suppress("unused")
    private val sdk = Build.VERSION.SDK_INT
}
