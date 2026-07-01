package me.carda.awesome_notifications_localizations

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationContentTransformer
import java.util.Locale

/**
 * Content transformer that translates the notification at build time. Mirrors the
 * original core `setCurrentTranslation`:
 *
 *  1. Resolve `titleLocKey`/`bodyLocKey` against the app's localized string
 *     resources for the current language (applying `titleLocArgs`/`bodyLocArgs`).
 *  2. Override title/body/summary/largeIcon/bigPicture and the action button
 *     labels from the matching entry of the model's `localizations` map (this
 *     takes precedence over the loc-key result).
 *
 * The core builder runs this without knowing it exists — the decorator seam.
 */
class LocalizationTransformer(
    private val manager: LocalizationManager
) : NotificationContentTransformer {

    @Suppress("UNCHECKED_CAST")
    override fun transform(model: Map<String, Any?>): Map<String, Any?> {
        val content = (model[CONTENT] as? Map<String, Any?>)?.toMutableMap()
            ?: return model
        val languageCode = manager.getLocalization()

        // 1. Loc keys → localized string resources for the current language.
        applyLocKeys(content, languageCode)

        // 2. localizations block (overrides the loc-key result).
        var translatedButtons: List<Map<String, Any?>>? = null
        val localizations = localizationsMap(model)
        if (!localizations.isNullOrEmpty()) {
            val matched = matchLanguage(localizations.keys, languageCode)
            val localization = matched?.let { localizations[it] as? Map<String, Any?> }
            if (localization != null) {
                for (key in TRANSLATABLE) {
                    (localization[key] as? String)?.let {
                        if (it.isNotEmpty()) content[key] = it
                    }
                }
                translatedButtons = translateButtonLabels(localization, model)
            }
        }

        val result = model.toMutableMap()
        result[CONTENT] = content
        translatedButtons?.let { result[BUTTONS] = it }
        return result
    }

    /** Replaces title/body with the app's localized string resource referenced by
     *  `titleLocKey`/`bodyLocKey`, formatting it with the matching `*LocArgs`. */
    @Suppress("UNCHECKED_CAST")
    private fun applyLocKeys(content: MutableMap<String, Any?>, languageCode: String) {
        val context = manager.context() ?: return
        val resources = getLocalizedResources(context, languageCode)
        resolveLocKey(context, resources,
            content[TITLE_LOC_KEY] as? String,
            content[TITLE_LOC_ARGS] as? List<Any?>)?.let { content[TITLE] = it }
        resolveLocKey(context, resources,
            content[BODY_LOC_KEY] as? String,
            content[BODY_LOC_ARGS] as? List<Any?>)?.let { content[BODY] = it }
    }

    private fun resolveLocKey(
        context: Context,
        resources: Resources,
        locKey: String?,
        locArgs: List<Any?>?
    ): String? {
        if (locKey.isNullOrEmpty()) return null
        return try {
            val id = context.resources.getIdentifier(locKey, "string", context.packageName)
            if (id == 0) return null
            // Convert iOS-style "%@" placeholders (not escaped) to "%s".
            var localized = resources.getString(id).replace(Regex("(?<!\\\\)%@"), "%s")
            locArgs?.forEach { arg -> localized = String.format(localized, arg.toString()) }
            localized.ifEmpty { null }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    /** Builds a Resources bound to [languageCode] instead of the device locale. */
    private fun getLocalizedResources(context: Context, languageCode: String): Resources {
        val parts = languageCode.split("-")
        val language = parts[0].lowercase(Locale.ROOT)
        val country = if (parts.size > 1) parts[1].uppercase(Locale.ROOT) else ""
        val locale = if (country.isEmpty()) Locale(language) else Locale(language, country)
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        return context.createConfigurationContext(config).resources
    }

    /** The `localizations` block, accepting either a Map or — for push/JSON
     *  payloads where it arrives JSON-encoded — a JSON string. */
    @Suppress("UNCHECKED_CAST")
    private fun localizationsMap(model: Map<String, Any?>): Map<String, Any?>? {
        return when (val raw = model[LOCALIZATIONS]) {
            is Map<*, *> -> raw as Map<String, Any?>
            is String -> try {
                JsonUtils.getInstance().fromJson(raw)
            } catch (e: Exception) {
                null
            }
            else -> null
        }
    }

    /** Overrides each action button's label from the localization's `buttonLabels`
     *  map (keyed by the button key); returns null when there is nothing to do. */
    @Suppress("UNCHECKED_CAST")
    private fun translateButtonLabels(
        localization: Map<String, Any?>,
        model: Map<String, Any?>
    ): List<Map<String, Any?>>? {
        val buttonLabels = localization[BUTTON_LABELS] as? Map<String, Any?>
        if (buttonLabels.isNullOrEmpty()) return null
        val buttons = model[BUTTONS] as? List<Map<String, Any?>> ?: return null
        return buttons.map { button ->
            val key = button[BUTTON_KEY] as? String
            val label = buttonLabels[key] as? String
            if (key != null && !label.isNullOrEmpty()) {
                button.toMutableMap().apply { this[BUTTON_LABEL] = label }
            } else {
                button
            }
        }
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
        const val TITLE = "title"
        const val BODY = "body"
        const val TITLE_LOC_KEY = "titleLocKey"
        const val BODY_LOC_KEY = "bodyLocKey"
        const val TITLE_LOC_ARGS = "titleLocArgs"
        const val BODY_LOC_ARGS = "bodyLocArgs"
        const val BUTTONS = "actionButtons"
        const val BUTTON_KEY = "key"
        const val BUTTON_LABEL = "label"
        const val BUTTON_LABELS = "buttonLabels"
        val TRANSLATABLE = listOf("title", "body", "summary", "largeIcon", "bigPicture")
    }
}
