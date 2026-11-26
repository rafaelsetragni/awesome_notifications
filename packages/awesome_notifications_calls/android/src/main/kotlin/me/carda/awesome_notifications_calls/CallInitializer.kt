package me.carda.awesome_notifications_calls

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Installs the calls decorator when the app's process starts, before any
 * Flutter engine: a call pushed by FCM, its buttons and its ring timeout run
 * with the app killed.
 */
class CallInitializer : ContentProvider() {
    override fun onCreate(): Boolean {
        AwesomeNotificationsCallsPlugin.install()
        return true
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?): Int = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?): Int = 0
}
