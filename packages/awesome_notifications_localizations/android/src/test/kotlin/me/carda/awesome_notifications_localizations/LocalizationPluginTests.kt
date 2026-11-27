package me.carda.awesome_notifications_localizations

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationBuilderRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** A builder at the end of the chain that only records the model it got. */
private class CapturingBuilder : NotificationBuilder() {
    var model: Map<String, Any?>? = null
    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        this.model = model
        return BuildOutcome.Handled
    }
}

/** The Flutter plugin: decorator + method handler wiring. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocalizationPluginTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    /** The binding only needs the application context here (built reflectively:
     *  its constructor takes engine objects this plugin never touches). */
    private fun binding(): FlutterPlugin.FlutterPluginBinding {
        val constructor = FlutterPlugin.FlutterPluginBinding::class.java.declaredConstructors
            .first { it.parameterTypes.firstOrNull() == Context::class.java }
        constructor.isAccessible = true
        val args = constructor.parameterTypes.mapIndexed { i, _ -> if (i == 0) context else null }
        return constructor.newInstance(*args.toTypedArray()) as FlutterPlugin.FlutterPluginBinding
    }

    private fun answer(method: String, arguments: Any? = null): Pair<Boolean, Any?> {
        var value: Any? = null
        val handled = AwesomeMethodHandlerRegistry.handle(method, arguments, { value = it })
        return handled to value
    }

    @Test fun attachingInstallsTheDecoratorAndTheMethodsUntilDetached() {
        val plugin = AwesomeNotificationsLocalizationsPlugin()
        val binding = binding()
        plugin.onAttachedToEngine(binding)
        try {
            // The localization decorator is the outermost builder (priority 100).
            assertTrue(NotificationBuilderRegistry.makeBuilder() is LocalizationBuilder)

            assertEquals(true to true, answer("setLocalization", "DE"))
            assertEquals(true to "de", answer("getLocalization"))
        } finally {
            plugin.onDetachedFromEngine(binding)
        }
        // Only this engine's handler goes away.
        assertFalse(answer("getLocalization").first)
    }
}

/** The builder decorator: translates, then hands over to the wrapped builder. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocalizationBuilderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val manager = LocalizationManager.getInstance()

    @Before fun init() {
        manager.init(context)
    }

    @Suppress("UNCHECKED_CAST")
    @Test fun theWrappedBuilderGetsTheTranslatedModel() {
        manager.setLocalization("pt-br")
        val inner = CapturingBuilder()
        val builder = LocalizationBuilder(inner, LocalizationTransformer(manager))
        val model = mapOf(
            "content" to mapOf("id" to 1, "title" to "Hello"),
            "localizations" to mapOf("pt-br" to mapOf("title" to "Olá"))
        )

        val outcome = builder.build(context, model)

        assertSame(BuildOutcome.Handled, outcome)
        assertEquals("Olá", (inner.model!!["content"] as Map<String, Any?>)["title"])
    }
}

/** Loc keys resolved against the app's (here: androidx's) string resources. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocalizationLocKeyTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val manager = LocalizationManager.getInstance()
    private val transformer = LocalizationTransformer(manager)

    @Before fun init() {
        manager.init(context)
    }

    @Suppress("UNCHECKED_CAST")
    private fun content(out: Map<String, Any?>) = out["content"] as Map<String, Any?>

    @Test fun locKeysAreResolvedInTheCurrentLanguage() {
        manager.setLocalization("pt-br")
        val out = transformer.transform(mapOf("content" to mapOf(
            "id" to 1, "title" to "Hello", "body" to "World",
            "titleLocKey" to "call_notification_answer_action",
            "bodyLocKey" to "call_notification_incoming_text",
            // No placeholder in the string: the args leave it unchanged.
            "bodyLocArgs" to listOf("ignored")
        )))
        assertEquals("Atender", content(out)["title"])
        assertEquals("Chamada recebida", content(out)["body"])
    }

    @Test fun anotherLanguageResolvesItsOwnTranslation() {
        manager.setLocalization("es")
        val out = transformer.transform(mapOf("content" to mapOf(
            "id" to 1, "title" to "Hello", "titleLocKey" to "call_notification_answer_action"
        )))
        assertEquals("Responder", content(out)["title"])
    }

    @Test fun theLocalizationsBlockWinsOverTheLocKey() {
        manager.setLocalization("pt-br")
        val out = transformer.transform(mapOf(
            "content" to mapOf("id" to 1, "titleLocKey" to "call_notification_answer_action"),
            "localizations" to mapOf("pt-br" to mapOf("title" to "Do bloco"))
        ))
        assertEquals("Do bloco", content(out)["title"])
    }

    @Test fun aLocKeyThatFailsToFormatKeepsTheOriginalText() {
        manager.setLocalization("pt-br")
        val broken = object {
            override fun toString(): String = throw IllegalStateException("unprintable")
        }
        val out = transformer.transform(mapOf("content" to mapOf(
            "id" to 1, "title" to "Hello",
            "titleLocKey" to "call_notification_answer_action",
            "titleLocArgs" to listOf(broken)
        )))
        assertEquals("Hello", content(out)["title"])
    }

    @Test fun aModelWithoutContentIsReturnedAsIs() {
        val model = mapOf<String, Any?>("localizations" to mapOf("en" to mapOf("title" to "x")))
        assertSame(model, transformer.transform(model))
    }
}
