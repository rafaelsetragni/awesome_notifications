package me.carda.android_awn_core

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlarmManager

/**
 * 0.12 `requestUserPermissions` with the app's notifications on (Android
 * 8+): the missing permissions needing a rationale either open their
 * settings page (no manifest permission, or its rationale is due) or ask the
 * system dialog for their manifest permissions; and what is answered after.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PermissionManagerFlowsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var activity: Activity

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        ChannelManager.clearForTest()
        manager().notificationChannels.forEach { manager().deleteNotificationChannel(it.id) }
        shadowOf(manager()).setNotificationsEnabled(true)
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_DEFAULT)
        shadowOf(manager()).setNotificationPolicyAccessGranted(true)
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        PermissionManager.onForeground()
    }

    @After fun tearDown() {
        ChannelManager.clearForTest()
        PermissionManager.onForeground()
    }

    private fun channel(key: String, vararg extra: Pair<String, Any?>) = ChannelManager.setChannel(
        context,
        mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to key, Definitions.NOTIFICATION_CHANNEL_NAME to key) +
            mapOf(*extra)
    )

    /** Something on the device answers [action]. */
    private fun settingsPage(action: String, scheme: String? = null) {
        val component = ComponentName("com.android.settings", action)
        shadowOf(context.packageManager).addActivityIfNotPresent(component)
        shadowOf(context.packageManager).addIntentFilterForActivity(
            component,
            IntentFilter(action).apply {
                addCategory(Intent.CATEGORY_DEFAULT)
                if (scheme != null) addDataScheme(scheme)
            }
        )
    }

    private fun opened(): Intent? =
        shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>()).nextStartedActivity

    private fun request(channelKey: String?, vararg permissions: String, from: Activity? = activity): Array<List<String>?> {
        val answer = arrayOfNulls<List<String>>(1)
        PermissionManager.requestUserPermissions(from, context, channelKey, permissions.toList()) { answer[0] = it }
        return answer
    }

    @Test fun nothingRequestedAnswersRightAway() {
        assertEquals(emptyList<String>(), request(null)[0])
    }

    @Test fun exactAlarmsAskTheSystemDialog() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        val answer = request(null, "PreciseAlarms", "Alert")
        assertNull(answer[0])
        assertEquals(
            listOf(Manifest.permission.SCHEDULE_EXACT_ALARM),
            shadowOf(activity).lastRequestedPermission.requestedPermissions.toList()
        )
        ShadowAlarmManager.setCanScheduleExactAlarms(true)
        PermissionManager.onDialogResult(PermissionManager.REQUEST_CODE)
        assertEquals(emptyList<String>(), answer[0])
    }

    @Test fun anUnknownPermissionAsksForTheNotificationsPermission() {
        val answer = request(null, "Whatever")
        assertEquals(
            listOf(Manifest.permission.POST_NOTIFICATIONS),
            shadowOf(activity).lastRequestedPermission.requestedPermissions.toList()
        )
        PermissionManager.onForeground()
        // Still unknown, so still missing.
        assertEquals(listOf("Whatever"), answer[0])
    }

    @Test fun withoutAnActivityTheManifestPermissionsAreNotAsked() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        val answer = request(null, "PreciseAlarms", from = null)
        assertEquals(listOf("PreciseAlarms"), answer[0])
    }

    @Test fun exactAlarmsWithARationaleDueOpenTheirSettingsPage() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        shadowOf(context.packageManager).setShouldShowRequestPermissionRationale(
            Manifest.permission.SCHEDULE_EXACT_ALARM, true)
        settingsPage(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, "package")

        val answer = request(null, "PreciseAlarms")
        val page = opened()!!
        assertEquals(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, page.action)
        assertEquals("package:" + context.packageName, page.dataString)
        assertEquals(context.packageName, page.getStringExtra(Settings.EXTRA_APP_PACKAGE))
        assertEquals(Intent.FLAG_ACTIVITY_NEW_TASK, page.flags and Intent.FLAG_ACTIVITY_NEW_TASK)
        assertNull(answer[0])
        PermissionManager.onForeground()
        assertEquals(listOf("PreciseAlarms"), answer[0])
    }

    @Test fun exactAlarmsFallBackToTheAppsNotificationPage() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        shadowOf(context.packageManager).setShouldShowRequestPermissionRationale(
            Manifest.permission.SCHEDULE_EXACT_ALARM, true)
        settingsPage(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        request(null, "PreciseAlarms")
        assertEquals(Settings.ACTION_APP_NOTIFICATION_SETTINGS, opened()!!.action)
    }

    @Test fun overrideDnDOpensTheDnDAccessPage() {
        shadowOf(manager()).setNotificationPolicyAccessGranted(false)
        settingsPage(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
        val answer = request(null, "OverrideDnD")
        assertEquals(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS, opened()!!.action)
        shadowOf(manager()).setNotificationPolicyAccessGranted(true)
        PermissionManager.onForeground()
        assertEquals(emptyList<String>(), answer[0])
    }

    @Test fun overrideDnDWithNoPageAnswersRightAway() {
        shadowOf(manager()).setNotificationPolicyAccessGranted(false)
        val answer = request(null, "OverrideDnD")
        assertNull(opened())
        assertEquals(listOf("OverrideDnD"), answer[0])
    }

    @Test fun aChannelPermissionOpensTheChannelsPage() {
        channel("quiet", Definitions.NOTIFICATION_IMPORTANCE to "Low")
        settingsPage(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
        val answer = request("quiet", "Alert")
        val page = opened()!!
        assertEquals(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS, page.action)
        assertEquals("quiet", page.getStringExtra(Settings.EXTRA_CHANNEL_ID))
        assertEquals(context.packageName, page.getStringExtra(Settings.EXTRA_APP_PACKAGE))

        assertNull(answer[0])
        // Back in front with the channel unchanged: still missing.
        PermissionManager.onForeground()
        assertEquals(listOf("Alert"), answer[0])
    }

    @Test fun anAppWideChannelPermissionFallsBackToTheAppsPage() {
        // No channel page on this device: the app's notification page.
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_LOW)
        settingsPage(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        val answer = request(null, "Sound")
        assertEquals(Settings.ACTION_APP_NOTIFICATION_SETTINGS, opened()!!.action)
        PermissionManager.onForeground()
        assertEquals(listOf("Sound"), answer[0])
    }

    @Test fun noPageAtAllAnswersWhatIsMissingRightAway() {
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_LOW)
        val answer = request(null, "Sound", "Badge")
        assertNull(opened())
        assertEquals(listOf("Sound"), answer[0])
    }

    @Test fun aChannelGoneBeforeTheAnswerAnswersEverythingStillRequested() {
        channel("gone", Definitions.NOTIFICATION_IMPORTANCE to "Low")
        settingsPage(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
        val answer = request("gone", "Alert", "Light")
        manager().deleteNotificationChannel("gone")
        PermissionManager.onForeground()
        // The check failed (unknown channel): logged, and nothing removed.
        assertEquals(listOf("Alert"), answer[0])
    }

    @Test fun aChannelAllowsUnlistedPermissionsAndReadsTheDeviceBadgeSetting() {
        channel("plain")
        val statuses = PermissionManager.getPermissionStatuses(
            context, "plain", listOf("PreciseAlarms", "Car", "OverrideDnD"))
        assertEquals("granted", statuses["PreciseAlarms"])
        assertEquals("notSupported", statuses["Car"])
        assertEquals("granted", statuses["OverrideDnD"])

        shadowOf(manager()).setNotificationPolicyAccessGranted(false)
        assertEquals("notDetermined",
            PermissionManager.getPermissionStatuses(context, null, listOf("OverrideDnD"))["OverrideDnD"])

        Settings.Secure.putInt(context.contentResolver, "notification_badging", 0)
        assertEquals("notDetermined",
            PermissionManager.getPermissionStatuses(context, null, listOf("Badge"))["Badge"])
        Settings.Secure.putInt(context.contentResolver, "notification_badging", 1)
        assertEquals("granted",
            PermissionManager.getPermissionStatuses(context, null, listOf("Badge"))["Badge"])
    }
}

/**
 * The same checks and request on Android 7, where channels are only the
 * app's own model: 0.12 kept the channel's settings in step with what the
 * device allows, and only Sound / CriticalAlert / OverrideDnD could need a
 * rationale.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [25])
class PermissionManagerAndroid7Test {

    private val context: Context = ApplicationProvider.getApplicationContext()

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        ChannelManager.clearForTest()
        shadowOf(manager()).setNotificationsEnabled(true)
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_DEFAULT)
        shadowOf(manager()).setNotificationPolicyAccessGranted(true)
        PermissionManager.onForeground()
    }

    @After fun tearDown() {
        ChannelManager.clearForTest()
        PermissionManager.onForeground()
    }

    private fun channel(key: String, vararg extra: Pair<String, Any?>) = ChannelManager.setChannel(
        context,
        mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to key, Definitions.NOTIFICATION_CHANNEL_NAME to key) +
            mapOf(*extra)
    )

    private fun request(channelKey: String?, vararg permissions: String): Array<List<String>?> {
        val answer = arrayOfNulls<List<String>>(1)
        PermissionManager.requestUserPermissions(null, context, channelKey, permissions.toList()) { answer[0] = it }
        return answer
    }

    @Test fun theChannelModelFollowsWhatTheDeviceAllows() {
        channel(
            "ch",
            Definitions.NOTIFICATION_PLAY_SOUND to false,
            Definitions.NOTIFICATION_ENABLE_VIBRATION to false,
            Definitions.NOTIFICATION_ENABLE_LIGHTS to false
        )
        val answer = request(
            "ch", "Alert", "Sound", "Badge", "Vibration", "Light", "CriticalAlert", "FullScreenIntent", "Unknown")

        val updated = ChannelManager.getChannel("ch")!!
        assertEquals("High", updated[Definitions.NOTIFICATION_IMPORTANCE])
        assertEquals(true, updated[Definitions.NOTIFICATION_PLAY_SOUND])
        assertEquals(true, updated[Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE])
        assertEquals(true, updated[Definitions.NOTIFICATION_ENABLE_VIBRATION])
        assertEquals(true, updated[Definitions.NOTIFICATION_ENABLE_LIGHTS])
        assertEquals(true, updated[Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS])
        // Everything allowed now, except the unknown name.
        assertEquals(listOf("Unknown"), answer[0])
    }

    @Test fun channelStatusesReadTheAppsChannelModel() {
        channel(
            "low",
            Definitions.NOTIFICATION_IMPORTANCE to "Low",
            "enableVibration" to false,
            "enableLights" to false,
            "channelShowBadge" to true
        )
        assertEquals(
            mapOf(
                "Alert" to "denied",
                // Allowed device-wide: no rationale before Android 8, so denied.
                "Sound" to "denied",
                "Vibration" to "denied",
                "Light" to "denied",
                "Badge" to "granted",
                "CriticalAlert" to "denied",
                "PreciseAlarms" to "granted"
            ),
            PermissionManager.getPermissionStatuses(
                context, "low",
                listOf("Alert", "Sound", "Vibration", "Light", "Badge", "CriticalAlert", "PreciseAlarms"))
        )

        channel("high", Definitions.NOTIFICATION_IMPORTANCE to "High")
        assertEquals(
            mapOf("Alert" to "granted", "Sound" to "granted", "Vibration" to "granted",
                "Light" to "granted", "Badge" to "denied"),
            PermissionManager.getPermissionStatuses(
                context, "high", listOf("Alert", "Sound", "Vibration", "Light", "Badge"))
        )

        channel("off", Definitions.NOTIFICATION_IMPORTANCE to "None")
        assertEquals("denied",
            PermissionManager.getPermissionStatuses(context, "off", listOf("Alert"))["Alert"])
    }

    @Test fun anUnknownChannelThrows() {
        try {
            PermissionManager.getPermissionStatuses(context, "nope", listOf("Alert"))
            org.junit.Assert.fail("expected an exception")
        } catch (e: AwesomeNotificationsException) {
            assertEquals("Channel nope does not exist.", e.message)
        }
    }

    @Test fun onlySoundCriticalAlertAndDnDCanBeNotDetermined() {
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_LOW)
        shadowOf(manager()).setNotificationPolicyAccessGranted(false)
        assertEquals(
            mapOf("Sound" to "notDetermined", "OverrideDnD" to "notDetermined", "FullScreenIntent" to "granted"),
            PermissionManager.getPermissionStatuses(
                context, null, listOf("Sound", "OverrideDnD", "FullScreenIntent"))
        )
    }

    @Test fun withNotificationsOffTheOldSettingsPageOpens() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val component = ComponentName("com.android.settings", "AppNotifications")
        shadowOf(context.packageManager).addActivityIfNotPresent(component)
        shadowOf(context.packageManager).addIntentFilterForActivity(
            component,
            IntentFilter("android.settings.APP_NOTIFICATION_SETTINGS").apply { addCategory(Intent.CATEGORY_DEFAULT) }
        )
        val answer = request(null, "Alert")
        val page = shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>()).nextStartedActivity
        assertEquals("android.settings.APP_NOTIFICATION_SETTINGS", page.action)
        assertEquals(context.packageName, page.getStringExtra("app_package"))
        assertEquals(context.applicationInfo.uid, page.getIntExtra("app_uid", -1))
        assertNull(answer[0])
        PermissionManager.onForeground()
        assertEquals(listOf("Alert"), answer[0])
    }

    @Test fun aSoundRationaleOpensTheAppsPageBeforeAndroid8() {
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_LOW)
        // No settings page on this device: answered right away.
        val answer = request(null, "Sound")
        assertEquals(listOf("Sound"), answer[0])
    }
}
