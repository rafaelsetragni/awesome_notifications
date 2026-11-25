package me.carda.awesome_notifications

import android.content.Context

/**
 * The Dart callback handles a killed app needs: the background isolate's entry
 * point (`awesomeDartBGHandle`, sent on initialize) and the app's
 * `onActionReceivedMethod` (`actionHandle`, sent by setListeners). Kept on
 * disk, as 0.12 did, so they outlive the process.
 */
internal object ActionHandles {
    private const val PREFERENCES = "me.carda.awesome_notifications.handles"
    const val BACKGROUND_HANDLE = "awesomeDartBGHandle"
    const val ACTION_HANDLE = "actionHandle"

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun save(context: Context, key: String, handle: Long?) {
        preferences(context).edit().apply {
            if (handle == null || handle == 0L) remove(key) else putLong(key, handle)
        }.apply()
    }

    fun get(context: Context, key: String): Long = preferences(context).getLong(key, 0L)
}
