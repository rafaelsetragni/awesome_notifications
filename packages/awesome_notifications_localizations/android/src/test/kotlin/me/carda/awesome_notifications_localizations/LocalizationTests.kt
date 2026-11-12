package me.carda.awesome_notifications_localizations

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The current-language store (persisted in SharedPreferences). */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocalizationManagerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val manager = LocalizationManager.getInstance()

    @Before fun init() {
        manager.init(context)
    }

    @Test fun setAndGetPersists() {
        assertTrue(manager.setLocalization("zh"))
        assertEquals("zh", manager.getLocalization())
    }

    @Test fun codeIsLowercased() {
        manager.setLocalization("PT-BR")
        assertEquals("pt-br", manager.getLocalization())
    }

    @Test fun nullFallsBackToSystemLanguage() {
        manager.setLocalization(null)
        val language = manager.getLocalization()
        assertTrue(language.isNotEmpty())
        assertEquals(language.lowercase(), language)
    }
}

/**
 * Build-time translation: the `localizations` block overrides content and button
 * labels for the current language (with prefix fallback), and tolerates the block
 * arriving as a JSON string (push path).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocalizationTransformerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val manager = LocalizationManager.getInstance()
    private val transformer = LocalizationTransformer(manager)

    @Before fun init() {
        manager.init(context)
    }

    private fun model(localizations: Any?): Map<String, Any?> = buildMap {
        put("content", mapOf("id" to 1, "title" to "Hello"))
        put("actionButtons", listOf(mapOf("key" to "YES", "label" to "Yes")))
        if (localizations != null) put("localizations", localizations)
    }

    @Suppress("UNCHECKED_CAST")
    private fun title(out: Map<String, Any?>): Any? =
        (out["content"] as Map<String, Any?>)["title"]

    @Test fun translatesTitleAndButtonLabel() {
        manager.setLocalization("pt-br")
        val out = transformer.transform(
            model(mapOf("pt-br" to mapOf("title" to "Olá", "buttonLabels" to mapOf("YES" to "Sim"))))
        )
        assertEquals("Olá", title(out))
        @Suppress("UNCHECKED_CAST")
        val buttons = out["actionButtons"] as List<Map<String, Any?>>
        assertEquals("Sim", buttons[0]["label"])
    }

    @Test fun fallsBackByLanguagePrefix() {
        manager.setLocalization("pt-br")
        val out = transformer.transform(model(mapOf("pt" to mapOf("title" to "OlaPt"))))
        assertEquals("OlaPt", title(out))
    }

    @Test fun unmatchedLanguageLeavesTitleUntouched() {
        manager.setLocalization("fr")
        val out = transformer.transform(model(mapOf("pt-br" to mapOf("title" to "Olá"))))
        assertEquals("Hello", title(out))
    }

    @Test fun noLocalizationsReturnsUnchanged() {
        manager.setLocalization("pt-br")
        assertEquals("Hello", title(transformer.transform(model(null))))
    }

    @Test fun localizationsAsJsonStringIsDecoded() {
        manager.setLocalization("pt-br")
        val out = transformer.transform(model("{\"pt-br\":{\"title\":\"OlaJson\"}}"))
        assertEquals("OlaJson", title(out))
    }
}
