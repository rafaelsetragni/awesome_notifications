package me.carda.awesome_notifications

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import me.carda.android_awn_core.BackgroundActions

/**
 * Installs the background action executor when the app's process starts,
 * before any Flutter engine: a button pressed with the app killed starts the
 * process only for its receiver.
 */
class AwesomeNotificationsInitializer : ContentProvider() {
    override fun onCreate(): Boolean {
        BackgroundActions.executor = ActionBackgroundExecutor
        return true
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?): Int = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?): Int = 0
}
