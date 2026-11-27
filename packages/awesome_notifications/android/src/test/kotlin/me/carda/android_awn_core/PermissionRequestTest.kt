package me.carda.android_awn_core

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.provider.Settings
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * 0.12 `requestUserPermissions` (requestPermissionToSendNotifications) on
 * Android 13+: the system dialog while it can show, the app's notification
 * settings once the user denied it; the answer when the user is back.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PermissionRequestTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var activity: Activity

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        ChannelManager.clearForTest()
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_DEFAULT)
        activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        // Drain anything a previous test left waiting.
        PermissionManager.onForeground()
    }

    private fun request(): Array<List<String>?> {
        val answer = arrayOfNulls<List<String>>(1)
        PermissionManager.requestUserPermissions(activity, context, null, listOf("Alert", "Sound")) {
            answer[0] = it
        }
        return answer
    }

    @Test fun allowedAnswersRightAway() {
        shadowOf(manager()).setNotificationsEnabled(true)
        assertEquals(emptyList<String>(), request()[0])
        assertNull(shadowOf(activity).lastRequestedPermission)
    }

    @Test fun offAndNeverAskedShowsTheDialogAndAnswersWithIt() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val answer = request()
        assertNull(answer[0])
        assertEquals(listOf(Manifest.permission.POST_NOTIFICATIONS),
            shadowOf(activity).lastRequestedPermission.requestedPermissions.toList())
        assertEquals(PermissionManager.REQUEST_CODE, shadowOf(activity).lastRequestedPermission.requestCode)

        shadowOf(manager()).setNotificationsEnabled(true)
        PermissionManager.onDialogResult(PermissionManager.REQUEST_CODE)
        assertEquals(emptyList<String>(), answer[0])
    }

    @Test fun offAfterTheUserDeniedOpensTheAppsNotificationSettings() {
        shadowOf(manager()).setNotificationsEnabled(false)
        shadowOf(context.packageManager).setShouldShowRequestPermissionRationale(
            Manifest.permission.POST_NOTIFICATIONS, true)
        // Something answers the settings page.
        shadowOf(context.packageManager).addActivityIfNotPresent(
            android.content.ComponentName("com.android.settings", "Notifications"))
        shadowOf(context.packageManager).addIntentFilterForActivity(
            android.content.ComponentName("com.android.settings", "Notifications"),
            android.content.IntentFilter(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                addCategory(android.content.Intent.CATEGORY_DEFAULT)
            })

        val answer = request()
        assertNull(shadowOf(activity).lastRequestedPermission)
        val opened = shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>()).nextStartedActivity
        assertEquals(Settings.ACTION_APP_NOTIFICATION_SETTINGS, opened.action)
        assertEquals(context.packageName, opened.getStringExtra(Settings.EXTRA_APP_PACKAGE))
        assertNull(answer[0])

        // Back in front, still off: both missing.
        PermissionManager.onForeground()
        assertEquals(listOf("Alert", "Sound"), answer[0])
    }

    @Test fun anotherRequestCodeIsNotOurs() {
        assertEquals(false, PermissionManager.onDialogResult(7))
    }
}
