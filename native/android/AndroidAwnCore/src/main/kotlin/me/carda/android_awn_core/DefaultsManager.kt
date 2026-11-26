package me.carda.android_awn_core

import android.content.Context

/**
 * The app's defaults that must outlive the process (0.12 `DefaultsManager`):
 * the `defaultIcon` given to `initialize`, read by every notification built
 * later, also with the app killed (a push, a schedule).
 */
object DefaultsManager {

    private const val PREFERENCES = "awesome_notifications_defaults"
    private const val KEY_DEFAULT_ICON = "defaultIcon"

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    /** 0.12: `initialize` always stores it, so a null clears an earlier one. */
    fun setDefaultIcon(context: Context, icon: String?) {
        preferences(context).edit().apply {
            if (icon.isNullOrEmpty()) remove(KEY_DEFAULT_ICON) else putString(KEY_DEFAULT_ICON, icon)
        }.apply()
    }

    fun getDefaultIcon(context: Context): String? =
        preferences(context).getString(KEY_DEFAULT_ICON, null)
}
