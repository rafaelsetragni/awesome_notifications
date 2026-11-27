package me.carda.awesome_notifications_chat

import android.app.NotificationManager
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationBuilderRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** A binding with only the application context (the plugin uses nothing else). */
internal fun pluginBinding(context: Context): FlutterPlugin.FlutterPluginBinding {
    val constructor = FlutterPlugin.FlutterPluginBinding::class.java.declaredConstructors
        .first { it.parameterTypes.firstOrNull() == Context::class.java }
    constructor.isAccessible = true
    val args = constructor.parameterTypes.mapIndexed { i, _ -> if (i == 0) context else null }
    return constructor.newInstance(*args.toTypedArray()) as FlutterPlugin.FlutterPluginBinding
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ChatPluginTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    private fun answer(method: String, arguments: Any? = null): Pair<Boolean, Any?> {
        var value: Any? = null
        val handled = AwesomeMethodHandlerRegistry.handle(method, arguments, { value = it })
        return handled to value
    }

    @Test fun attachingAnswersTheChatMethodsUntilDetached() {
        val plugin = AwesomeNotificationsChatPlugin()
        val binding = pluginBinding(context)
        plugin.onAttachedToEngine(binding)
        try {
            assertTrue(NotificationBuilderRegistry.makeBuilder() is ChatBuilder)
            val (handled, value) = answer(ChatKeys.METHOD_LIST_ACTIVE)
            assertTrue(handled)
            assertEquals(emptyList<String>(), value)
        } finally {
            plugin.onDetachedFromEngine(binding)
        }
        assertFalse(answer(ChatKeys.METHOD_LIST_ACTIVE).first)
        // Detaching twice is harmless.
        plugin.onDetachedFromEngine(binding)
    }

    @Test fun theInitializerInstallsTheDecoratorAndIsAnInertProvider() {
        val provider = ChatInitializer()
        assertTrue(provider.onCreate())
        assertTrue(NotificationBuilderRegistry.makeBuilder() is ChatBuilder)
        val uri = Uri.parse("content://chat")
        assertNull(provider.query(uri, null, null, null, null))
        assertNull(provider.getType(uri))
        assertNull(provider.insert(uri, ContentValues()))
        assertEquals(0, provider.delete(uri, null, null))
        assertEquals(0, provider.update(uri, ContentValues(), null, null))
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ChatMethodHandlerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val handler = ChatMethodHandler(context)
    private val core = AwesomeNotifications(context, Executor { it.run() })

    private val me = mapOf("key" to "u-1", "name" to "Rafael")
    private val ana = mapOf("key" to "u-2", "name" to "Ana")

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        AwesomeNotificationsChatPlugin.install()
        manager().cancelAll()
        ShortcutManagerCompat.removeAllDynamicShortcuts(context)
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "chat", Definitions.NOTIFICATION_CHANNEL_NAME to "Chat")
        )
    }

    private fun create(
        id: Int,
        conversationId: String,
        sender: Map<String, Any?> = ana,
        buttons: List<Map<String, Any?>>? = null
    ): Boolean? {
        val model = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_CONTENT to mapOf(
                Definitions.NOTIFICATION_ID to id,
                Definitions.NOTIFICATION_CHANNEL_KEY to "chat",
                Definitions.NOTIFICATION_LAYOUT to "Messaging"
            ),
            ChatKeys.CONVERSATION to mapOf(
                "id" to conversationId, "me" to me,
                "message" to mapOf("sender" to sender, "text" to "Oi")
            )
        )
        if (buttons != null) model[Definitions.NOTIFICATION_BUTTONS] = buttons
        var created: Boolean? = null
        core.createNotification(model, onError = { _, _, _ -> created = false }) { created = it }
        shadowOf(Looper.getMainLooper()).idle()
        return created
    }

    private data class Call(val handled: Boolean, val value: Any?, val error: Triple<String, String?, Any?>?)

    private fun call(method: String, arguments: Any?): Call {
        var value: Any? = null
        var error: Triple<String, String?, Any?>? = null
        val handled = handler.handle(method, arguments, { value = it }) { code, message, details ->
            error = Triple(code, message, details)
        }
        return Call(handled, value, error)
    }

    @Test fun addReplyWithoutAnIdOrAMessageFails() {
        for (args in listOf(
            null,
            mapOf("message" to mapOf("sender" to me, "text" to "Ok")),
            mapOf("id" to " ", "message" to mapOf("sender" to me, "text" to "Ok")),
            mapOf("id" to "family"),
            mapOf("id" to "family", "message" to mapOf("sender" to me, "text" to " "))
        )) {
            val call = call(ChatKeys.METHOD_ADD_REPLY, args)
            assertTrue(call.handled)
            assertNull(call.value)
            assertEquals("INVALID_ARGUMENTS", call.error!!.first)
            assertEquals("addReply needs a conversation id and a message", call.error!!.second)
            assertEquals("arguments.invalid.addReply", call.error!!.third)
        }
    }

    @Test fun withoutAnErrorCallbackAFailureAnswersNull() {
        var answered = false
        var value: Any? = "unset"
        assertTrue(handler.handle(ChatKeys.METHOD_ADD_REPLY, null) { answered = true; value = it })
        assertTrue(answered)
        assertNull(value)
    }

    @Test fun addReplyToAConversationNotOnScreenAnswersFalse() {
        val call = call(ChatKeys.METHOD_ADD_REPLY, mapOf("id" to "nobody", "message" to mapOf("sender" to me, "text" to "Ok")))
        assertEquals(false, call.value)
        assertNull(call.error)
    }

    @Test fun listActiveConversationsIsWhatIsOnScreen() {
        assertEquals(emptyList<String>(), call(ChatKeys.METHOD_LIST_ACTIVE, null).value)
        create(1, "family")
        create(2, "work")
        create(3, "family")
        assertEquals(setOf("family", "work"), (call(ChatKeys.METHOD_LIST_ACTIVE, null).value as List<*>).toSet())
        assertEquals(2, (call(ChatKeys.METHOD_LIST_ACTIVE, null).value as List<*>).size)
    }

    @Test fun markAsReadAndRemoveIgnoreANonStringId() {
        create(1, "family")
        assertEquals(true, call(ChatKeys.METHOD_MARK_AS_READ, 42).value)
        assertEquals(true, call(ChatKeys.METHOD_REMOVE_CONVERSATION, null).value)
        assertEquals(listOf(1), manager().activeNotifications.map { it.id })
    }

    @Test fun capabilitiesOnAndroid14() {
        val caps = call(ChatKeys.METHOD_CAPABILITIES, null).value
        assertEquals(
            mapOf("history" to true, "reply" to true, "avatar" to true, "systemConversation" to true),
            caps
        )
    }

    @Config(sdk = [28])
    @Test fun capabilitiesOnAndroid9HaveNoSystemConversation() {
        @Suppress("UNCHECKED_CAST")
        val caps = call(ChatKeys.METHOD_CAPABILITIES, null).value as Map<String, Any?>
        assertEquals(true, caps["avatar"])
        assertEquals(false, caps["systemConversation"])
    }

    @Test fun otherMethodsAreNotAnswered() {
        val call = call("createNotification", null)
        assertFalse(call.handled)
        assertNull(call.value)
        assertNull(call.error)
    }

    @Test fun aTypedReplyButtonIsMarkedAsAReply() {
        create(1, "family", buttons = listOf(
            mapOf(Definitions.NOTIFICATION_BUTTON_KEY to "REPLY", Definitions.NOTIFICATION_BUTTON_LABEL to "Reply",
                Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT to true),
            mapOf(Definitions.NOTIFICATION_BUTTON_KEY to "READ", Definitions.NOTIFICATION_BUTTON_LABEL to "Read")
        ))
        val notification = manager().activeNotifications.single().notification
        val reply = NotificationCompat.getAction(notification, 0)!!
        val read = NotificationCompat.getAction(notification, 1)!!
        assertEquals("Reply", reply.title.toString())
        assertEquals(NotificationCompat.Action.SEMANTIC_ACTION_REPLY, reply.semanticAction)
        assertFalse(reply.showsUserInterface)
        assertEquals("Read", read.title.toString())
        assertEquals(NotificationCompat.Action.SEMANTIC_ACTION_NONE, read.semanticAction)
    }

    @Test fun theSendersAvatarIsTheShortcutsIcon() {
        val file = File(context.cacheDir, "ana.png")
        file.outputStream().use {
            Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888).compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        assertEquals(true, create(1, "family", sender = ana + mapOf("avatar" to "file://" + file.absolutePath)))
        val shortcut = ShortcutManagerCompat.getDynamicShortcuts(context).single()
        assertEquals("family", shortcut.id)
        assertEquals("family", manager().activeNotifications.single().notification.shortcutId)
    }
}

