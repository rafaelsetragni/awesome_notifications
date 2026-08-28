package me.carda.awesome_notifications_fcm

import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.NotificationLifeCycle
import me.carda.android_awn_core.NotificationSource
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Test

class SilentDataModelTest {

    @Test
    fun `fromData extracts the envelope and keeps custom data`() {
        val model = SilentDataModel().fromData(
            mapOf(
                Definitions.NOTIFICATION_ID to "42",
                Definitions.NOTIFICATION_CREATED_SOURCE to "Firebase",
                Definitions.NOTIFICATION_CREATED_LIFECYCLE to "Background",
                "orderId" to "999"
            )
        )

        assertEquals(42, model.id)
        assertEquals(NotificationSource.Firebase, model.createdSource)
        assertEquals(NotificationLifeCycle.Background, model.createdLifeCycle)
        assertEquals("999", model.data["orderId"])
        assertNotNull(model.createdDate)
    }

    @Test
    fun `internal routing keys are not surfaced as data`() {
        val model = SilentDataModel().fromData(
            mapOf(
                FcmDefinitions.SILENT_HANDLE to "123",
                "keep" to "me"
            )
        )
        assertFalse(model.data.containsKey(FcmDefinitions.SILENT_HANDLE))
        assertEquals("me", model.data["keep"])
    }

    @Test
    fun `toMap and toJson round-trip the envelope`() {
        val model = SilentDataModel().fromData(
            mapOf(Definitions.NOTIFICATION_ID to "5", "k" to "v")
        )
        val map = model.toMap()
        assertEquals("5", map[Definitions.NOTIFICATION_ID])
        assertEquals("Firebase", map[Definitions.NOTIFICATION_CREATED_SOURCE])
        assertEquals("v", map["k"])

        val restored = SilentDataModel().fromJson(model.toJson())
        assertEquals(5, restored.id)
        assertEquals("v", restored.data["k"])
    }
}
