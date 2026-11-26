package me.carda.awesome_notifications_live_activities

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Installs the live activities decorator when the app's process starts,
 * before any Flutter engine: an activity pushed by FCM, or swiped away, with
 * the app killed.
 */
class LiveInitializer : ContentProvider() {
    override fun onCreate(): Boolean {
        AwesomeNotificationsLiveActivitiesPlugin.install()
        return true
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?): Int = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?): Int = 0
}
