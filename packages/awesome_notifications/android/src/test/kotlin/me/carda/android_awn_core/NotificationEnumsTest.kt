package me.carda.android_awn_core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

/**
 * The enums are the single source of truth for the strings serialized over the
 * channel. These tests lock the wire values and the tolerant parsers (which
 * accept the plain `.name` and a legacy `"Enum.X"` form, falling back sensibly).
 */
class NotificationEnumsTest {

    // --- Wire names must match the Dart enums exactly ---

    @Test fun sourceNames() {
        assertEquals("Local", NotificationSource.Local.name)
        assertEquals("Schedule", NotificationSource.Schedule.name)
    }

    @Test fun lifeCycleNames() {
        // Terminated, NOT the deprecated "AppKilled" the Dart side no longer parses.
        assertEquals("Foreground", NotificationLifeCycle.Foreground.name)
        assertEquals("Background", NotificationLifeCycle.Background.name)
        assertEquals("Terminated", NotificationLifeCycle.Terminated.name)
    }

    // --- ActionType.from ---

    @Test fun actionTypeParsesExact() {
        assertEquals(ActionType.DismissAction, ActionType.from("DismissAction"))
        assertEquals(ActionType.KeepOnTop, ActionType.from("KeepOnTop"))
        assertEquals(ActionType.SilentBackgroundAction, ActionType.from("SilentBackgroundAction"))
    }

    @Test fun actionTypeParsesLegacyPrefixed() {
        assertEquals(ActionType.KeepOnTop, ActionType.from("ActionType.KeepOnTop"))
    }

    @Test fun actionTypeFallsBackToDefault() {
        assertEquals(ActionType.Default, ActionType.from(null))
        assertEquals(ActionType.Default, ActionType.from(""))
        assertEquals(ActionType.Default, ActionType.from("Bogus"))
    }

    // --- NotificationImportance ---

    @Test fun importanceParsesCaseInsensitiveAndPrefixed() {
        assertEquals(NotificationImportance.High, NotificationImportance.from("High"))
        assertEquals(NotificationImportance.High, NotificationImportance.from("high"))
        assertEquals(NotificationImportance.Min, NotificationImportance.from("NotificationImportance.Min"))
        assertEquals(NotificationImportance.Default, NotificationImportance.from(null))
        assertEquals(NotificationImportance.Default, NotificationImportance.from("nope"))
    }

    @Test fun importanceMapsToAndroidConstants() {
        // High and Max share the same Android importance; None differs from Default.
        assertEquals(
            NotificationImportance.High.toAndroidImportance(),
            NotificationImportance.Max.toAndroidImportance()
        )
        assertNotEquals(
            NotificationImportance.None.toAndroidImportance(),
            NotificationImportance.Default.toAndroidImportance()
        )
    }

    // --- NotificationLayout ---

    @Test fun layoutParses() {
        assertEquals(NotificationLayout.BigPicture, NotificationLayout.from("BigPicture"))
        assertEquals(NotificationLayout.Default, NotificationLayout.from("NotificationLayout.Default"))
        assertEquals(NotificationLayout.Default, NotificationLayout.from(null))
        assertEquals(NotificationLayout.Default, NotificationLayout.from("Nope"))
    }

    // --- MediaSourcePrefix ---

    @Test fun mediaPrefixValues() {
        assertEquals("resource://", MediaSourcePrefix.RESOURCE)
        assertEquals("asset://", MediaSourcePrefix.ASSET)
        assertEquals("file://", MediaSourcePrefix.FILE)
        assertEquals("https://", MediaSourcePrefix.NETWORK_HTTPS)
    }
}
