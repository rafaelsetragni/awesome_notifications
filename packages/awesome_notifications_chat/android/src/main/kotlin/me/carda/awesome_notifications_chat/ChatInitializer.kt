package me.carda.awesome_notifications_chat

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Installs the chat decorator when the app's process starts, before any
 * Flutter engine: a push that arrives with the app closed is built natively
 * by the FCM service, and still needs the conversation rendering.
 */
class ChatInitializer : ContentProvider() {
    override fun onCreate(): Boolean {
        AwesomeNotificationsChatPlugin.install()
        return true
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?): Int = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?): Int = 0
}