class ChatModelsTest {

    private val me = mapOf("key" to "u-1", "name" to "Rafael")
    private val ana = mapOf("key" to "u-2", "name" to "Ana")
    private val message = mapOf("sender" to ana, "text" to "Oi")

    private fun error(block: Any?, isGroup: Boolean = false): String? {
        val (conversation, error) = ChatConversation.parse(block, isGroup)
        assertNull(conversation)
        return error
    }

    @Test fun theConversationIsValidatedLikeDart() {
        assertEquals("The conversation is not a map", error("family"))
        assertEquals("The conversation needs a non-empty id", error(mapOf("id" to " ", "me" to me, "message" to message)))
        assertEquals("The conversation needs a person (key and name) as me",
            error(mapOf("id" to "f", "me" to mapOf("key" to "u-1"), "message" to message)))
        assertEquals("The conversation needs a message with a sender (key and name) and a text",
            error(mapOf("id" to "f", "me" to me, "message" to mapOf("sender" to ana))))
        assertEquals("Every participant needs a key and a name",
            error(mapOf("id" to "f", "me" to me, "message" to message, "participants" to listOf(mapOf("name" to "X")))))
        assertEquals("The person key \"u-1\" is repeated in the conversation",
            error(mapOf("id" to "f", "me" to me, "message" to message, "participants" to listOf(me))))
    }

    @Test fun theDefaultsOfAValidConversation() {
        val (conversation, error) = ChatConversation.parse(
            mapOf("id" to "f", "me" to me, "message" to message, "image" to "asset://g.png"), false
        )
        assertNull(error)
        conversation!!
        assertEquals("asset://g.png", conversation.image)
        assertFalse(conversation.replaceHistory)
        assertTrue(conversation.shortcut)
        assertEquals("Ana", conversation.displayName(isGroup = true)) // no title: the sender
    }

    @Test fun anUnreadableTimestampIsNow() {
        val before = System.currentTimeMillis()
        val parsed = ChatMessage.parseUtc("yesterday")
        assertTrue(parsed in before..System.currentTimeMillis())
        assertTrue(ChatMessage.parseUtc(null) >= before)
        assertEquals(0L, ChatMessage.parseUtc("1970-01-01 00:00:00"))
    }

    @Test fun aMessageNeedsAMap() {
        assertNull(ChatMessage.from("Oi"))
        assertNull(ChatMessage.from(mapOf("text" to "Oi")))
    }
}
