package me.carda.awesome_notifications_localizations

import me.carda.android_awn_core.NotificationContentTransformer
import java.util.Locale

/**
 * Content transformer that translates the notification at build time, using the
 * `localizations` map carried by the model and the current language. Mirrors the
 * original `setCurrentTranslation`: pick the matching locale (with fallback) and
 * overwrite the content's title/body/summary/largeIcon/bigPicture.
 *
 * The core builder runs this without knowing it exists — the decorator seam.
 */
class LocalizationTransformer(
    private val manager: LocalizationManager
) : NotificationContentTransformer {

    @Suppress("UNCHECKED_CAST")
    override fun transform(model: Map<String, Any?>): Map<String, Any?> {
        val localizations = model[LOCALIZATIONS] as? Map<String, Any?> ?: return model
        if (localizations.isEmpty()) return model

        val matched = matchLanguage(localizations.keys, manager.getLocalization()) ?: return model
        val localization = localizations[matched] as? Map<String, Any?> ?: return model

        val content = (model[CONTENT] as? Map<String, Any?>)?.toMutableMap() ?: return model
        for (key in TRANSLATABLE) {
            (localization[key] as? String)?.let { if (it.isNotEmpty()) content[key] = it }
        }

        return model.toMutableMap().apply { this[CONTENT] = content }
    }

    /** exact → key-as-prefix → code-as-prefix (e.g. "pt-br" falls back to "pt"). */
    private fun matchLanguage(keys: Set<String>, languageCode: String): String? {
        val code = languageCode.lowercase(Locale.ROOT)
        keys.firstOrNull { it.lowercase(Locale.ROOT) == code }?.let { return it }

        val normalized = code.replace("-", "_")
        var keyPrefix: String? = null
        var codePrefix: String? = null
        for (key in keys.sortedDescending()) {
            val lowerKey = key.lowercase(Locale.ROOT).replace("-", "_")
            if (lowerKey == normalized) return key
            if (lowerKey.startsWith("${normalized}_")) keyPrefix = key
            else if (normalized.startsWith("${lowerKey}_")) codePrefix = key
        }
        return keyPrefix ?: codePrefix
    }

    private companion object {
        const val LOCALIZATIONS = "localizations"
        const val CONTENT = "content"
        val TRANSLATABLE = listOf("title", "body", "summary", "largeIcon", "bigPicture")
    }
}
