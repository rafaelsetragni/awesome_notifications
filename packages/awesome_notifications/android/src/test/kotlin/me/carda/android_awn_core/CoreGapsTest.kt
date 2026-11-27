package me.carda.android_awn_core

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import androidx.test.core.app.ApplicationProvider
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterJNI
import io.flutter.embedding.engine.loader.FlutterLoader
import java.io.File
import java.net.ServerSocket
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import kotlin.concurrent.thread
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowPowerManager

/** A drawable every test app has (from androidx.core). */
private const val DRAWABLE = "notify_panel_notification_icon_bg"

/**
 * The four media sources of 0.12 `BitmapUtils`: network, file, Flutter asset
 * and Android resource, and what each answers when the image is missing.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BitmapSourcesTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val bitmaps = BitmapUtils.getInstance()

    @After fun tearDown() = FlutterInjector.reset()

    private fun pngBytes(): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        android.graphics.Bitmap.createBitmap(8, 8, android.graphics.Bitmap.Config.ARGB_8888)
            .compress(android.graphics.Bitmap.CompressFormat.PNG, 100, out)
        return out.toByteArray()
    }

    @Test fun aNetworkImageIsDownloaded() {
        val body = pngBytes()
        val server = ServerSocket(0)
        val requests = mutableListOf<String>()
        val worker = thread {
            server.accept().use { socket ->
                val reader = socket.getInputStream().bufferedReader()
                requests.add(reader.readLine())
                while (reader.readLine()?.isNotEmpty() == true) { /* headers */ }
                val out = socket.getOutputStream()
                out.write(
                    ("HTTP/1.1 200 OK\r\nContent-Type: image/png\r\nContent-Length: ${body.size}\r\n" +
                        "Connection: close\r\n\r\n").toByteArray())
                out.write(body)
                out.flush()
            }
        }
        try {
            val bitmap = bitmaps.getBitmapFromSource(context, "http://127.0.0.1:${server.localPort}/pic.png")
            worker.join(5000)
            assertNotNull(bitmap)
            assertEquals("GET /pic.png HTTP/1.1", requests.single())
        } finally {
            server.close()
        }
    }

    @Test fun anUnreachableNetworkImageIsNull() {
        val port = ServerSocket(0).use { it.localPort } // closed: refused
        assertNull(bitmaps.getBitmapFromSource(context, "https://127.0.0.1:$port/pic.png"))
    }

    @Test fun aFileImageIsDecoded() {
        val file = File(context.cacheDir, "pic.png").apply { writeBytes(pngBytes()) }
        assertNotNull(bitmaps.getBitmapFromSource(context, "file://" + file.absolutePath))
    }

    @Test fun anAssetIsLookedUpThroughFlutter() {
        val asked = mutableListOf<String>()
        val loader = object : FlutterLoader(FlutterJNI(), Executors.newSingleThreadExecutor()) {
            override fun getLookupKeyForAsset(asset: String): String {
                asked.add(asset)
                return "flutter_assets/$asset"
            }
        }
        FlutterInjector.reset()
        FlutterInjector.setInstance(FlutterInjector.Builder().setFlutterLoader(loader).build())
        // Not bundled in the test app: no bitmap.
        assertNull(bitmaps.getBitmapFromSource(context, "asset://images/pic.png"))
        assertEquals(listOf("images/pic.png"), asked)
    }

    @Test fun aResourceImageIsDecoded() {
        assertNotNull(bitmaps.getBitmapFromSource(context, "resource://drawable/$DRAWABLE"))
        assertNull(bitmaps.getBitmapFromSource(context, "resource://drawable/missing"))
        assertNull(bitmaps.getBitmapFromSource(context, "resource://nothing"))
    }

    @Test fun roundedImagesKeepTheirSize() {
        val file = File(context.cacheDir, "round.png").apply { writeBytes(pngBytes()) }
        val rounded = bitmaps.getBitmapFromSource(context, "file://" + file.absolutePath, true)!!
        assertEquals(8, rounded.width)
    }

    @Test fun drawableIdsWithOrWithoutThePrefix() {
        val id = context.resources.getIdentifier(DRAWABLE, "drawable", context.packageName)
        assertNotEquals(0, id)
        assertEquals(id, bitmaps.getDrawableResourceId(context, "drawable/$DRAWABLE"))
        assertEquals(id, bitmaps.getDrawableResourceId(context, "resource://drawable/$DRAWABLE"))
        assertEquals(0, bitmaps.getDrawableResourceId(context, "drawable"))
        assertEquals(0, bitmaps.getDrawableResourceId(context, null))
    }
}

