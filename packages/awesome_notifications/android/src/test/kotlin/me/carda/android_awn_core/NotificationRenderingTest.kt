package me.carda.android_awn_core

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import androidx.core.app.NotificationCompat
import androidx.test.core.app.ApplicationProvider
import java.util.concurrent.Executor
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The 0.12 `getNotificationBuilderFromModel` steps restored in 1.0: the HTML
 * texts and summary, grouping (and the group summary notification),
 * visibility, showWhen, ticker, onlyAlertOnce, priority, chronometer,
 * timeoutAfter, vibration, lights, colors, the BigPicture / BigText / Inbox /
 * ProgressBar layouts, the action buttons' label and authentication, and the
 * channel's importance and channel group.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
@Suppress("DEPRECATION")
class NotificationRenderingTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val builder = NotificationBuilder.getNewBuilder()

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
        manager().cancelAll()
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            manager().notificationChannels.forEach { manager().deleteNotificationChannel(it.id) }
            manager().notificationChannelGroups.forEach { manager().deleteNotificationChannelGroup(it.id) }
        }
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

    private fun model(
        vararg content: Pair<String, Any?>,
        id: Int = 1,
        buttons: List<Map<String, Any?>>? = null
    ): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_CONTENT to mapOf(
                Definitions.NOTIFICATION_ID to id,
                Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                Definitions.NOTIFICATION_TITLE to "Title",
                Definitions.NOTIFICATION_BODY to "Body"
            ) + mapOf(*content)
        )
        if (buttons != null) map[Definitions.NOTIFICATION_BUTTONS] = buttons
        return map
    }

    private fun build(vararg content: Pair<String, Any?>, id: Int = 1): Notification =
        builder.createNotificationContent(context, model(*content, id = id))!!

    private fun Notification.has(flag: Int) = flags and flag == flag

    private fun imageFile(name: String): String {
        val file = java.io.File(context.cacheDir, name)
        file.outputStream().use {
            Bitmap.createBitmap(40, 20, Bitmap.Config.ARGB_8888)
                .apply { eraseColor(Color.RED) }
                .compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        return "file://" + file.absolutePath
    }

    // MARK: - Texts

    @Test fun theTextsAreHtml() {
        channel()
        val notification = build(
            Definitions.NOTIFICATION_TITLE to "<b>Bold</b>",
            Definitions.NOTIFICATION_BODY to "<i>Italic</i>")
        val title = notification.extras.getCharSequence(Notification.EXTRA_TITLE)
        assertEquals("Bold", title.toString())
        assertTrue((title as Spanned).getSpans(0, title.length, StyleSpan::class.java).isNotEmpty())
        assertEquals("Italic", notification.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
    }

    @Test fun flutterColorsAreAdaptedToJava() {
        // 0xFFFF0000 as Dart sends it → the signed int Java's parser reads.
        assertEquals("<font color=\"-65536\">x</font>",
            HtmlUtils.adaptFlutterColorsToJava("<font color=\"4294901760\">x</font>"))
        assertEquals("plain", HtmlUtils.adaptFlutterColorsToJava("plain"))
        assertNull(HtmlUtils.fromHtml("  "))
    }

    @Test fun theSummaryIsTheSubText() {
        channel()
        assertEquals("Sub", build(Definitions.NOTIFICATION_SUMMARY to "Sub")
            .extras.getCharSequence(Notification.EXTRA_SUB_TEXT).toString())
        assertNull(build().extras.getCharSequence(Notification.EXTRA_SUB_TEXT))
    }

    @Test fun theTickerIsTickerElseSummaryElseBodyElseTitle() {
        channel()
        assertEquals("T", build(Definitions.NOTIFICATION_TICKER to "T",
            Definitions.NOTIFICATION_SUMMARY to "S").tickerText.toString())
        assertEquals("S", build(Definitions.NOTIFICATION_TICKER to " ",
            Definitions.NOTIFICATION_SUMMARY to "S").tickerText.toString())
        assertEquals("Body", build().tickerText.toString())
        assertEquals("Title", build(Definitions.NOTIFICATION_BODY to null).tickerText.toString())
    }

    // MARK: - showWhen / chronometer / timeoutAfter

    @Test fun theTimeShowsUnlessShowWhenIsFalse() {
        channel()
        assertTrue(build().extras.getBoolean(Notification.EXTRA_SHOW_WHEN))
        assertFalse(build(Definitions.NOTIFICATION_SHOW_WHEN to false)
            .extras.getBoolean(Notification.EXTRA_SHOW_WHEN))
        // Only a Boolean counts (default true).
        assertTrue(build(Definitions.NOTIFICATION_SHOW_WHEN to "false")
            .extras.getBoolean(Notification.EXTRA_SHOW_WHEN))
    }

    @Test fun theChronometerCountsUpFromItsSeconds() {
        channel()
        val before = System.currentTimeMillis()
        val notification = build(Definitions.NOTIFICATION_CHRONOMETER to 10)
        assertTrue(notification.extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertTrue(notification.`when` in (before - 10_000 - 1_000)..(System.currentTimeMillis() - 10_000))

        assertFalse(build(Definitions.NOTIFICATION_CHRONOMETER to -1)
            .extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertFalse(build(Definitions.NOTIFICATION_CHRONOMETER to 10, Definitions.NOTIFICATION_SHOW_WHEN to false)
            .extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
        assertFalse(build().extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER))
    }

    @Test fun timeoutAfterIsInSecondsFromOne() {
        channel()
        assertEquals(5_000L, build(Definitions.NOTIFICATION_TIMEOUT_AFTER to 5).timeoutAfter)
        assertEquals(0L, build(Definitions.NOTIFICATION_TIMEOUT_AFTER to 0).timeoutAfter)
        assertEquals(0L, build().timeoutAfter)
    }

    // MARK: - Visibility

    @Test fun theVisibilityIsTheContentPrivacy() {
        channel()
        assertEquals(Notification.VISIBILITY_PRIVATE, build().visibility)
        assertEquals(Notification.VISIBILITY_PUBLIC, build(Definitions.NOTIFICATION_PRIVACY to "Public").visibility)
        assertEquals(Notification.VISIBILITY_SECRET, build(Definitions.NOTIFICATION_PRIVACY to "Secret").visibility)
    }

    @Test fun quirkTheChannelPrivacyOnlyAppliesToAnUnknownContentPrivacy() {
        channel("ch", Definitions.NOTIFICATION_DEFAULT_PRIVACY to "Public")
        // 0.12's content defaults privacy to Private, so the channel's is not used...
        assertEquals(Notification.VISIBILITY_PRIVATE, build().visibility)
        // ...unless the content's is a text that is no privacy.
        assertEquals(Notification.VISIBILITY_PUBLIC, build(Definitions.NOTIFICATION_PRIVACY to "zz").visibility)
    }

    // MARK: - onlyAlertOnce / priority

    @Test fun aProgressBarOrAnOnlyAlertOnceChannelAlertsOnce() {
        channel()
        assertFalse(build().has(Notification.FLAG_ONLY_ALERT_ONCE))
        assertTrue(build(Definitions.NOTIFICATION_LAYOUT to "ProgressBar").has(Notification.FLAG_ONLY_ALERT_ONCE))
        channel("ch", Definitions.NOTIFICATION_ONLY_ALERT_ONCE to true)
        assertTrue(build().has(Notification.FLAG_ONLY_ALERT_ONCE))
    }

    @Test fun thePriorityIsTheChannelImportance() {
        val expected = mapOf(
            "Min" to NotificationCompat.PRIORITY_MIN,
            "Low" to NotificationCompat.PRIORITY_LOW,
            "Default" to NotificationCompat.PRIORITY_DEFAULT,
            "High" to NotificationCompat.PRIORITY_HIGH,
            "Max" to NotificationCompat.PRIORITY_MAX)
        // (A deleted Android channel comes back with its old settings: one key each.)
        for ((importance, priority) in expected) {
            channel(importance, Definitions.NOTIFICATION_IMPORTANCE to importance)
            assertEquals(importance, priority,
                build(Definitions.NOTIFICATION_CHANNEL_KEY to importance).priority)
        }
        channel()
        assertEquals(NotificationCompat.PRIORITY_DEFAULT, build().priority)
    }

    @Test fun aMaxChannelIsImportanceMax() {
        channel("ch", Definitions.NOTIFICATION_IMPORTANCE to "Max")
        assertEquals(NotificationManager.IMPORTANCE_MAX, manager().getNotificationChannel("ch").importance)
    }

    // MARK: - Vibration / lights

    // Android 8+ (NotificationCompat with a channel) clears the
    // notification's own vibration and lights: the channel's apply. These are
    // what Android 7 and older use.

    @Test @Config(sdk = [25])
    fun aVibratingChannelUsesItsPatternAndASilentOneZero() {
        channel("ch", Definitions.NOTIFICATION_VIBRATION_PATTERN to listOf(0, 100, 200))
        assertArrayEquals(longArrayOf(0, 100, 200), build().vibrate)
        channel()
        assertNull(build().vibrate)
        channel("ch", Definitions.NOTIFICATION_ENABLE_VIBRATION to false)
        assertArrayEquals(longArrayOf(0), build().vibrate)
    }

    @Test @Config(sdk = [25])
    fun aChannelWithLightsBlinksItsLed() {
        channel()
        val notification = build()
        assertEquals(Color.WHITE, notification.ledARGB)
        assertEquals(300, notification.ledOnMS)
        assertEquals(700, notification.ledOffMS)

        channel("ch",
            Definitions.NOTIFICATION_LED_COLOR to Color.GREEN,
            Definitions.NOTIFICATION_LED_ON_MS to 100,
            Definitions.NOTIFICATION_LED_OFF_MS to 200)
        val custom = build()
        assertEquals(Color.GREEN, custom.ledARGB)
        assertEquals(100, custom.ledOnMS)
        assertEquals(200, custom.ledOffMS)

        channel("ch", Definitions.NOTIFICATION_ENABLE_LIGHTS to false)
        assertEquals(0, build().ledOnMS)
    }

    @Test @Config(sdk = [25])
    fun beforeAndroid8ThePriorityIsTheChannelModelImportance() {
        channel("ch", Definitions.NOTIFICATION_IMPORTANCE to "High")
        assertEquals(NotificationCompat.PRIORITY_HIGH, build().priority)
    }

    @Test fun onAndroid8TheChannelsOwnLightsAndVibrationApply() {
        channel("ch", Definitions.NOTIFICATION_VIBRATION_PATTERN to listOf(0, 100, 200))
        val android = manager().getNotificationChannel("ch")
        assertTrue(android.shouldVibrate())
        assertArrayEquals(longArrayOf(0, 100, 200), android.vibrationPattern)
        assertTrue(android.shouldShowLights())
    }

    // MARK: - Colors

    @Test fun theColorIsTheContentsElseTheChannelsElseBlack() {
        channel()
        // 0.12 quirk: an unset color is set as black, not left at the default.
        assertEquals(Color.BLACK, build().color)
        // Dart sends 0xFFFF0000 as a Long.
        assertEquals(Color.RED, build(Definitions.NOTIFICATION_COLOR to 0xFFFF0000L).color)
        channel("ch", Definitions.NOTIFICATION_DEFAULT_COLOR to 0xFF0000FFL)
        assertEquals(Color.BLUE, build().color)
        // Black means "unset": a black content color takes the channel's.
        assertEquals(Color.BLUE, build(Definitions.NOTIFICATION_COLOR to 0xFF000000L).color)
        assertFalse(build().extras.getBoolean(Notification.EXTRA_COLORIZED))
    }

    @Test fun aBackgroundColorColorizes() {
        channel()
        val notification = build(Definitions.NOTIFICATION_BACKGROUND_COLOR to 0xFF00FF00L,
            Definitions.NOTIFICATION_COLOR to 0xFFFF0000L)
        assertEquals(Color.GREEN, notification.color)
        assertTrue(notification.extras.getBoolean(Notification.EXTRA_COLORIZED))
    }

    // MARK: - Layouts

    @Test fun theProgressBarIsClampedAndIndeterminateWithoutProgress() {
        channel()
        fun bar(progress: Any?) = build(Definitions.NOTIFICATION_LAYOUT to "ProgressBar",
            Definitions.NOTIFICATION_PROGRESS to progress).extras
        assertEquals(42, bar(42.7).getInt(Notification.EXTRA_PROGRESS))
        assertEquals(100, bar(42.7).getInt(Notification.EXTRA_PROGRESS_MAX))
        assertFalse(bar(42.7).getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE))
        assertEquals(100, bar(150).getInt(Notification.EXTRA_PROGRESS))
        assertEquals(0, bar(-5).getInt(Notification.EXTRA_PROGRESS))
        assertTrue(bar(null).getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE))
        // Not a ProgressBar: no bar.
        assertEquals(0, build(Definitions.NOTIFICATION_PROGRESS to 50).extras.getInt(Notification.EXTRA_PROGRESS_MAX))
    }

    @Test fun bigTextShowsTheWholeBody() {
        channel()
        val extras = build(Definitions.NOTIFICATION_LAYOUT to "BigText",
            Definitions.NOTIFICATION_BODY to "A long <b>body</b>",
            Definitions.NOTIFICATION_SUMMARY to "Sum").extras
        assertEquals("A long body", extras.getCharSequence(Notification.EXTRA_BIG_TEXT).toString())
        assertEquals("Sum", extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT).toString())
        assertEquals("Title", extras.getCharSequence(Notification.EXTRA_TITLE_BIG).toString())
        // Without a body there is no BigText style.
        assertNull(build(Definitions.NOTIFICATION_LAYOUT to "BigText", Definitions.NOTIFICATION_BODY to null)
            .extras.getCharSequence(Notification.EXTRA_BIG_TEXT))
    }

    @Test fun inboxListsTheBodyLines() {
        channel()
        val extras = build(Definitions.NOTIFICATION_LAYOUT to "Inbox",
            Definitions.NOTIFICATION_BODY to "one\r\ntwo\nthree\n\n").extras
        assertEquals(listOf("one", "two", "three"),
            extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)!!.map { it.toString() })
        assertEquals("+ 3 more", extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT).toString())

        val withSummary = build(Definitions.NOTIFICATION_LAYOUT to "Inbox",
            Definitions.NOTIFICATION_BODY to "one\ntwo",
            Definitions.NOTIFICATION_SUMMARY to "2 new").extras
        assertEquals("2 new", withSummary.getCharSequence(Notification.EXTRA_SUMMARY_TEXT).toString())
    }

    @Test fun quirkABlankInboxSummaryLeavesNoSummaryText() {
        channel()
        val extras = build(Definitions.NOTIFICATION_LAYOUT to "Inbox",
            Definitions.NOTIFICATION_SUMMARY to "").extras
        assertNull(extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT))
    }

    @Test fun bigPictureShowsThePictureAndTheBodyAsSummary() {
        channel()
        val picture = imageFile("picture.png")
        val notification = build(Definitions.NOTIFICATION_LAYOUT to "BigPicture",
            Definitions.NOTIFICATION_BIG_PICTURE to picture,
            Definitions.NOTIFICATION_LARGE_ICON to picture)
        assertNotNull(notification.extras.get(Notification.EXTRA_PICTURE))
        assertEquals("Body", notification.extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT).toString())
        assertNotNull(notification.getLargeIcon())
        assertNotNull(notification.extras.get(Notification.EXTRA_LARGE_ICON_BIG))
    }

    @Test fun hideLargeIconOnExpandUsesThePictureAsIconAndHidesItExpanded() {
        channel()
        val notification = build(Definitions.NOTIFICATION_LAYOUT to "BigPicture",
            Definitions.NOTIFICATION_BIG_PICTURE to imageFile("picture.png"),
            Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND to true)
        assertNotNull(notification.getLargeIcon())
        assertNull(notification.extras.get(Notification.EXTRA_LARGE_ICON_BIG))
    }

    @Test fun aBigPictureThatDoesNotLoadKeepsTheLargeIcon() {
        channel()
        val notification = build(Definitions.NOTIFICATION_LAYOUT to "BigPicture",
            Definitions.NOTIFICATION_BIG_PICTURE to "weird://does-not-load",
            Definitions.NOTIFICATION_LARGE_ICON to imageFile("icon.png"))
        assertNotNull(notification.getLargeIcon())
        assertNull(notification.extras.get(Notification.EXTRA_PICTURE))
    }

    @Test fun aRoundedLargeIconIsCutByACircle() {
        val square = Bitmap.createBitmap(20, 20, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.RED) }
        val rounded = BitmapUtils.getInstance().roundBitmap(square)
        assertEquals(20, rounded.width)
        assertEquals(Color.TRANSPARENT, rounded.getPixel(0, 0))
    }

    // MARK: - Grouping

    @Test fun aGroupKeyGroupsAndSorts() {
        channel("ch", Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR to "Children")
        val notification = build(Definitions.NOTIFICATION_GROUP_KEY to "g", id = 7)
        assertEquals("g", notification.group)
        assertTrue(notification.sortKey.endsWith("7"))
        assertEquals(NotificationCompat.GROUP_ALERT_CHILDREN, notification.groupAlertBehavior)
        assertFalse(notification.has(Notification.FLAG_GROUP_SUMMARY))
        assertNull(build().group)
    }

    @Test fun theGroupSortOrdersByTime() {
        channel("ch", Definitions.NOTIFICATION_GROUP_SORT to "Asc")
        val asc = build(Definitions.NOTIFICATION_GROUP_KEY to "g").sortKey.dropLast(1).toLong()
        assertTrue(asc <= System.currentTimeMillis())
        channel("ch")
        val desc = build(Definitions.NOTIFICATION_GROUP_KEY to "g").sortKey.dropLast(1).toLong()
        assertTrue(desc > System.currentTimeMillis())
    }

    @Test fun theChannelGroupKeyGroupsWithoutAContentOne() {
        channel("ch", Definitions.NOTIFICATION_GROUP_KEY to "from-channel")
        assertEquals("from-channel", build().group)
    }

    @Test fun theMessagingLayoutsAreNotGrouped() {
        channel()
        assertNull(build(Definitions.NOTIFICATION_GROUP_KEY to "g",
            Definitions.NOTIFICATION_LAYOUT to "Messaging").group)
    }

    @Test fun theFirstOfAGroupPostsItsSummaryFirst() {
        channel()
        val first = builder.createNotificationContent(
            context, model(Definitions.NOTIFICATION_GROUP_KEY to "g", Definitions.NOTIFICATION_LARGE_ICON to imageFile("i.png"), id = 1))!!
        val summaries = manager().activeNotifications
        assertEquals(1, summaries.size)
        val summary = summaries[0]
        assertTrue(summary.id != 1)
        assertEquals("g", summary.notification.group)
        assertTrue(summary.notification.has(Notification.FLAG_GROUP_SUMMARY))
        assertNull(summary.notification.deleteIntent)
        assertNull(summary.notification.getLargeIcon())
        assertEquals("Title", summary.notification.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertNotNull(first.deleteIntent)

        // The summary is on screen: the next ones of the group post none.
        manager().notify(1, first)
        manager().notify(2, builder.createNotificationContent(
            context, model(Definitions.NOTIFICATION_GROUP_KEY to "g", id = 2))!!)
        assertEquals(3, manager().activeNotifications.size)
        assertEquals(1, manager().activeNotifications.count { it.notification.has(Notification.FLAG_GROUP_SUMMARY) })
    }

    @Test fun noSummaryWithoutAGroupOrForAnotherLayout() {
        channel()
        build()
        build(Definitions.NOTIFICATION_GROUP_KEY to "g", Definitions.NOTIFICATION_LAYOUT to "BigText")
        build(Definitions.NOTIFICATION_GROUP_KEY to "g", Definitions.NOTIFICATION_LAYOUT to "Messaging")
        assertEquals(0, manager().activeNotifications.size)
    }

    @Test fun createNotificationPostsTheSummaryAndTheNotification() {
        channel()
        val core = AwesomeNotifications(context, Executor { it.run() })
        core.createNotification(model(Definitions.NOTIFICATION_GROUP_KEY to "g")) {}
        val active = manager().activeNotifications
        assertEquals(2, active.size)
        assertEquals(1, active.count { it.id == 1 })
        assertTrue(active.all { it.notification.group == "g" })
    }

    // MARK: - Action buttons

    private fun button(vararg extra: Pair<String, Any?>) = mapOf(
        Definitions.NOTIFICATION_BUTTON_KEY to "k",
        Definitions.NOTIFICATION_BUTTON_LABEL to "Label",
        Definitions.NOTIFICATION_ACTION_TYPE to "SilentAction"
    ) + mapOf(*extra)

    private fun action(button: Map<String, Any?>): Notification.Action =
        builder.createNotificationContent(context, model(buttons = listOf(button)))!!.actions[0]

    @Test fun aDangerousButtonIsRed() {
        channel()
        val title = action(button(Definitions.NOTIFICATION_IS_DANGEROUS_OPTION to true)).title as Spanned
        assertEquals("Label", title.toString())
        val spans = title.getSpans(0, title.length, ForegroundColorSpan::class.java)
        assertEquals(1, spans.size)
        assertEquals(0xFF0000, spans[0].foregroundColor and 0xFFFFFF)
    }

    @Test fun aButtonColorColorsItsLabel() {
        channel()
        val title = action(button(Definitions.NOTIFICATION_COLOR to 0xFF00FF00L)).title
        assertEquals("Label", title.toString())
        assertTrue((title as Spanned).getSpans(0, title.length, ForegroundColorSpan::class.java).isNotEmpty())
        val plain = action(button()).title
        assertEquals("Label", plain.toString())
    }

    @Test fun aButtonCanRequireAuthentication() {
        channel()
        assertTrue(action(button(Definitions.NOTIFICATION_AUTHENTICATION_REQUIRED to true)).isAuthenticationRequired)
        assertFalse(action(button()).isAuthenticationRequired)
    }

    // MARK: - Channel groups

    @Test fun aChannelJoinsItsGroupWhenTheGroupExists() {
        val core = AwesomeNotifications(context, Executor { it.run() })
        core.initialize(
            listOf(
                mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "a", Definitions.NOTIFICATION_CHANNEL_NAME to "A",
                    Definitions.NOTIFICATION_CHANNEL_GROUP_KEY to "grp"),
                mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "b", Definitions.NOTIFICATION_CHANNEL_NAME to "B",
                    Definitions.NOTIFICATION_CHANNEL_GROUP_KEY to "missing")),
            null,
            listOf(
                mapOf(Definitions.NOTIFICATION_CHANNEL_GROUP_KEY to "grp",
                    Definitions.NOTIFICATION_CHANNEL_GROUP_NAME to "Group"),
                // 0.12: a group without a name is skipped.
                mapOf(Definitions.NOTIFICATION_CHANNEL_GROUP_KEY to "nameless")))
        assertEquals(listOf("grp"), manager().notificationChannelGroups.map { it.id })
        assertEquals("Group", manager().getNotificationChannelGroup("grp").name)
        assertEquals("grp", manager().getNotificationChannel("a").group)
        assertNull(manager().getNotificationChannel("b").group)
    }
}
