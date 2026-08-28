package me.carda.awesome_notifications_fcm

import android.content.Context

/**
 * Persists the registered background callback handles and flags so a headless
 * FirebaseMessagingService (which starts with no in-memory state) can spin up the
 * Dart background isolate to deliver silent data while the app is terminated.
 */
object FcmDefaultsManager {
    private const val KEY_DEBUG = "debug"
    private const val KEY_BG_HANDLE = "dartBackgroundHandle"
    private const val KEY_SILENT_HANDLE = "silentCallbackHandle"
    private const val KEY_LAST_TOKEN = "lastFcmToken"

    private fun prefs(context: Context) =
        context.getSharedPreferences(FcmDefinitions.SHARED_FCM_DEFAULTS, Context.MODE_PRIVATE)

    fun saveHandles(
        context: Context,
        dartBackgroundHandle: Long?,
        silentCallbackHandle: Long?,
        debug: Boolean
    ) {
        prefs(context).edit().apply {
            putBoolean(KEY_DEBUG, debug)
            dartBackgroundHandle?.let { putLong(KEY_BG_HANDLE, it) }
            silentCallbackHandle?.let { putLong(KEY_SILENT_HANDLE, it) }
            apply()
        }
    }

    fun getDartBackgroundHandle(context: Context): Long =
        prefs(context).getLong(KEY_BG_HANDLE, 0L)

    fun getSilentCallbackHandle(context: Context): Long =
        prefs(context).getLong(KEY_SILENT_HANDLE, 0L)

    fun isDebug(context: Context): Boolean = prefs(context).getBoolean(KEY_DEBUG, false)

    fun setLastToken(context: Context, token: String?) {
        prefs(context).edit().putString(KEY_LAST_TOKEN, token).apply()
    }

    fun getLastToken(context: Context): String? =
        prefs(context).getString(KEY_LAST_TOKEN, null)
}
