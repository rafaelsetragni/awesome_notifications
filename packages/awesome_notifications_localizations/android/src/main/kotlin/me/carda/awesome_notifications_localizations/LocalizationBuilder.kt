package me.carda.awesome_notifications_localizations

import android.content.Context
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.NotificationBuilder

/**
 * Builder decorator that **translates** a notification before it is built. It
 * inherits the core [NotificationBuilder], overrides [build], runs the
 * [LocalizationTransformer] over the model (loc-keys + the `localizations` block
 * for the current language), then delegates the actual content building to the
 * wrapped builder via [next].
 *
 * Registered with a HIGH priority so it ends up outermost — translation happens
 * before lower-priority decorators (e.g. scheduling) see the model, so the
 * scheduled payload is the already-translated one.
 */
class LocalizationBuilder(
    inner: NotificationBuilder,
    private val transformer: LocalizationTransformer
) : NotificationBuilder(inner) {

    override fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        return next(context, transformer.transform(model))
    }
}
