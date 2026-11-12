package me.carda.android_awn_core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pure map-logic of [NotificationBuilder]: lifecycle stamping (the persistence
 * that makes created/displayed round-trip to the action), the event stampers, and
 * the action-type / dismiss decision helpers. Android-framework paths
 * (createNotificationContent, PendingIntents, images) are covered separately.
 */
class NotificationBuilderTest {

    private val builder = NotificationBuilder.getNewBuilder()

    private fun modelWithContent(content: Map<String, Any?>): Map<String, Any?> =
        mapOf(Definitions.NOTIFICATION_CONTENT to content)

    // --- content extraction ---

    @Test fun contentMapAndId() {
        val model = modelWithContent(mapOf(Definitions.NOTIFICATION_ID to 5))
        assertEquals(5, builder.notificationId(model))
        assertEquals(5, builder.contentMap(model)[Definitions.NOTIFICATION_ID])
    }

    @Test fun contentMapEmptyWhenMissing() {
        assertTrue(builder.contentMap(emptyMap()).isEmpty())
        assertNull(builder.notificationId(emptyMap()))
    }

    // --- created lifecycle stamping ---

    @Test fun stampCreatedAddsFieldsWithSource() {
        val stamped = builder.stampCreatedLifecycle(
            modelWithContent(mapOf(Definitions.NOTIFICATION_ID to 1)),
            source = NotificationSource.Schedule
        )
        val content = builder.contentMap(stamped)
        assertEquals("Schedule", content[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertEquals("Foreground", content[Definitions.NOTIFICATION_CREATED_LIFECYCLE])
        assertNotNull(content[Definitions.NOTIFICATION_CREATED_DATE])
    }

    @Test fun stampCreatedIsNoOpWhenAlreadyStamped() {
        val stamped = builder.stampCreatedLifecycle(
            modelWithContent(
                mapOf(
                    Definitions.NOTIFICATION_ID to 1,
                    Definitions.NOTIFICATION_CREATED_DATE to "2020-01-01 00:00:00",
                    Definitions.NOTIFICATION_CREATED_SOURCE to "Local"
                )
            ),
            source = NotificationSource.Schedule
        )
        val content = builder.contentMap(stamped)
        // Date already present → the created block is preserved (source stays Local).
        assertEquals("Local", content[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertEquals("2020-01-01 00:00:00", content[Definitions.NOTIFICATION_CREATED_DATE])
    }

    // --- displayed lifecycle stamping ---

    @Test fun stampDisplayedSetsFields() {
        val stamped = builder.stampDisplayedLifecycle(
            modelWithContent(mapOf(Definitions.NOTIFICATION_ID to 1)),
            displayedDate = "2020-01-01 00:00:00",
            lifeCycle = NotificationLifeCycle.Background
        )
        val content = builder.contentMap(stamped)
        assertEquals("2020-01-01 00:00:00", content[Definitions.NOTIFICATION_DISPLAYED_DATE])
        assertEquals("Background", content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE])
    }

    @Test fun nowUtcIsFormatted() {
        // yyyy-MM-dd HH:mm:ss, 19 chars.
        assertEquals(19, builder.nowUtc().length)
    }

    // --- event stampers ---

    @Test fun registerCreatedPreservesExistingSource() {
        val out = builder.registerCreatedEvent(
            mapOf(Definitions.NOTIFICATION_CREATED_SOURCE to "Schedule"),
            NotificationLifeCycle.Foreground
        )
        assertEquals("Schedule", out[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertNotNull(out[Definitions.NOTIFICATION_CREATED_DATE])
    }

    @Test fun registerCreatedDefaultsSourceToLocal() {
        val out = builder.registerCreatedEvent(emptyMap(), NotificationLifeCycle.Foreground)
        assertEquals("Local", out[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertEquals("Foreground", out[Definitions.NOTIFICATION_CREATED_LIFECYCLE])
    }

    @Test fun registerDisplayedStamps() {
        val out = builder.registerDisplayedEvent(emptyMap(), NotificationLifeCycle.Background)
        assertEquals("Background", out[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE])
        assertNotNull(out[Definitions.NOTIFICATION_DISPLAYED_DATE])
    }

    @Test fun registerActionStampsTypeAndLifecycle() {
        val out = builder.registerActionEvent(
            emptyMap(), NotificationLifeCycle.Background, ActionType.KeepOnTop
        )
        assertEquals("KeepOnTop", out[Definitions.NOTIFICATION_ACTION_TYPE])
        assertEquals("Background", out[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
        assertNotNull(out[Definitions.NOTIFICATION_ACTION_DATE])
    }

    @Test fun registerDismissedStamps() {
        val out = builder.registerDismissedEvent(emptyMap(), NotificationLifeCycle.Foreground)
        assertEquals("Foreground", out[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
        assertNotNull(out[Definitions.NOTIFICATION_DISMISSED_DATE])
    }

    // --- action-type / dismiss decisions ---

    @Test fun buttonActionTypeParses() {
        assertEquals(
            ActionType.DismissAction,
            builder.buttonActionType(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "DismissAction"))
        )
        assertEquals(ActionType.Default, builder.buttonActionType(null))
    }

    @Test fun isDismissActionOnContent() {
        assertTrue(
            builder.isDismissAction(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "DismissAction"))
        )
        assertFalse(
            builder.isDismissAction(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "Default"))
        )
    }

    @Test fun shouldButtonAutoDismissRules() {
        assertTrue(
            builder.shouldButtonAutoDismiss(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "DismissAction"))
        )
        assertFalse(
            builder.shouldButtonAutoDismiss(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "KeepOnTop"))
        )
        assertFalse(
            builder.shouldButtonAutoDismiss(mapOf(Definitions.NOTIFICATION_AUTO_DISMISSIBLE to false))
        )
        assertTrue(builder.shouldButtonAutoDismiss(emptyMap())) // default true
    }

    @Test fun shouldAutoDismissContentRules() {
        assertTrue(
            builder.shouldAutoDismiss(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "DismissAction"))
        )
        assertFalse(
            builder.shouldAutoDismiss(mapOf(Definitions.NOTIFICATION_ACTION_TYPE to "KeepOnTop"))
        )
        assertTrue(builder.shouldAutoDismiss(emptyMap())) // default true
    }

    // --- misc ---

    @Test fun readId() {
        assertEquals(9, builder.readId(mapOf(Definitions.NOTIFICATION_ID to 9)))
        assertNull(builder.readId(emptyMap()))
    }

    @Test fun findButtonByKey() {
        val model = mapOf(
            Definitions.NOTIFICATION_BUTTONS to
                listOf(mapOf(Definitions.NOTIFICATION_BUTTON_KEY to "A"))
        )
        assertNotNull(builder.findButton(model, "A"))
        assertNull(builder.findButton(model, "B"))
        assertNull(builder.findButton(model, ""))
    }

    @Test fun actionButtonsEmptyWhenAbsent() {
        assertTrue(builder.actionButtons(emptyMap()).isEmpty())
    }
}
