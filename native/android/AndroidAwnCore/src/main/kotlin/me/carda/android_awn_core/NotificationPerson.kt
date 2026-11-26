package me.carda.android_awn_core

import android.content.Context
import android.graphics.Bitmap
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat

/**
 * A person in a notification (who sends a message, who is calling…), shared by
 * the add-ons that show people (chat, calls). Parsed from the map the Dart
 * person serializes to: `key`, `name`, `avatar`, `uri`, `isBot`, `isImportant`.
 */
data class NotificationPerson(
    val key: String,
    val name: String,
    /** A media reference (`https://`, `asset://`, `file://`, `resource://`). */
    val avatar: String?,
    val uri: String?,
    val isBot: Boolean,
    val isImportant: Boolean
) {
    /**
     * The androidx [Person]: key, name, bot, important, the uri when given and
     * the avatar, circle-cropped, as its icon (when it loads). Loading the
     * avatar does I/O: call off the main thread.
     */
    fun toPerson(
        context: Context,
        bitmapUtils: BitmapUtils = BitmapUtils.getInstance()
    ): Person {
        val builder = Person.Builder()
            .setKey(key)
            .setName(name)
            .setBot(isBot)
            .setImportant(isImportant)
        uri?.let { builder.setUri(it) }
        avatarBitmap(context, bitmapUtils)?.let { builder.setIcon(IconCompat.createWithBitmap(it)) }
        return builder.build()
    }

    /** The avatar, circle-cropped, or null when there is none or it does not load. */
    fun avatarBitmap(
        context: Context,
        bitmapUtils: BitmapUtils = BitmapUtils.getInstance()
    ): Bitmap? {
        if (avatar.isNullOrEmpty()) return null
        return bitmapUtils.getBitmapFromSource(context, avatar)?.let { bitmapUtils.circleCrop(it) }
    }

    companion object {
        const val KEY = "key"
        const val NAME = "name"
        const val AVATAR = "avatar"
        const val URI = "uri"
        const val IS_BOT = "isBot"
        const val IS_IMPORTANT = "isImportant"

        /**
         * Parses a person map. Null unless it is a map with a non-blank `key`
         * and a non-blank `name`; `avatar` / `uri` count only as Strings,
         * `isBot` / `isImportant` only as `true`.
         */
        fun from(map: Any?): NotificationPerson? {
            val m = map as? Map<*, *> ?: return null
            val key = (m[KEY] as? String)?.takeIf { it.isNotBlank() } ?: return null
            val name = (m[NAME] as? String)?.takeIf { it.isNotBlank() } ?: return null
            return NotificationPerson(
                key, name,
                m[AVATAR] as? String,
                m[URI] as? String,
                m[IS_BOT] == true,
                m[IS_IMPORTANT] == true
            )
        }
    }
}
