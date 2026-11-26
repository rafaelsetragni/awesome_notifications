package me.carda.awesome_notifications_chat

/** Keys of the `conversation` block (same names as the Dart `ChatKeys`). */
internal object ChatKeys {
    const val CONVERSATION = "conversation"

    const val ID = "id"
    const val TITLE = "title"
    const val ME = "me"
    const val MESSAGE = "message"
    const val PARTICIPANTS = "participants"
    const val IMAGE = "image"
    const val HISTORY = "history"
    const val SHORTCUT = "shortcut"

    // A person's keys: see the core's NotificationPerson.

    const val SENDER = "sender"
    const val TEXT = "text"
    const val TIMESTAMP = "timestamp"

    const val HISTORY_REPLACE = "replace"

    /** Added to the content payload: which conversation an action came from. */
    const val CONVERSATION_ID = "conversationId"
    /** Extra of the posted notification, to find a conversation on screen. */
    const val EXTRA_CONVERSATION_ID = "awn.chat.conversationId"

    const val METHOD_ADD_REPLY = "chatAddReply"
    const val METHOD_MARK_AS_READ = "chatMarkAsRead"
    const val METHOD_REMOVE_CONVERSATION = "chatRemoveConversation"
    const val METHOD_LIST_ACTIVE = "chatListActiveConversations"
    const val METHOD_CAPABILITIES = "chatCapabilities"

    // 0.12 exception codes
    const val CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    const val DETAILED_INVALID_ARGUMENTS = "arguments.invalid"

    /** Android's MessagingStyle keeps at most this many messages. */
    const val MAX_MESSAGES = 25
}