/**
 * Builder paths not reached elsewhere: the action buttons' intents, icons
 * and reply input, BigPicture's large icon fallback, a broken layout, the
 * messaging avatar, the screen wake-up's lock tag and the media session's
 * custom actions.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NotificationBuilderGapsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val builder = NotificationBuilder.getNewBuilder()

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
        manager().cancelAll()
        ChannelManager.setChannel(
            context,
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "ch", Definitions.NOTIFICATION_CHANNEL_NAME to "ch")
        )
    }

    @After fun tearDown() {
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
    }

    private fun model(
        vararg content: Pair<String, Any?>,
        buttons: List<Map<String, Any?>>? = null
    ): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_CONTENT to mapOf(
                Definitions.NOTIFICATION_ID to 3,
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_TITLE to "Title",
                Definitions.NOTIFICATION_BODY to "Body"
            ) + mapOf(*content)
        )
        if (buttons != null) map[Definitions.NOTIFICATION_BUTTONS] = buttons
        return map
    }

    private fun build(model: Map<String, Any?>): Notification =
        builder.createNotificationContent(context, model)!!

    private fun drawableId() = context.resources.getIdentifier(DRAWABLE, "drawable", context.packageName)

    @Test fun aForegroundButtonOpensTheAppWithItsKey() {
        val notification = build(
            model(buttons = listOf(mapOf(
                Definitions.NOTIFICATION_BUTTON_KEY to "open",
                Definitions.NOTIFICATION_BUTTON_LABEL to "Open",
                Definitions.NOTIFICATION_ACTION_TYPE to "Default",
                Definitions.NOTIFICATION_BUTTON_ICON to "resource://drawable/$DRAWABLE"
            )))
        )
        val action = notification.actions.single()
        assertEquals(drawableId(), action.getIcon().resId)
        val pending = shadowOf(action.actionIntent)
        assertTrue(pending.isActivityIntent)
        val intent = pending.savedIntent
        assertEquals(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_open", intent.action)
        assertEquals("open", intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED))
        assertNotNull(intent.getStringExtra(Definitions.NOTIFICATION_JSON))
        assertEquals(3 * 1000 + 0 + 1, pending.requestCode)
        assertTrue(intent.flags and Intent.FLAG_ACTIVITY_SINGLE_TOP != 0)
        assertTrue(pending.flags and PendingIntent.FLAG_IMMUTABLE != 0)
    }

    @Test fun buttonIconsOnlyComeFromResources() {
        fun iconOf(icon: String): Int? = build(
            model(buttons = listOf(mapOf(
                Definitions.NOTIFICATION_BUTTON_KEY to "k",
                Definitions.NOTIFICATION_ACTION_TYPE to "SilentAction",
                Definitions.NOTIFICATION_BUTTON_ICON to icon
            )))
        ).actions.single().getIcon()?.resId
        assertNull(iconOf("asset://icon.png"))
        assertNull(iconOf("resource://drawable"))
    }

    @Test fun aReplyButtonHasAMutableIntentAndARemoteInput() {
        val notification = build(
            model(buttons = listOf(mapOf(
                Definitions.NOTIFICATION_BUTTON_KEY to "reply",
                Definitions.NOTIFICATION_BUTTON_LABEL to "Reply",
                Definitions.NOTIFICATION_ACTION_TYPE to "SilentAction",
                Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT to true
            )))
        )
        val action = notification.actions.single()
        val input = action.remoteInputs.single()
        assertEquals(Definitions.NOTIFICATION_BUTTON_KEY_INPUT, input.resultKey)
        assertEquals("Reply", input.label.toString())
        val pending = shadowOf(action.actionIntent)
        assertTrue(pending.isBroadcastIntent)
        assertTrue(pending.flags and PendingIntent.FLAG_MUTABLE != 0)
        assertEquals(NotificationButtonReceiver::class.java.name, pending.savedIntent.component?.className)
    }

    @Test fun hiddenOnExpandTheLargeIconStandsInForAMissingBigPicture() {
        val withIcon = build(
            model(
                Definitions.NOTIFICATION_LAYOUT to "BigPicture",
                Definitions.NOTIFICATION_BIG_PICTURE to "resource://drawable/missing",
                Definitions.NOTIFICATION_LARGE_ICON to "resource://drawable/$DRAWABLE",
                Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND to true
            )
        )
        assertNotNull(withIcon.getLargeIcon())
        // No big picture: not the BigPicture style.
        assertNull(withIcon.extras.getString(Notification.EXTRA_TEMPLATE)?.takeIf { it.contains("BigPicture") })

        val without = build(
            model(
                Definitions.NOTIFICATION_LAYOUT to "BigPicture",
                Definitions.NOTIFICATION_BIG_PICTURE to "resource://drawable/missing",
                Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND to true
            )
        )
        assertNull(without.getLargeIcon())
    }

    @Test fun aBrokenLayoutIsIgnoredAndTheNotificationStillBuilds() {
        // A messages list that is not a list of messages.
        val notification = build(
            model(
                Definitions.NOTIFICATION_LAYOUT to "Messaging",
                "messages" to listOf("not a message")
            )
        )
        assertEquals("Title", notification.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertNull(NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification))
    }

    @Test fun aMessagingAvatarIsTheMessagesOrElseTheNotificationsLargeIcon() {
        val icon = "resource://drawable/$DRAWABLE"
        val notification = build(
            model(
                Definitions.NOTIFICATION_LAYOUT to "Messaging",
                "roundedLargeIcon" to true,
                "messages" to listOf(
                    mapOf("title" to "Ana", "messages" to "own icon", "largeIcon" to icon),
                    mapOf("title" to "Ana", "messages" to "no icon")
                )
            )
        )
        val messages = NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification)!!.messages
        assertEquals(listOf("own icon", "no icon"), messages.map { it.text.toString() })
        assertNotNull(messages[0].person!!.icon)
        assertNull(messages[1].person!!.icon)

        val fallback = build(
            model(
                Definitions.NOTIFICATION_LAYOUT to "Messaging",
                Definitions.NOTIFICATION_LARGE_ICON to icon,
                "messages" to listOf(mapOf("title" to "Ana", "messages" to "hi"))
            )
        )
        assertNotNull(
            NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(fallback)!!
                .messages.single().person!!.icon)
    }

    @Test fun theWakeLockIsTaggedWithTheAppsLabel() {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        shadowOf(power).setIsInteractive(false)
        val info = context.applicationInfo
        val previous = info.labelRes
        info.labelRes = context.resources.getIdentifier(
            "status_bar_notification_info_overflow", "string", context.packageName)
        try {
            builder.wakeUpScreen(context)
            val lock = ShadowPowerManager.getLatestWakeLock()!!
            assertEquals(
                context.getString(info.labelRes) + ":NotificationBuilder:WakeupLock",
                shadowOf(lock).tag)
        } finally {
            info.labelRes = previous
        }
    }

    @Test fun actionEventsDefaultToTheDefaultActionType() {
        val event = builder.registerActionEvent(mapOf("id" to 1), NotificationLifeCycle.Background)
        assertEquals("Default", event[Definitions.NOTIFICATION_ACTION_TYPE])
        assertEquals("Background", event[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
        assertNotNull(event[Definitions.NOTIFICATION_ACTION_DATE])
    }

    @Test fun mediaButtonsWithIconsAreSessionCustomActions() {
        val core = AwesomeNotifications(context, Executor { it.run() })
        ChannelManager.setChannel(
            context,
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "media", Definitions.NOTIFICATION_CHANNEL_NAME to "Media")
        )
        fun button(key: String, label: String?) = mapOf<String, Any?>(
            Definitions.NOTIFICATION_BUTTON_KEY to key,
            Definitions.NOTIFICATION_BUTTON_LABEL to label,
            Definitions.NOTIFICATION_BUTTON_ICON to "resource://drawable/$DRAWABLE",
            Definitions.NOTIFICATION_ACTION_TYPE to "KeepOnTop"
        )
        core.createNotification(
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to 21,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "media",
                    Definitions.NOTIFICATION_TITLE to "Song",
                    Definitions.NOTIFICATION_LAYOUT to "MediaPlayer"
                ),
                Definitions.NOTIFICATION_BUTTONS to listOf(
                    button("PLAY", "Play"),
                    button("NEXT", null),
                    mapOf(Definitions.NOTIFICATION_BUTTON_LABEL to "no key")
                )
            )
        ) {}
        shadowOf(Looper.getMainLooper()).idle()

        val state = MediaPlayerLayout.session(context).controller.playbackState!!
        assertEquals(listOf("PLAY", "NEXT"), state.customActions.map { it.action })
        assertEquals(listOf("Play", "NEXT"), state.customActions.map { it.name.toString() })
        assertEquals(drawableId(), state.customActions.first().icon)
        val shown = manager().activeNotifications.first { it.id == 21 }.notification
        assertTrue(shown.extras.getString(Notification.EXTRA_TEMPLATE)!!.contains("MediaStyle"))
    }
}

/** Engine and helper paths not reached elsewhere. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CoreHelpersGapsTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @After fun tearDown() = NotificationBuilderRegistry.clearForTest()

    @Test fun aBuilderWithoutThePostPermissionReportsNotCreated() {
        val core = AwesomeNotifications(context, Executor { it.run() })
        NotificationBuilderRegistry.clearForTest()
        NotificationBuilderRegistry.register(10) { inner ->
            object : NotificationBuilder(inner) {
                override fun build(context: Context, model: Map<String, Any?>): BuildOutcome =
                    throw SecurityException("POST_NOTIFICATIONS")
            }
        }
        var created: Boolean? = null
        core.createNotification(mapOf(Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 1))) {
            created = it
        }
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(false, created)
    }

    @Test fun aButtonReplyReachesTheAppAsItsInput() {
        val received = mutableListOf<Pair<String, Map<String, Any?>>>()
        val listener = object : AwesomeEventListener {
            override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
                received.add(eventType to content)
            }
        }
        AwesomeEventsReceiver.subscribe(listener)
        try {
            val model = mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 5),
                Definitions.NOTIFICATION_BUTTONS to listOf(
                    mapOf(Definitions.NOTIFICATION_BUTTON_KEY to "REPLY", Definitions.NOTIFICATION_ACTION_TYPE to "SilentAction")
                )
            )
            val intent = Intent(context, NotificationButtonReceiver::class.java)
                .setAction(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_REPLY")
                .putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
                .putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, "REPLY")
            RemoteInput.addResultsToIntent(
                arrayOf(RemoteInput.Builder(Definitions.NOTIFICATION_BUTTON_KEY_INPUT).build()),
                intent,
                Bundle().apply { putCharSequence(Definitions.NOTIFICATION_BUTTON_KEY_INPUT, "On my way") }
            )
            NotificationButtonReceiver().onReceive(context, intent)
            shadowOf(Looper.getMainLooper()).idle()
            val action = received.single { it.first == Definitions.EVENT_DEFAULT_ACTION }.second
            assertEquals("On my way", action[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
        } finally {
            AwesomeEventsReceiver.unsubscribe(listener)
        }
    }

    @Test fun aHandlerAnsweringOnlyTheSimpleFormAlsoAnswersWithAnErrorCallback() {
        val handler = object : AwesomeMethodHandler {
            override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean {
                if (method != "simple") return false
                result("simple:$arguments")
                return true
            }
        }
        AwesomeMethodHandlerRegistry.register(handler)
        try {
            var answer: Any? = null
            var failed = false
            assertTrue(AwesomeMethodHandlerRegistry.handle("simple", 1, { answer = it }, { _, _, _ -> failed = true }))
            assertEquals("simple:1", answer)
            assertFalse(failed)
            assertFalse(AwesomeMethodHandlerRegistry.handle("other", 1, { }, { _, _, _ -> }))
        } finally {
            AwesomeMethodHandlerRegistry.unregister(handler)
        }
    }

    @Test fun anInterceptorWithoutOverridesChangesNothing() {
        val core = AwesomeNotifications(context, Executor { it.run() })
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ChannelManager.setChannel(
            context,
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "keep", Definitions.NOTIFICATION_CHANNEL_NAME to "keep")
        )
        manager.notify(
            1,
            NotificationCompat.Builder(context, "keep").setSmallIcon(android.R.drawable.ic_dialog_info)
                .setGroup("g").build()
        )
        val silent = object : CancelInterceptor {}
        CancelInterceptorRegistry.register(silent)
        try {
            core.dismissByChannelKey("other")
            core.dismissByGroupKey("other")
            assertEquals(1, manager.activeNotifications.size)
            core.dismissByGroupKey("g")
            assertEquals(0, manager.activeNotifications.size)
        } finally {
            CancelInterceptorRegistry.unregister(silent)
            ChannelManager.clearForTest()
        }
    }

    @Test fun longsAreReadTolerantly() {
        val maps = MapUtils.getInstance()
        assertEquals(5L, maps.getLong(5))
        assertEquals(9_000_000_000L, maps.getLong(9_000_000_000L))
        assertEquals(3L, maps.getLong(3.9))
        assertEquals(42L, maps.getLong("42"))
        assertNull(maps.getLong("x"))
        assertNull(maps.getLong(true))
        assertNull(maps.getLong(null))
    }

    @Test fun anOverflowingFlutterColorIsLeftAsItIs() {
        val html = "<font color=\"99999999999999999999\">x</font>"
        assertEquals(html, HtmlUtils.adaptFlutterColorsToJava(html))
        assertEquals("", HtmlUtils.adaptFlutterColorsToJava(""))
    }

    @Test fun defaultColorsAsTextOrOtherValues() {
        fun color(value: Any?) = ChannelManager.defaultColor(mapOf(Definitions.NOTIFICATION_DEFAULT_COLOR to value))
        assertEquals(0xFF112233.toInt(), color("#112233"))
        assertEquals(0x80112233.toInt(), color("0x80112233"))
        assertEquals(0xFF000000.toInt(), color("red"))
        assertEquals(0xFF000000.toInt(), color(true))
        assertEquals(0x12345678, color(0x12345678))
        assertEquals(0xFF000000.toInt(), color(null))
    }

    @Test fun nonTextValuesAreReadAsTheirText() {
        assertEquals("12", ChannelManager.string012(12))
        assertEquals("true", ChannelManager.string012(true))
        assertNull(ChannelManager.string012(null))
        assertEquals(
            "7",
            ChannelManager.groupKey(mapOf(Definitions.NOTIFICATION_GROUP_KEY to 7))
        )
    }

    @Test fun safeEnumParsingQuirks() {
        assertEquals(NotificationCategory.Event, NotificationCategory.from("eXX"))
        assertEquals(NotificationCategory.Email, NotificationCategory.from("email"))
        assertEquals(DefaultRingtoneType.Notification, DefaultRingtoneType.from("zzz"))
        assertEquals(DefaultRingtoneType.Alarm, DefaultRingtoneType.from("Alarm"))
        assertEquals(NotificationPrivacy.Public, NotificationPrivacy.fromMapValue(12, NotificationPrivacy.Public))
        assertNull(NotificationPrivacy.fromMapValue(12, null))
        assertEquals(GroupSort.Desc, GroupSort.from("Desc"))
        assertEquals(GroupSort.Asc, GroupSort.from("asc"))
        assertNull(GroupSort.from("zzz"))
        assertEquals(GroupSort.Desc, GroupSort.from(null))
        assertEquals(GroupAlertBehaviour.All, GroupAlertBehaviour.from("All"))
        assertEquals(GroupAlertBehaviour.Summary, GroupAlertBehaviour.from("Summary"))
        assertEquals(GroupAlertBehaviour.Children, GroupAlertBehaviour.from("Children"))
        assertEquals(GroupAlertBehaviour.All, GroupAlertBehaviour.from("zzz"))
    }
}

/** Android 7: the app's notifications carry no channel id. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [25])
class CoreAndroid7Test {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test fun dismissingByChannelMatchesNothingBeforeAndroid8() {
        val core = AwesomeNotifications(context, Executor { it.run() })
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        @Suppress("DEPRECATION")
        manager.notify(1, NotificationCompat.Builder(context).setSmallIcon(android.R.drawable.ic_dialog_info).build())
        core.dismissByChannelKey("ch")
        assertEquals(1, manager.activeNotifications.size)
        core.dismissAll()
        assertEquals(0, manager.activeNotifications.size)
    }
}
