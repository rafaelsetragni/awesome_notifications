package me.carda.awesome_notifications_localizations

import android.content.Context

/**
 * Stores the current language code (persisted in SharedPreferences). Mirrors the
 * original AndroidAwnCore LocalizationManager: default is the system locale,
 * normalized to lowercase.
 */
class LocalizationManager private constructor() {
    companion object {
        private const val PREFS = "awn_localizations"
        private const val KEY = "languageCode"

        @Volatile
        private var instance: LocalizationManager? = null

        fun getInstance(): LocalizationManager =
            instance ?: synchronized(this) {
                instance ?: LocalizationManager().also { instance = it }
            }
    }

    private var appContext: Context? = null

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    fun setLocalization(languageCode: String?): Boolean {
        val context = appContext ?: return false
        val code = (languageCode ?: systemLanguage(context)).lowercase()
        prefs(context).edit().putString(KEY, code).apply()
        return true
    }

    fun getLocalization(): String {
        val context = appContext ?: return "en"
        val fallback = systemLanguage(context)
        return prefs(context).getString(KEY, fallback) ?: fallback
    }

    private fun systemLanguage(context: Context): String {
        @Suppress("DEPRECATION")
        val locale = context.resources.configuration.locale
        return locale.toLanguageTag().lowercase()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
