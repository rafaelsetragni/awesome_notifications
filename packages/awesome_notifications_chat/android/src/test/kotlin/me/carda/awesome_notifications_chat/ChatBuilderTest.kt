package me.carda.awesome_notifications_chat

import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilderRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ChatBuilderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context, Executor { it.run() })
    private val handler = ChatMethodHandler(context)

    private val me = mapOf("key" to "u-1", "name" to "Rafael")
    private val ana = mapOf("key" to "u-2", "name" to "Ana", "isImportant" to true)
    private val bia = mapOf("key" to "u-3", "name" to "Bia")

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        // The registry is process-wide (and clearing it is internal to the core).
        if (!registered) {
            registered = true
            NotificationBuilderRegistry.register(AwesomeNotificationsChatPlugin.PRIORITY) { ChatBuilder(it) }
        }
        manager().cancelAll()
        ShortcutManagerCompat.removeAllDynamicShortcuts(context)
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "chat", Definitions.NOTIFICATION_CHANNEL_NAME to "Chat")
        )
    }

    companion object {
        private var registered = false
    }

    private data class Outcome(val created: Boolean?, val code: String?, val detail: String?)

    private fun create(
        id: Int,
        layout: String? = "Messaging",
        conversation: Map<String, Any?>? = conversation(),
        content: Map<String, Any?> = emptyMap()
    ): Outcome {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "chat"
        )
        if (layout != null) c[Definitions.NOTIFICATION_LAYOUT] = layout
        c.putAll(content)
        val model = mutableMapOf<String, Any?>(Definitions.NOTIFICATION_CONTENT to c)
        if (conversation != null) model[ChatKeys.CONVERSATION] = conversation
        var outcome = Outcome(null, null, null)
        core.createNotification(model, onError = { code, _, details -> outcome = Outcome(null, code, details) }) {
            outcome = Outcome(it, null, null)
        }
        shadowOf(Looper.getMainLooper()).idle()
        return outcome
    }

    private fun conversation(
        text: String = "Chegando",
        sender: Map<String, Any?> = ana,
        title: String? = null,
        participants: List<Map<String, Any?>> = listOf(ana),
        history: String = "append",
        id: String = "family"
    ) = mapOf(
        "id" to id,
        "me" to me,
        "message" to mapOf("sender" to sender, "text" to text, "timestamp" to "2026-11-25 10:30:00"),
        "title" to title,
        "participants" to participants,
        "history" to history,
        "shortcut" to true
    )

    private fun style(id: Int) = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(
        manager().activeNotifications.first { it.id == id }.notification
    )!!

    @Test fun messagingLayoutsRequireAConversation() {
        val outcome = create(1, conversation = null)
        assertEquals("INVALID_ARGUMENTS", outcome.code)
        assertEquals("arguments.invalid.notificationConversation", outcome.detail)
        assertTrue(manager().activeNotifications.isEmpty())
    }

    @Test fun aConversationRequiresAMessagingLayout() {
        assertEquals("INVALID_ARGUMENTS", create(1, layout = null).code)
        assertEquals("INVALID_ARGUMENTS", create(2, layout = "BigPicture").code)
    }

    @Test fun aGroupNeedsATitleAndParticipants() {
        assertEquals("INVALID_ARGUMENTS", create(1, layout = "MessagingGroup").code)
        assertEquals(
            "INVALID_ARGUMENTS",
            create(2, layout = "MessagingGroup", conversation = conversation(title = "Família", participants = emptyList())).code
        )
    }

    @Test fun otherNotificationsAreUntouched() {
        assertEquals(true, create(1, layout = null, conversation = null).created)
    }

    @Test fun aMessageIsAnAndroidConversation() {
        assertEquals(true, create(1).created)
        val notification = manager().activeNotifications.single().notification
        val style = style(1)
        assertEquals("Rafael", style.user.name.toString())
        assertEquals(listOf("Chegando"), style.messages.map { it.text.toString() })
        assertEquals("Ana", style.messages.single().person?.name.toString())
        assertEquals("u-2", style.messages.single().person?.key)
        assertEquals(NotificationCompat.CATEGORY_MESSAGE, notification.category)
        assertEquals("family", notification.shortcutId)
        assertEquals(listOf("family"), ShortcutManagerCompat.getDynamicShortcuts(context).map { it.id })
    }

    @Test fun theTitleBodyAndPayloadAreFilled() {
        create(1)
        val extras = manager().activeNotifications.single().notification.extras
        assertEquals("Ana", extras.getCharSequence(NotificationCompat.EXTRA_TITLE).toString())
        assertEquals(listOf("family"), handler.let { ChatRenderer(context).activeConversationIds() })
    }

    @Test fun aGroupHasItsTitleAndAllSenders() {
        create(1, layout = "MessagingGroup", conversation = conversation(title = "Família", participants = listOf(ana, bia)))
        create(1, layout = "MessagingGroup", conversation = conversation(title = "Família", participants = listOf(ana, bia), sender = bia, text = "Eu também"))
        val style = style(1)
        assertEquals("Família", style.conversationTitle.toString())
        assertTrue(style.isGroupConversation)
        assertEquals(listOf("Ana", "Bia"), style.messages.map { it.person?.name.toString() })
    }

    @Test fun historyAppendsOrReplaces() {
        create(1, conversation = conversation(text = "um"))
        create(1, conversation = conversation(text = "dois"))
        assertEquals(listOf("um", "dois"), style(1).messages.map { it.text.toString() })
        create(1, conversation = conversation(text = "três", history = "replace"))
        assertEquals(listOf("três"), style(1).messages.map { it.text.toString() })
    }

    @Test fun historyKeepsTheLast25() {
        repeat(30) { create(1, conversation = conversation(text = "m$it")) }
        val texts = style(1).messages.map { it.text.toString() }
        assertEquals(25, texts.size)
        assertEquals("m29", texts.last())
    }

    @Test fun addReplyAddsTheUsersMessage() {
        create(1)
        var answer: Any? = null
        handler.handle(
            ChatKeys.METHOD_ADD_REPLY,
            mapOf("id" to "family", "message" to mapOf("sender" to me, "text" to "Ok!")),
            { answer = it }
        )
        assertEquals(true, answer)
        val messages = style(1).messages
        assertEquals(listOf("Chegando", "Ok!"), messages.map { it.text.toString() })
        assertNull(messages.last().person) // the user
    }

    @Test fun markAsReadAndRemoveConversation() {
        create(1)
        create(2, conversation = conversation(id = "work"))
        handler.handle(ChatKeys.METHOD_MARK_AS_READ, "family", {})
        assertEquals(listOf(2), manager().activeNotifications.map { it.id })
        handler.handle(ChatKeys.METHOD_REMOVE_CONVERSATION, "work", {})
        assertTrue(manager().activeNotifications.isEmpty())
        assertEquals(listOf("family"), ShortcutManagerCompat.getDynamicShortcuts(context).map { it.id })
    }
}
