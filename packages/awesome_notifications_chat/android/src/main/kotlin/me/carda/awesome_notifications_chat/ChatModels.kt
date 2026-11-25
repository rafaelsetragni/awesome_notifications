package me.carda.awesome_notifications_chat

import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** A participant, parsed from the `conversation` block. */
internal data class ChatPerson(
    val key: String,
    val name: String,
    val avatar: String?,
    val uri: String?,
    val isBot: Boolean,
    val isImportant: Boolean
) {
    companion object {
        fun from(map: Any?): ChatPerson? {
            val m = map as? Map<*, *> ?: return null
            val key = (m[ChatKeys.KEY] as? String)?.takeIf { it.isNotBlank() } ?: return null
            val name = (m[ChatKeys.NAME] as? String)?.takeIf { it.isNotBlank() } ?: return null
            return ChatPerson(
                key, name,
                m[ChatKeys.AVATAR] as? String,
                m[ChatKeys.URI] as? String,
                m[ChatKeys.IS_BOT] == true,
                m[ChatKeys.IS_IMPORTANT] == true
            )
        }
    }
}

internal data class ChatMessage(val sender: ChatPerson, val text: String, val timestampMillis: Long) {
    companion object {
        fun from(map: Any?): ChatMessage? {
            val m = map as? Map<*, *> ?: return null
            val sender = ChatPerson.from(m[ChatKeys.SENDER]) ?: return null
            val text = (m[ChatKeys.TEXT] as? String)?.takeIf { it.isNotBlank() } ?: return null
            return ChatMessage(sender, text, parseUtc(m[ChatKeys.TIMESTAMP] as? String))
        }

        /** "yyyy-MM-dd HH:mm:ss" in UTC (the plugin's date format); now when absent. */
        fun parseUtc(text: String?): Long {
            if (text.isNullOrEmpty()) return System.currentTimeMillis()
            return try {
                SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
                    .apply { timeZone = TimeZone.getTimeZone("UTC") }
                    .parse(text)?.time ?: System.currentTimeMillis()
            } catch (_: Exception) {
                System.currentTimeMillis()
            }
        }
    }
}

internal data class ChatConversation(
    val id: String,
    val me: ChatPerson,
    val message: ChatMessage,
    val title: String?,
    val participants: List<ChatPerson>,
    val image: String?,
    val replaceHistory: Boolean,
    val shortcut: Boolean
) {
    /** One-to-one: the person on the other side (the sender, unless it is me). */
    fun displayName(isGroup: Boolean): String =
        if (isGroup && !title.isNullOrEmpty()) title else message.sender.name

    companion object {
        /**
         * Parses and validates the block like the Dart side (push messages never
         * pass through Dart). Returns the conversation or the error message.
         */
        fun parse(block: Any?, isGroup: Boolean): Pair<ChatConversation?, String?> {
            val m = block as? Map<*, *> ?: return null to "The conversation is not a map"
            val id = (m[ChatKeys.ID] as? String)?.takeIf { it.isNotBlank() }
                ?: return null to "The conversation needs a non-empty id"
            val me = ChatPerson.from(m[ChatKeys.ME])
                ?: return null to "The conversation needs a person (key and name) as me"
            val message = ChatMessage.from(m[ChatKeys.MESSAGE])
                ?: return null to "The conversation needs a message with a sender (key and name) and a text"
            val rawParticipants = m[ChatKeys.PARTICIPANTS] as? List<*> ?: emptyList<Any?>()
            val participants = rawParticipants.map {
                ChatPerson.from(it) ?: return null to "Every participant needs a key and a name"
            }
            val keys = mutableSetOf(me.key)
            for (person in participants) {
                if (!keys.add(person.key))
                    return null to "The person key \"${person.key}\" is repeated in the conversation"
            }
            val title = (m[ChatKeys.TITLE] as? String)?.takeIf { it.isNotBlank() }
            if (isGroup && title == null)
                return null to "A MessagingGroup conversation needs a title"
            if (isGroup && participants.isEmpty())
                return null to "A MessagingGroup conversation needs its participants"
            return ChatConversation(
                id, me, message, title, participants,
                m[ChatKeys.IMAGE] as? String,
                m[ChatKeys.HISTORY] == ChatKeys.HISTORY_REPLACE,
                m[ChatKeys.SHORTCUT] != false
            ) to null
        }
    }
}
