package me.carda.awesome_notifications_chat

import android.content.Context
import android.os.Build
import me.carda.android_awn_core.AwesomeMethodHandler

/** Answers the AwesomeNotificationsChat channel methods. */
internal class ChatMethodHandler(private val context: Context) : AwesomeMethodHandler {

    override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean =
        handle(method, arguments, result) { _, _, _ -> result(null) }

    override fun handle(
        method: String,
        arguments: Any?,
        result: (Any?) -> Unit,
        error: (code: String, message: String?, details: Any?) -> Unit
    ): Boolean {
        val renderer = ChatRenderer(context)
        when (method) {
            ChatKeys.METHOD_ADD_REPLY -> {
                val args = arguments as? Map<*, *>
                val id = args?.get(ChatKeys.ID) as? String
                val message = ChatMessage.from(args?.get(ChatKeys.MESSAGE))
                if (id.isNullOrBlank() || message == null) {
                    error(
                        ChatKeys.CODE_INVALID_ARGUMENTS, "addReply needs a conversation id and a message",
                        ChatKeys.DETAILED_INVALID_ARGUMENTS + ".addReply"
                    )
                } else {
                    result(renderer.addReply(id, message))
                }
            }
            ChatKeys.METHOD_MARK_AS_READ -> {
                (arguments as? String)?.let { renderer.dismissConversation(it) }
                result(true)
            }
            ChatKeys.METHOD_REMOVE_CONVERSATION -> {
                (arguments as? String)?.let {
                    renderer.dismissConversation(it)
                    renderer.removeShortcut(it)
                }
                result(true)
            }
            ChatKeys.METHOD_LIST_ACTIVE -> result(renderer.activeConversationIds())
            ChatKeys.METHOD_CAPABILITIES -> result(
                mapOf(
                    "history" to true,
                    "reply" to true,
                    "avatar" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P),
                    "systemConversation" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                )
            )
            else -> return false
        }
        return true
    }
}
