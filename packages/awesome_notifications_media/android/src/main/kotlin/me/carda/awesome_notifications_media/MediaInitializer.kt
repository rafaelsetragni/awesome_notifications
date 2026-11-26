package me.carda.awesome_notifications_media

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Installs the media decorator when the app's process starts, before any
 * Flutter engine: a media notification built or used with the app closed
 * (a schedule firing, a control tapped after the app was killed) still needs it.
 */
class MediaInitializer : ContentProvider() {
    override fun onCreate(): Boolean {
        AwesomeNotificationsMediaPlugin.install()
        return true
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?): Int = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?): Int = 0
}
