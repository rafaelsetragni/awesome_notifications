package me.carda.android_awn_core

import android.app.Notification
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Android-framework paths of [NotificationBuilder]: building a real
 * [Notification] and the decorator-chain entry point [NotificationBuilder.build]
 * (which stamps the created/displayed lifecycle on the immediate-delivery path).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NotificationBuilderContentTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val builder = NotificationBuilder.getNewBuilder()

    private fun model(vararg content: Pair<String, Any?>): Map<String, Any?> =
        mapOf(Definitions.NOTIFICATION_CONTENT to mapOf(*content))

    @Test fun buildsNotificationWithTitleAndBody() {
        val notification = builder.createNotificationContent(
            context,
            model(
                Definitions.NOTIFICATION_ID to 1,
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_TITLE to "Title",
                Definitions.NOTIFICATION_BODY to "Body"
            )
        )
        assertNotNull(notification)
        assertEquals("Title", notification!!.extras.getString(Notification.EXTRA_TITLE))
        assertEquals("Body", notification.extras.getString(Notification.EXTRA_TEXT))
    }

    @Test fun nullWhenIdMissing() {
        assertNull(
            builder.createNotificationContent(
                context, model(Definitions.NOTIFICATION_CHANNEL_KEY to "ch")
            )
        )
    }

    @Test fun nullWhenChannelKeyMissing() {
        assertNull(
            builder.createNotificationContent(
                context, model(Definitions.NOTIFICATION_ID to 1)
            )
        )
    }

    @Test fun buildPostsAndStampsLifecycle() {
        val outcome = builder.build(
            context,
            model(
                Definitions.NOTIFICATION_ID to 1,
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_TITLE to "T"
            )
        )
        assertTrue(outcome is BuildOutcome.Post)
        val post = outcome as BuildOutcome.Post
        assertEquals(1, post.id)
        // Immediate path bakes created + displayed into the stored model.
        val content = builder.contentMap(post.model)
        assertNotNull(content[Definitions.NOTIFICATION_CREATED_DATE])
        assertNotNull(content[Definitions.NOTIFICATION_DISPLAYED_DATE])
        assertEquals("Local", content[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertEquals("Foreground", content[Definitions.NOTIFICATION_CREATED_LIFECYCLE])
    }

    @Test fun buildInvalidWhenIdMissing() {
        val outcome = builder.build(
            context, model(Definitions.NOTIFICATION_CHANNEL_KEY to "ch")
        )
        assertEquals(BuildOutcome.Invalid, outcome)
    }
}
