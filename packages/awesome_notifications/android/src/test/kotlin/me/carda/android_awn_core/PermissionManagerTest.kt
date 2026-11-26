package me.carda.android_awn_core

import android.app.NotificationManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlarmManager

/** 0.12.1 `getPermissionStatuses` on Android (Android 8+ rules). */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PermissionManagerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val core = AwesomeNotifications(context)

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        ChannelManager.clearForTest()
        manager().notificationChannels.forEach { manager().deleteNotificationChannel(it.id) }
        shadowOf(manager()).setNotificationsEnabled(true)
        // A device answers the app's importance (Robolectric defaults to none).
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_DEFAULT)
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
    }

    @After fun tearDown() = ChannelManager.clearForTest()

    private fun channel(key: String, vararg extra: Pair<String, Any?>) = core.setChannel(
        mapOf(
            Definitions.NOTIFICATION_CHANNEL_KEY to key,
            Definitions.NOTIFICATION_CHANNEL_NAME to key
        ) + mapOf(*extra)
    )

    private fun statuses(channelKey: String?, vararg permissions: String) =
        core.getPermissionStatuses(channelKey, permissions.toList())

    @Test fun appWideStatuses() {
        val result = statuses(
            null, "Alert", "Sound", "Badge", "Vibration", "Light", "CriticalAlert",
            "Provisional", "Car", "FullScreenIntent", "PreciseAlarms"
        )
        assertEquals(
            mapOf(
                "Alert" to "granted",
                "Sound" to "granted",
                "Badge" to "granted",
                "Vibration" to "granted",
                "Light" to "granted",
                "CriticalAlert" to "granted",
                "Provisional" to "notSupported",
                "Car" to "notSupported",
                // Not declared in the manifest, and never a rationale on Android 8+.
                "FullScreenIntent" to "denied",
                "PreciseAlarms" to "granted"
            ),
            result
        )
    }

    @Test fun soundNeedsTheAppsImportance() {
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_LOW)
        assertEquals("notDetermined", statuses(null, "Sound")["Sound"])
    }

    @Test fun aMissingPermissionIsNotDeterminedOnAndroid8Plus() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        assertEquals("notDetermined", statuses(null, "PreciseAlarms")["PreciseAlarms"])
    }

    @Test fun channelStatusesFollowTheAndroidChannel() {
        channel("low", Definitions.NOTIFICATION_IMPORTANCE to "Low")
        assertEquals(
            mapOf(
                "Alert" to "notDetermined",
                "Sound" to "notDetermined", // under IMPORTANCE_DEFAULT
                "Vibration" to "notDetermined",
                "CriticalAlert" to "notDetermined",
                "Badge" to "notDetermined" // 0.12 channels have no badge by default
            ),
            statuses("low", "Alert", "Sound", "Vibration", "CriticalAlert", "Badge")
        )

        channel("high", Definitions.NOTIFICATION_IMPORTANCE to "High",
            Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS to true)
        assertEquals(
            mapOf("Alert" to "granted", "Sound" to "granted", "CriticalAlert" to "granted"),
            statuses("high", "Alert", "Sound", "CriticalAlert")
        )

        channel("silent", Definitions.NOTIFICATION_IMPORTANCE to "High",
            Definitions.NOTIFICATION_PLAY_SOUND to false)
        assertEquals("notDetermined", statuses("silent", "Sound")["Sound"])
    }

    @Test fun aDisabledChannelAllowsNothing() {
        channel("off", Definitions.NOTIFICATION_IMPORTANCE to "None")
        val result = statuses("off", "Alert", "Badge", "PreciseAlarms")
        assertEquals("notDetermined", result["Alert"])
        assertEquals("notDetermined", result["Badge"])
        assertEquals("notDetermined", result["PreciseAlarms"])
    }

    @Test fun quirkWithNotificationsOffEverythingIsNotDetermined() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val result = statuses(null, "Alert", "Sound", "FullScreenIntent", "Provisional")
        assertEquals("notDetermined", result["Alert"])
        assertEquals("notDetermined", result["Sound"])
        assertEquals("notDetermined", result["FullScreenIntent"])
        assertEquals("notSupported", result["Provisional"])
    }

    @Test fun quirkAnUnknownPermissionIsNotDetermined() {
        assertEquals("notDetermined", statuses(null, "Whatever")["Whatever"])
    }

    @Test fun anUnknownChannelThrows() {
        try {
            statuses("nope", "Alert")
            fail("expected an exception")
        } catch (e: AwesomeNotificationsException) {
            assertEquals("INVALID_ARGUMENTS", e.code)
            assertEquals("Channel nope does not exist.", e.message)
            assertEquals("arguments.invalid.channel.key", e.detailedCode)
        }
    }

    @Test fun aForceUpdatedChannelIsFoundByItsPrefix() {
        // 0.12 force-updated channels have the id "<key>_<hash>".
        val channel = android.app.NotificationChannel(
            "legacy_abc", "Legacy", NotificationManager.IMPORTANCE_HIGH)
        manager().createNotificationChannel(channel)
        assertEquals("granted", statuses("legacy", "Alert")["Alert"])
    }

    @Test fun safeNameParsing() {
        assertEquals(NotificationPermission.Provisional, NotificationPermission.fromSafeName("Provisional"))
        assertEquals(NotificationPermission.PreciseAlarms, NotificationPermission.fromSafeName("PreciseAlarms"))
        assertEquals(NotificationPermission.Car, NotificationPermission.fromSafeName("Car"))
        assertEquals(NotificationPermission.CriticalAlert, NotificationPermission.fromSafeName("CriticalAlert"))
        assertNull(NotificationPermission.fromSafeName(""))
        assertNull(NotificationPermission.fromName("alert"))
        assertEquals(NotificationPermission.Alert, NotificationPermission.fromName(" Alert "))
    }
}
