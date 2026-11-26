package me.carda.android_awn_core

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowPowerManager

/**
 * The 0.12 content / channel options of the Android notification: category
 * (and its flags), full screen intent, locked, the channel's sound and
 * `defaultRingtoneType`, and wakeUpScreen.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NotificationOptionsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val builder = NotificationBuilder.getNewBuilder()

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
        ShadowPowerManager.clearWakeLocks()
        manager().notificationChannels.forEach { manager().deleteNotificationChannel(it.id) }
    }

    @After fun tearDown() {
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
    }

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun channel(key: String = "ch", vararg extra: Pair<String, Any?>) =
        ChannelManager.setChannel(
            context,
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to key,
                Definitions.NOTIFICATION_CHANNEL_NAME to key
            ) + mapOf(*extra)
        )

    private fun build(vararg content: Pair<String, Any?>, ctx: Context = context): Notification =
        builder.createNotificationContent(
            ctx,
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to 1,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                    Definitions.NOTIFICATION_TITLE to "Title"
                ) + mapOf(*content)
            )
        )!!

    private fun Notification.has(flag: Int) = flags and flag == flag

    // MARK: - Category

    @Test fun theCategoryIsItsRawValue() {
        channel()
        assertEquals("call", build(Definitions.NOTIFICATION_CATEGORY to "Call").category)
        assertEquals("alarm", build(Definitions.NOTIFICATION_CATEGORY to "Alarm").category)
        assertEquals("location_sharing", build(Definitions.NOTIFICATION_CATEGORY to "LocalSharing").category)
        assertEquals("err", build(Definitions.NOTIFICATION_CATEGORY to "Error").category)
        assertEquals("msg", build(Definitions.NOTIFICATION_CATEGORY to "Message").category)
        assertEquals("missed_call", build(Definitions.NOTIFICATION_CATEGORY to "MissedCall").category)
        assertEquals("stopwatch", build(Definitions.NOTIFICATION_CATEGORY to "StopWatch").category)
        assertEquals("progress", build(Definitions.NOTIFICATION_CATEGORY to "Progress").category)
        assertEquals("promo", build(Definitions.NOTIFICATION_CATEGORY to "Promo").category)
    }

    @Test fun withoutACategoryThereIsNone() {
        channel()
        assertNull(build().category)
        assertNull(build(Definitions.NOTIFICATION_CATEGORY to "").category)
        assertNull(build(Definitions.NOTIFICATION_CATEGORY to 1).category)
        assertNull(build(Definitions.NOTIFICATION_CATEGORY to "zzz").category)
    }

    @Test fun quirkTheCategoryIsReadByItsFirstChars() {
        channel()
        // 0.12 getSafeEnum: any text starting with "c" is Call.
        assertEquals("call", build(Definitions.NOTIFICATION_CATEGORY to "cookie").category)
    }

    @Test fun aCallIsInsistentHighPriorityAndCannotBeCleared() {
        channel()
        val notification = build(Definitions.NOTIFICATION_CATEGORY to "Call")
        assertTrue(notification.has(Notification.FLAG_INSISTENT))
        @Suppress("DEPRECATION")
        assertTrue(notification.has(Notification.FLAG_HIGH_PRIORITY))
        assertTrue(notification.has(Notification.FLAG_NO_CLEAR))
    }

    @Test fun anAlarmIsInsistentAndCannotBeCleared() {
        channel()
        val notification = build(Definitions.NOTIFICATION_CATEGORY to "Alarm")
        assertTrue(notification.has(Notification.FLAG_INSISTENT))
        assertTrue(notification.has(Notification.FLAG_NO_CLEAR))
        @Suppress("DEPRECATION")
        assertFalse(notification.has(Notification.FLAG_HIGH_PRIORITY))
    }

    @Test fun otherCategoriesAddNoFlags() {
        channel()
        val notification = build(Definitions.NOTIFICATION_CATEGORY to "Reminder")
        assertFalse(notification.has(Notification.FLAG_INSISTENT))
        assertFalse(notification.has(Notification.FLAG_NO_CLEAR))
    }

    // MARK: - Full screen intent

    @Test fun fullScreenIntentIsTheTapIntent() {
        channel()
        val notification = build(Definitions.NOTIFICATION_FULL_SCREEN_INTENT to true)
        assertNotNull(notification.fullScreenIntent)
        assertSame(notification.contentIntent, notification.fullScreenIntent)
    }

    @Test fun noFullScreenIntentUnlessTrue() {
        channel()
        assertNull(build().fullScreenIntent)
        assertNull(build(Definitions.NOTIFICATION_FULL_SCREEN_INTENT to false).fullScreenIntent)
        assertNull(build(Definitions.NOTIFICATION_FULL_SCREEN_INTENT to "true").fullScreenIntent)
    }

    // MARK: - Locked (0.12 precedence table)

    private fun ongoing(contentLocked: Any?, channelLocked: Any?): Boolean {
        ChannelManager.clearForTest()
        if (channelLocked == null) channel() else channel("ch", Definitions.NOTIFICATION_LOCKED to channelLocked)
        val notification =
            if (contentLocked == null) build()
            else build(Definitions.NOTIFICATION_LOCKED to contentLocked)
        return notification.has(Notification.FLAG_ONGOING_EVENT)
    }

    @Test fun lockedPrecedence() {
        // content locked wins
        assertTrue(ongoing(contentLocked = true, channelLocked = null))
        assertTrue(ongoing(contentLocked = true, channelLocked = false))
        assertTrue(ongoing(contentLocked = true, channelLocked = true))
        // nothing locked
        assertFalse(ongoing(contentLocked = null, channelLocked = null))
        assertFalse(ongoing(contentLocked = false, channelLocked = null))
        assertFalse(ongoing(contentLocked = false, channelLocked = false))
        // the content says otherwise
        assertFalse(ongoing(contentLocked = false, channelLocked = true))
    }

    @Test fun quirkALockedChannelAloneDoesNotLock() {
        // 0.12: the content's `locked` defaults to false, so the channel's
        // `getValueOrDefault(content.locked, true)` reads false.
        assertFalse(ongoing(contentLocked = null, channelLocked = true))
        // Only a Boolean counts.
        assertFalse(ongoing(contentLocked = "true", channelLocked = null))
    }

    // MARK: - Channel sound / defaultRingtoneType

    private var soundChannels = 0

    /** A new channel each time: Android restores a deleted channel's sound. */
    private fun channelSound(vararg extra: Pair<String, Any?>): android.net.Uri? {
        val key = "snd" + soundChannels++
        channel(key, *extra)
        return manager().getNotificationChannel(key).sound
    }

    @Test fun theChannelPlaysTheDefaultSoundOfItsRingtoneType() {
        assertEquals(Settings.System.DEFAULT_NOTIFICATION_URI, channelSound())
        assertEquals(
            Settings.System.DEFAULT_NOTIFICATION_URI,
            channelSound(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Notification"))
        assertEquals(
            Settings.System.DEFAULT_ALARM_ALERT_URI,
            channelSound(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Alarm"))
        assertEquals(
            Settings.System.DEFAULT_RINGTONE_URI,
            channelSound(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Ringtone"))
    }

    @Test fun theChannelSoundUsesSonificationNotificationAttributes() {
        channel("attrs", Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Alarm")
        val attributes = manager().getNotificationChannel("attrs").audioAttributes
        assertEquals(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION, attributes.contentType)
        assertEquals(android.media.AudioAttributes.USAGE_NOTIFICATION, attributes.usage)
    }

    @Test fun aChannelVibratesAndLightsWithoutABadgeByDefault() {
        channel("defaults")
        val ch = manager().getNotificationChannel("defaults")
        assertEquals(true, ch.shouldVibrate())
        assertEquals(true, ch.shouldShowLights())
        assertEquals(0xFFFFFFFF.toInt(), ch.lightColor)
        assertEquals(false, ch.canShowBadge())
    }

    @Test fun theChannelOptionsReachTheAndroidChannel() {
        channel(
            "options",
            Definitions.NOTIFICATION_ENABLE_VIBRATION to true,
            Definitions.NOTIFICATION_VIBRATION_PATTERN to longArrayOf(0, 500, 200),
            Definitions.NOTIFICATION_ENABLE_LIGHTS to true,
            Definitions.NOTIFICATION_LED_COLOR to 0xFF00FF00L,
            Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE to true)
        val ch = manager().getNotificationChannel("options")
        assertEquals(listOf(0L, 500L, 200L), ch.vibrationPattern.toList())
        assertEquals(0xFF00FF00.toInt(), ch.lightColor)
        assertEquals(true, ch.canShowBadge())

        channel(
            "off",
            Definitions.NOTIFICATION_ENABLE_VIBRATION to false,
            Definitions.NOTIFICATION_ENABLE_LIGHTS to false)
        val off = manager().getNotificationChannel("off")
        assertEquals(false, off.shouldVibrate())
        assertEquals(false, off.shouldShowLights())
    }

    @Test fun aChannelWithoutSoundIsSilent() {
        assertNull(channelSound(
            Definitions.NOTIFICATION_PLAY_SOUND to false,
            Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Alarm"))
    }

    @Test fun anUnknownSoundSourcePlaysNothing() {
        // 0.12: a sound source that is no raw resource has no uri.
        assertNull(channelSound(Definitions.NOTIFICATION_SOUND_SOURCE to "resource://raw/nope"))
    }

    /** The sound set on the Android builder (Android 7 plays it; 8+ plays the channel's). */
    private fun builderSound(channelKey: String, vararg content: Pair<String, Any?>): android.net.Uri? {
        var sound: android.net.Uri? = null
        NotificationBuilderRegistry.register(1) { inner ->
            object : NotificationBuilder(inner) {
                override fun decorate(
                    context: Context,
                    model: Map<String, Any?>,
                    builder: androidx.core.app.NotificationCompat.Builder
                ) {
                    val field = androidx.core.app.NotificationCompat.Builder::class.java
                        .getDeclaredField("mNotification").apply { isAccessible = true }
                    @Suppress("DEPRECATION")
                    sound = (field.get(builder) as Notification).sound
                    super.decorate(context, model, builder)
                }
            }
        }
        build(Definitions.NOTIFICATION_CHANNEL_KEY to channelKey, *content)
        NotificationBuilderRegistry.clearForTest()
        return sound
    }

    @Test fun theNotificationSoundFollowsTheChannel() {
        channel("ring", Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Ringtone")
        assertEquals(Settings.System.DEFAULT_RINGTONE_URI, builderSound("ring"))

        channel("alarm", Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE to "Alarm")
        assertEquals(Settings.System.DEFAULT_ALARM_ALERT_URI, builderSound("alarm"))

        channel("plain")
        assertEquals(Settings.System.DEFAULT_NOTIFICATION_URI, builderSound("plain"))

        channel("quiet", Definitions.NOTIFICATION_PLAY_SOUND to false)
        assertNull(builderSound("quiet"))
        // 0.12: the content's customSound is only used when the channel plays sound.
        assertNull(builderSound("quiet", Definitions.NOTIFICATION_CUSTOM_SOUND to "resource://raw/x"))
    }

    @Test fun anUnknownCustomSoundPlaysNothing() {
        channel("plain2")
        assertNull(builderSound("plain2", Definitions.NOTIFICATION_CUSTOM_SOUND to "resource://raw/nope"))
    }

    // MARK: - Critical alerts (0.12.1: channel-only)

    @Test fun aCriticalChannelBypassesDnd() {
        channel("critical", Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS to true)
        assertTrue(manager().getNotificationChannel("critical").canBypassDnd())
        channel("normal")
        assertFalse(manager().getNotificationChannel("normal").canBypassDnd())
    }

    @Test fun criticalAlertsNeverChangeTheDevicesDnd() {
        val before = manager().currentInterruptionFilter
        channel("ch", Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS to true)
        build("criticalAlert" to true)
        assertEquals(before, manager().currentInterruptionFilter)
    }

    @Test fun aContentCriticalAlertIsIgnored() {
        channel("ch")
        build("criticalAlert" to true)
        assertFalse(manager().getNotificationChannel("ch").canBypassDnd())
    }

    // MARK: - Wake up screen

    private fun powerManager() =
        context.getSystemService(Context.POWER_SERVICE) as PowerManager

    @Test fun wakeUpScreenWakesAnOffScreenFor3Seconds() {
        channel()
        shadowOf(powerManager()).setIsInteractive(false)
        build(Definitions.NOTIFICATION_WAKE_UP_SCREEN to true)
        val wakeLock = ShadowPowerManager.getLatestWakeLock()
        assertNotNull(wakeLock)
        assertTrue(wakeLock.isHeld) // held for its 3 s timeout
        assertTrue(shadowOf(wakeLock).tag.endsWith(":NotificationBuilder:WakeupLock"))
    }

    @Test fun wakeUpScreenDoesNothingWithTheScreenOn() {
        channel()
        shadowOf(powerManager()).setIsInteractive(true)
        build(Definitions.NOTIFICATION_WAKE_UP_SCREEN to true)
        assertNull(ShadowPowerManager.getLatestWakeLock())
    }

    @Test fun noWakeUpUnlessAsked() {
        channel()
        shadowOf(powerManager()).setIsInteractive(false)
        build()
        assertNull(ShadowPowerManager.getLatestWakeLock())
    }

    @Test
    @Config(shadows = [ShadowWakeLockWithoutPermission::class])
    fun withoutWakeLockPermissionTheCreateFailsAndNothingIsShown() {
        channel()
        manager().cancelAll()
        shadowOf(powerManager()).setIsInteractive(false)
        val core = AwesomeNotifications(context, Executor { it.run() })
        var created: Boolean? = null
        var error: Triple<String, String, String?>? = null
        core.createNotification(
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to 7,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                    Definitions.NOTIFICATION_TITLE to "Wake",
                    Definitions.NOTIFICATION_WAKE_UP_SCREEN to true
                )
            ),
            onError = { code, message, details -> error = Triple(code, message, details) }
        ) { created = it }
        shadowOf(Looper.getMainLooper()).idle()

        assertNull(created)
        assertEquals(Definitions.CODE_NOTIFICATION_THREAD_EXCEPTION, error!!.first)
        assertEquals(ShadowWakeLockWithoutPermission.MESSAGE, error!!.second)
        assertEquals(Definitions.DETAILED_UNEXPECTED_ERROR, error!!.third)
        assertTrue(manager().activeNotifications.none { it.id == 7 })
    }

    @Test
    @Config(shadows = [ShadowWakeLockWithoutPermission::class])
    fun withoutWakeLockPermissionTheScreenOnIsFine() {
        channel()
        shadowOf(powerManager()).setIsInteractive(true)
        assertNotNull(build(Definitions.NOTIFICATION_WAKE_UP_SCREEN to true))
    }
}

/** A wake lock as without the WAKE_LOCK permission: acquiring it throws. */
@Implements(PowerManager.WakeLock::class)
class ShadowWakeLockWithoutPermission : ShadowPowerManager.ShadowWakeLock() {
    companion object {
        const val MESSAGE = "Neither user 10001 nor current process has android.permission.WAKE_LOCK."
    }

    @Implementation
    override fun acquire(timeout: Long) {
        throw SecurityException(MESSAGE)
    }
}
