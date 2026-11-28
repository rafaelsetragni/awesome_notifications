package me.carda.android_awn_core

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import androidx.core.text.HtmlCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Builds notifications from a serialized `NotificationModel`, injects the full
 * model into the tap/dismiss PendingIntents so it can be recovered later, and
 * stamps the lifecycle events (created/displayed/pressed/dismissed).
 *
 * Created via a factory (an instance with injected helpers — not static utility
 * methods), mirroring the original AndroidAwnCore `NotificationBuilder`.
 *
 * This is also the base of the builder **decorator chain**: an add-on subclasses
 * it, overrides [build], does its work and calls [next] to delegate to the
 * wrapped inner builder. The [NotificationBuilderRegistry] composes the chain in
 * priority order so the build order is predictable.
 */
open class NotificationBuilder protected constructor(
    private val inner: NotificationBuilder? = null,
    private val stringUtils: StringUtils = StringUtils.getInstance(),
    private val mapUtils: MapUtils = MapUtils.getInstance(),
    private val jsonUtils: JsonUtils = JsonUtils.getInstance(),
    private val bitmapUtils: BitmapUtils = BitmapUtils.getInstance()
) {
    companion object {
        fun getNewBuilder(): NotificationBuilder = NotificationBuilder()

        /**
         * Set by a decorator that renders the layout itself (e.g. the messaging
         * add-on): the core then skips its built-in layout for that model.
         */
        const val CUSTOM_LAYOUT = "awn.customLayout"
    }

    // MARK: - Decorator chain

    /**
     * Produces the [BuildOutcome] for a model. The base builds the content and
     * asks the caller to post it now; a decorator overrides this, does its work
     * (transform the model, or take over delivery), and calls [next] to delegate
     * to the wrapped builder.
     */
    open fun build(context: Context, model: Map<String, Any?>): BuildOutcome {
        // Immediate delivery: stamp created + displayed (now) into the content so
        // both round-trip to the action event via the tap PendingIntent (a tapped
        // notification would otherwise report null created/displayed dates).
        // Scheduling decorators intercept before this and stamp their own dates.
        val stamped = stampDisplayedLifecycle(
            stampCreatedLifecycle(model),
            displayedDate = nowUtc(),
            lifeCycle = NotificationLifeCycle.Foreground)
        val prepared = prepareLayout(context, stamped)
        val notification = try {
            createNotificationContent(context, prepared)
        } catch (e: SecurityException) {
            // 0.12: the wake lock without WAKE_LOCK fails the whole send, which
            // the create call answered as a NOTIFICATION_THREAD_EXCEPTION.
            return BuildOutcome.Failed(
                Definitions.CODE_NOTIFICATION_THREAD_EXCEPTION,
                "${e.localizedMessage}", // 0.12 String.format("%s", …)
                Definitions.DETAILED_UNEXPECTED_ERROR
            )
        } ?: return BuildOutcome.Invalid
        val id = notificationId(prepared) ?: return BuildOutcome.Invalid
        return BuildOutcome.Post(id, notification, prepared)
    }

    /** Delegates to the wrapped inner builder (called by decorators). */
    fun next(context: Context, model: Map<String, Any?>): BuildOutcome =
        inner?.build(context, model) ?: BuildOutcome.Invalid

    /**
     * Decorator seam on the Android builder itself: called once per notification
     * (immediate or scheduled), after the core applied its content (texts,
     * images, layout, buttons) and right before `build()`, on the registered
     * chain from the outermost decorator inwards. A decorator
     * overrides it to set what the model can't express (a style, a shortcut,
     * extras) and calls `super.decorate` to let the inner ones do theirs.
     */
    open fun decorate(
        context: Context,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        inner?.decorate(context, model, builder)
    }

    /** Whether a decorator renders this model's layout itself. */
    fun hasCustomLayout(model: Map<String, Any?>): Boolean = model[CUSTOM_LAYOUT] == true

    /**
     * The model step of the layout, right before delivery (immediate or at a
     * schedule's fire time): the 0.12 messaging layouts may move the message
     * under its conversation's id and add the history. Unchanged when a
     * decorator renders the layout itself.
     */
    fun prepareLayout(context: Context, model: Map<String, Any?>): Map<String, Any?> =
        if (hasCustomLayout(model)) model
        else MediaPlayerLayout.prepare(context, MessagingLayout.prepare(context, model))

    // MARK: - Lifecycle stamping (persisted into the stored content)

    /**
     * Returns a copy of [model] with the created lifecycle (date/source/lifeCycle)
     * merged into its `content` sub-map, unless already present. Persisting it in
     * the content is what lets a later displayed/action event carry the
     * createdDate — the tap/dismiss PendingIntents serialize this content.
     */
    fun stampCreatedLifecycle(
        model: Map<String, Any?>,
        lifeCycle: NotificationLifeCycle = NotificationLifeCycle.Foreground,
        source: NotificationSource = NotificationSource.Local
    ): Map<String, Any?> {
        val content = contentMap(model).toMutableMap()
        if (content[Definitions.NOTIFICATION_CREATED_DATE] == null) {
            content[Definitions.NOTIFICATION_CREATED_DATE] = now()
            content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = lifeCycle.name
            content[Definitions.NOTIFICATION_CREATED_SOURCE] = source.name
        }
        return model.toMutableMap().apply { this[Definitions.NOTIFICATION_CONTENT] = content }
    }

    /**
     * Returns a copy of [model] with the displayed lifecycle merged into its
     * `content` sub-map. Immediate delivery passes the current time; a scheduled
     * receiver passes the actual fire time when it posts.
     */
    fun stampDisplayedLifecycle(
        model: Map<String, Any?>,
        displayedDate: String,
        lifeCycle: NotificationLifeCycle
    ): Map<String, Any?> {
        val content = contentMap(model).toMutableMap()
        content[Definitions.NOTIFICATION_DISPLAYED_DATE] = displayedDate
        content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] = lifeCycle.name
        return model.toMutableMap().apply { this[Definitions.NOTIFICATION_CONTENT] = content }
    }

    /** Current UTC timestamp, formatted like every other lifecycle date. */
    fun nowUtc(): String = now()

    // MARK: - Build

    /**
     * Builds an Android notification from a serialized model, or null if
     * invalid. As 0.12 `NotificationSender`, a notification of a group with
     * nothing of that group on screen first posts the group's summary (see
     * [postGroupSummary]); the caller then posts this one.
     */
    fun createNotificationContent(context: Context, model: Map<String, Any?>): Notification? =
        createNotificationContent(context, model, groupSummary = false)

    /**
     * The 0.12 `getNotificationBuilderFromModel` steps, in its order (the
     * steps that only touch independent builder fields stay where 1.0 had
     * them). [groupSummary] builds the group's summary notification.
     */
    private fun createNotificationContent(
        context: Context,
        model: Map<String, Any?>,
        groupSummary: Boolean
    ): Notification? {
        val content = contentMap(model)
        val id = mapUtils.getInt(content[Definitions.NOTIFICATION_ID]) ?: return null
        val channelKey =
            mapUtils.getString(content[Definitions.NOTIFICATION_CHANNEL_KEY]) ?: return null

        val channel = ChannelManager.getChannel(channelKey)
        // 0.12 `getChannelByKey`: on Android 8+ the channel's importance,
        // vibration and lights are read back from its Android channel.
        val androidChannel =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                ChannelManager.getAndroidChannel(context, channelKey)
            else null
        val layout =
            NotificationLayout.from(mapUtils.getString(content[Definitions.NOTIFICATION_LAYOUT]))
        val groupKey = groupKey(content, channel)
        val contentIntent = contentIntent(context, id, model)
        val builder = NotificationCompat.Builder(context, channelKey)
            .setSmallIcon(smallIcon(context, content, channel))
            .setAutoCancel(shouldAutoDismiss(content))
            .setContentIntent(contentIntent)
        // 0.12 `setNotificationPendingIntents`: a group summary has no dismiss intent.
        if (!groupSummary) builder.setDeleteIntent(deleteIntent(context, id, model))

        setTitle(content, builder)
        setBody(content, builder)
        setSummary(content, builder)
        setGrouping(content, layout, groupKey, channel, groupSummary, id, builder)
        setVisibility(content, channel, builder)
        setShowWhen(content, builder)
        if (!hasCustomLayout(model)) setLayout(context, content, layout, builder)
        setLargeIcon(context, content, layout, builder)
        setTicker(content, builder)
        setOnlyAlertOnce(layout, channel, builder)
        setImportance(channel, androidChannel, builder)
        setChronometer(content, builder)
        setTimeoutAfter(content, builder)
        setVibrationPattern(channel, androidChannel, builder)
        setLights(channel, androidChannel, builder)
        setLayoutColor(content, channel, builder)

        val buttonIntents = applyActionButtons(context, id, model, builder)
        if (!hasCustomLayout(model)) {
            MediaPlayerLayout.applyStyle(
                context, content, actionButtons(model), buttonIntents, builder, bitmapUtils)
        }
        builder.addExtras(MessagingLayout.groupExtras(context, id, groupKey))

        setLockedNotification(content, channel, builder)
        setCategory(content, builder)
        setSound(context, content, channelKey, channel, builder)
        setFullScreenIntent(content, contentIntent, builder)

        NotificationBuilderRegistry.makeBuilder().decorate(context, model, builder)

        val notification = builder.build()
        setWakeUpScreen(context, content)
        setCategoryFlags(content, notification)
        if (!groupSummary) postGroupSummary(context, model, content, layout, groupKey)
        return notification
    }

    // MARK: - 0.12 texts, grouping, visibility and alerting

    /** 0.12 `setTitle`: the title as HTML. */
    private fun setTitle(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE]) ?: return
        builder.setContentTitle(HtmlUtils.fromHtml(title))
    }

    /** 0.12 `setBody`: the body as HTML. */
    private fun setBody(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY]) ?: return
        builder.setContentText(HtmlUtils.fromHtml(body))
    }

    /** 0.12 `setSummary`: the `summary` (as HTML) is the sub text. */
    private fun setSummary(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val summary = ChannelManager.string012(content[Definitions.NOTIFICATION_SUMMARY]) ?: return
        builder.setSubText(HtmlUtils.fromHtml(summary))
    }

    /** 0.12 `getGroupKey`: the content's `groupKey`, else the channel's. */
    private fun groupKey(content: Map<String, Any?>, channel: Map<String, Any?>?): String? {
        val contentKey = ChannelManager.string012(content[Definitions.NOTIFICATION_GROUP_KEY])
        return if (!stringUtils.isNullOrEmpty(contentKey)) contentKey
        else ChannelManager.groupKey(channel)
    }

    /**
     * 0.12 `setGrouping`, quirks included: not for the Messaging layouts
     * (their group is the conversation). With a group key: the group, the
     * summary flag for the group summary, a sort key of the current time
     * (`groupSort: Asc`; any other value sorts descending, as
     * `Long.MAX_VALUE - now`) followed by the id, and the channel's
     * `groupAlertBehavior` (default All).
     */
    private fun setGrouping(
        content: Map<String, Any?>,
        layout: NotificationLayout,
        groupKey: String?,
        channel: Map<String, Any?>?,
        groupSummary: Boolean,
        id: Int,
        builder: NotificationCompat.Builder
    ) {
        if (MessagingLayout.isMessaging(layout)) return
        if (stringUtils.isNullOrEmpty(groupKey)) return
        builder.setGroup(groupKey)
        if (groupSummary) builder.setGroupSummary(true)
        val now = System.currentTimeMillis()
        val sortKey =
            (if (ChannelManager.groupSort(channel) == GroupSort.Asc) now else Long.MAX_VALUE - now)
                .toString()
        builder.setSortKey(sortKey + id.toString())
        builder.setGroupAlertBehavior(ChannelManager.groupAlertBehavior(channel).ordinal)
    }

    /**
     * 0.12 `NotificationSender` + `_buildSummaryGroupNotification`, quirks
     * included: on Android 7+, a `Default` layout notification of a group
     * with nothing of that group on screen first posts a summary of the
     * group — a copy of the notification under a new random id, without its
     * large icon and big picture — so later ones stack under it. The summary
     * then counts as on screen, so the next ones of the group post none.
     * Not for a layout a decorator renders itself.
     */
    private fun postGroupSummary(
        context: Context,
        model: Map<String, Any?>,
        content: Map<String, Any?>,
        layout: NotificationLayout,
        groupKey: String?
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        if (layout != NotificationLayout.Default || hasCustomLayout(model)) return
        if (stringUtils.isNullOrEmpty(groupKey)) return
        if (MessagingLayout.activeIdsOfGroup(context, groupKey).isNotEmpty()) return

        val summaryId = nextRandomId()
        val summaryContent = content.toMutableMap().apply {
            this[Definitions.NOTIFICATION_ID] = summaryId
            this[Definitions.NOTIFICATION_LAYOUT] = NotificationLayout.Default.name
            this[Definitions.NOTIFICATION_LARGE_ICON] = null
            this[Definitions.NOTIFICATION_BIG_PICTURE] = null
        }
        val summaryModel =
            model.toMutableMap().apply { this[Definitions.NOTIFICATION_CONTENT] = summaryContent }
        val summary = createNotificationContent(context, summaryModel, groupSummary = true) ?: return
        try {
            NotificationManagerCompat.from(context).notify(summaryId, summary)
        } catch (_: SecurityException) {
            // No POST_NOTIFICATIONS: the notification's own post reports it.
        }
    }

    /** 0.12 `IntegerUtils.generateNextRandomId`: a random int, made positive. */
    private fun nextRandomId(): Int {
        val value = random.nextInt()
        return if (value < 0) value * -1 else value
    }

    private val random = java.security.SecureRandom()

    /**
     * 0.12 `setVisibility`, quirk included: the content's `privacy`, else the
     * channel's `defaultPrivacy` (default Private). But 0.12's content model
     * defaults `privacy` to Private, so the channel's applies only when the
     * content's is a text that is no privacy at all.
     */
    private fun setVisibility(
        content: Map<String, Any?>,
        channel: Map<String, Any?>?,
        builder: NotificationCompat.Builder
    ) {
        val privacy = NotificationPrivacy.fromMapValue(
            content[Definitions.NOTIFICATION_PRIVACY], NotificationPrivacy.Private)
            ?: ChannelManager.defaultPrivacy(channel)
        builder.setVisibility(NotificationPrivacy.toAndroidPrivacy(privacy))
    }

    /** 0.12 `showWhen`: only a Boolean counts; default true. */
    private fun showWhen(content: Map<String, Any?>): Boolean =
        content[Definitions.NOTIFICATION_SHOW_WHEN] as? Boolean ?: true

    /** 0.12 `setShowWhen`: the time is shown unless `showWhen: false`. */
    private fun setShowWhen(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        builder.setShowWhen(showWhen(content))
    }

    /**
     * 0.12 `setTicker`: the `ticker`, else the `summary`, else the `body`,
     * else the `title` (the first one not blank).
     */
    private fun setTicker(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        fun orElse(value: String?, default: String?) =
            if (stringUtils.isNullOrEmpty(value)) default else value
        var ticker = orElse(ChannelManager.string012(content[Definitions.NOTIFICATION_TICKER]), "")
        ticker = orElse(ticker, ChannelManager.string012(content[Definitions.NOTIFICATION_SUMMARY]))
        ticker = orElse(ticker, ChannelManager.string012(content[Definitions.NOTIFICATION_BODY]))
        ticker = orElse(ticker, ChannelManager.string012(content[Definitions.NOTIFICATION_TITLE]))
        builder.setTicker(ticker)
    }

    /**
     * 0.12 `setOnlyAlertOnce`: a `ProgressBar` layout (its updates must not
     * ring again) or a channel with `onlyAlertOnce: true`.
     */
    private fun setOnlyAlertOnce(
        layout: NotificationLayout,
        channel: Map<String, Any?>?,
        builder: NotificationCompat.Builder
    ) {
        builder.setOnlyAlertOnce(
            layout == NotificationLayout.ProgressBar || ChannelManager.onlyAlertOnce(channel))
    }

    /**
     * 0.12 `setImportance`: the channel's importance as the notification's
     * priority (what Android 7 and older use). On Android 8+ it is read back
     * from the Android channel, so a user's change counts.
     */
    private fun setImportance(
        channel: Map<String, Any?>?,
        androidChannel: android.app.NotificationChannel?,
        builder: NotificationCompat.Builder
    ) {
        val importance = androidChannel
            ?.let { NotificationImportance.fromAndroidImportance(it.importance) }
            ?: ChannelManager.importance(channel)
        builder.setPriority(importance.toAndroidPriority())
    }

    /**
     * 0.12 `setChronometer`, quirks included: a `chronometer` of 0 or more
     * seconds (and `showWhen` not false) counts up from that many seconds
     * ago (`when` = now − seconds × 1000, an int product as in 0.12).
     */
    private fun setChronometer(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val chronometer =
            (content[Definitions.NOTIFICATION_CHRONOMETER] as? Number)?.toInt() ?: return
        if (chronometer < 0 || !showWhen(content)) return
        builder.setWhen(System.currentTimeMillis() - chronometer * 1000)
        builder.setUsesChronometer(true)
    }

    /**
     * 0.12 `setTimeoutAfter`: a `timeoutAfter` of 1 or more seconds removes
     * the notification after that time (an int product, as in 0.12).
     */
    private fun setTimeoutAfter(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val timeoutAfter =
            (content[Definitions.NOTIFICATION_TIMEOUT_AFTER] as? Number)?.toInt() ?: return
        if (timeoutAfter < 1) return
        builder.setTimeoutAfter((timeoutAfter * 1000).toLong())
    }

    /**
     * 0.12 `setVibrationPattern` (what Android 7 and older use): a vibrating
     * channel uses its pattern, when it has one; a channel that does not
     * vibrate sets the `[0]` pattern. On Android 8+ whether it vibrates is
     * read back from the Android channel.
     */
    private fun setVibrationPattern(
        channel: Map<String, Any?>?,
        androidChannel: android.app.NotificationChannel?,
        builder: NotificationCompat.Builder
    ) {
        val enableVibration = androidChannel?.shouldVibrate() ?: ChannelManager.enableVibration(channel)
        if (enableVibration) {
            val pattern = ChannelManager.vibrationPattern(channel)
            if (pattern != null && pattern.isNotEmpty()) builder.setVibrate(pattern)
        } else {
            builder.setVibrate(longArrayOf(0))
        }
    }

    /**
     * 0.12 `setLights` (what Android 7 and older use): a channel with lights
     * blinks its `ledColor` (default white) `ledOnMs` on (300) / `ledOffMs`
     * off (700). On Android 8+ whether it has lights is read back from the
     * Android channel.
     */
    private fun setLights(
        channel: Map<String, Any?>?,
        androidChannel: android.app.NotificationChannel?,
        builder: NotificationCompat.Builder
    ) {
        val enableLights = androidChannel?.shouldShowLights() ?: ChannelManager.enableLights(channel)
        if (enableLights) {
            builder.setLights(
                ChannelManager.ledColor(channel),
                ChannelManager.ledOnMs(channel),
                ChannelManager.ledOffMs(channel))
        }
    }

    /**
     * 0.12 `setLayoutColor`, quirks included: with a `backgroundColor` (a
     * number) the notification is colorized with it; otherwise the accent
     * color is the content's `color`, else the channel's `defaultColor`. Black
     * means "no color" in that fallback, so an unset color is set as black
     * (not left at Android's default) and a content color of black takes the
     * channel's.
     */
    private fun setLayoutColor(
        content: Map<String, Any?>,
        channel: Map<String, Any?>?,
        builder: NotificationCompat.Builder
    ) {
        val backgroundColor = (content[Definitions.NOTIFICATION_BACKGROUND_COLOR] as? Number)?.toInt()
        if (backgroundColor == null) {
            builder.setColor(layoutColor(content, channel))
        } else {
            builder.setColorized(true)
            builder.setColor(backgroundColor)
        }
    }

    /** 0.12 `getLayoutColor`. */
    private fun layoutColor(content: Map<String, Any?>, channel: Map<String, Any?>?): Int {
        val color = (content[Definitions.NOTIFICATION_COLOR] as? Number)?.toInt() ?: Color.BLACK
        if (color != Color.BLACK) return color
        return ChannelManager.defaultColor(channel)
    }

    // MARK: - 0.12 layouts (setLayout)

    /**
     * 0.12 `setLayout`: the layout's style (BigPicture, BigText, Inbox,
     * Messaging, ProgressBar; MediaPlayer needs the buttons' intents, so it
     * is applied after them). A layout whose content is missing falls back to
     * the default one; a failure is logged and ignored, as in 0.12.
     */
    private fun setLayout(
        context: Context,
        content: Map<String, Any?>,
        layout: NotificationLayout,
        builder: NotificationCompat.Builder
    ) {
        try {
            when (layout) {
                NotificationLayout.BigPicture -> setBigPictureLayout(context, content, builder)
                NotificationLayout.BigText -> setBigTextStyle(content, builder)
                NotificationLayout.Inbox -> setInboxLayout(content, builder)
                NotificationLayout.Messaging, NotificationLayout.MessagingGroup ->
                    MessagingLayout.applyStyle(context, content, builder, bitmapUtils)
                NotificationLayout.ProgressBar -> setProgressLayout(content, builder)
                else -> {}
            }
        } catch (e: Exception) {
            android.util.Log.e("NotificationBuilder", "${e.message}")
        }
    }

    private fun rounded(content: Map<String, Any?>, key: String): Boolean =
        content[key] as? Boolean ?: false

    /**
     * 0.12 `setBigPictureLayout`, quirks included: with `hideLargeIconOnExpand`
     * the large icon is the big picture itself (or, without one, the large
     * icon, rounded if either is), and it is hidden when expanded; otherwise
     * the large icon (the big picture's bitmap when both paths are equal).
     * Without a big picture only the large icon is set. Expanded, the title
     * and the BODY (as the summary text) show.
     */
    private fun setBigPictureLayout(
        context: Context,
        content: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ): Boolean {
        val bigPictureReference = ChannelManager.string012(content[Definitions.NOTIFICATION_BIG_PICTURE])
        val largeIconReference = ChannelManager.string012(content[Definitions.NOTIFICATION_LARGE_ICON])
        val hideLargeIconOnExpand =
            content[Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND] as? Boolean ?: false
        val roundedLargeIcon = rounded(content, Definitions.NOTIFICATION_ROUNDED_LARGE_ICON)
        val roundedBigPicture = rounded(content, Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE)

        var bigPicture: Bitmap? = null
        var largeIcon: Bitmap? = null
        if (!stringUtils.isNullOrEmpty(bigPictureReference)) {
            bigPicture = bitmapUtils.getBitmapFromSource(context, bigPictureReference, roundedBigPicture)
        }
        if (hideLargeIconOnExpand) {
            largeIcon = bigPicture
                ?: if (!stringUtils.isNullOrEmpty(largeIconReference))
                    bitmapUtils.getBitmapFromSource(
                        context, largeIconReference, roundedLargeIcon || roundedBigPicture)
                else null
        } else {
            val areEqual = !stringUtils.isNullOrEmpty(largeIconReference) &&
                largeIconReference == bigPictureReference
            if (areEqual) largeIcon = bigPicture
            else if (!stringUtils.isNullOrEmpty(largeIconReference))
                largeIcon = bitmapUtils.getBitmapFromSource(context, largeIconReference, roundedLargeIcon)
        }

        if (largeIcon != null) builder.setLargeIcon(largeIcon)
        if (bigPicture == null) return false

        val style = NotificationCompat.BigPictureStyle()
        style.bigPicture(bigPicture)
        style.bigLargeIcon(if (hideLargeIconOnExpand) null else largeIcon)
        val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
        if (!stringUtils.isNullOrEmpty(title)) style.setBigContentTitle(HtmlUtils.fromHtml(title))
        val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
        if (!stringUtils.isNullOrEmpty(body)) style.setSummaryText(HtmlUtils.fromHtml(body))
        builder.setStyle(style)
        return true
    }

    /**
     * 0.12 `setBigTextStyle`: expanded, the whole body (HTML), with the
     * summary and title. Without a body the default layout is kept.
     */
    private fun setBigTextStyle(content: Map<String, Any?>, builder: NotificationCompat.Builder): Boolean {
        val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
        if (stringUtils.isNullOrEmpty(body)) return false
        val style = NotificationCompat.BigTextStyle()
        style.bigText(HtmlUtils.fromHtml(body))
        val summary = ChannelManager.string012(content[Definitions.NOTIFICATION_SUMMARY])
        if (!stringUtils.isNullOrEmpty(summary)) style.setSummaryText(HtmlUtils.fromHtml(summary))
        val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
        if (!stringUtils.isNullOrEmpty(title)) style.setBigContentTitle(HtmlUtils.fromHtml(title))
        builder.setStyle(style)
        return true
    }

    /**
     * 0.12 `setInboxLayout`, quirks included: each line of the body is an
     * inbox line (Java `split`, so trailing empty lines are dropped). The
     * summary text is the `summary`; without one it is "+ N more" (N = the
     * number of lines). A blank but present `summary` leaves no summary text.
     */
    private fun setInboxLayout(content: Map<String, Any?>, builder: NotificationCompat.Builder): Boolean {
        val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
        if (stringUtils.isNullOrEmpty(body)) return false
        val lines = body!!.split(Regex("\\r?\\n")).dropLastWhile { it.isEmpty() }
        if (lines.isEmpty()) return false

        val style = NotificationCompat.InboxStyle()
        val summary = ChannelManager.string012(content[Definitions.NOTIFICATION_SUMMARY])
        // 0.12 quirk: with a summary, this first summary text is the BODY;
        // the summary replaces it right below.
        style.setSummaryText(
            if (stringUtils.isNullOrEmpty(summary)) "+ ${lines.size} more"
            else HtmlUtils.fromHtml(body))
        val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
        if (!stringUtils.isNullOrEmpty(title)) style.setBigContentTitle(HtmlUtils.fromHtml(title))
        if (summary != null) style.setSummaryText(HtmlUtils.fromHtml(summary))
        for (line in lines) style.addLine(HtmlUtils.fromHtml(line))
        builder.setStyle(style)
        return true
    }

    /**
     * 0.12 `setProgressLayout`: a 0–100 bar at `progress` (truncated and
     * clamped to 0…100); indeterminate without a `progress`.
     */
    private fun setProgressLayout(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        val progress = progress012(content[Definitions.NOTIFICATION_PROGRESS])
        builder.setProgress(100, maxOf(0, minOf(100, progress?.toInt() ?: 0)), progress == null)
    }

    /** 0.12 `progress` (a Float): a number, or a numeric text; else null. */
    private fun progress012(value: Any?): Float? = when (value) {
        is Number -> value.toFloat()
        is String -> value.toFloatOrNull()
        else -> null
    }

    /**
     * 0.12 `setLargeIcon`: the large icon (rounded with `roundedLargeIcon`),
     * except for the BigPicture layout, which sets its own.
     */
    private fun setLargeIcon(
        context: Context,
        content: Map<String, Any?>,
        layout: NotificationLayout,
        builder: NotificationCompat.Builder
    ) {
        if (layout == NotificationLayout.BigPicture) return
        val largeIconReference = ChannelManager.string012(content[Definitions.NOTIFICATION_LARGE_ICON])
        if (stringUtils.isNullOrEmpty(largeIconReference)) return
        bitmapUtils.getBitmapFromSource(
            context, largeIconReference, rounded(content, Definitions.NOTIFICATION_ROUNDED_LARGE_ICON))
            ?.let { builder.setLargeIcon(it) }
    }

    // MARK: - 0.12 content / channel options

    /**
     * 0.12 `setSmallIcon`: the content's `icon`, else the channel's `icon`,
     * else the `defaultIcon` given to `initialize`, else `mipmap/ic_launcher`
     * (each a `resource://drawable/name`, `res_name` tried first). Android
     * draws it as a silhouette (only its alpha), so a full-color launcher
     * icon shows as a solid square.
     *
     * Where 0.12 set a missing resource (id 0) and the post failed, 1.0 keeps
     * looking down the list, and ends at the app's launcher icon.
     */
    private fun smallIcon(context: Context, content: Map<String, Any?>, channel: Map<String, Any?>?): Int {
        val bitmaps = BitmapUtils.getInstance()
        val content012 = mapUtils.getString(content[Definitions.NOTIFICATION_ICON])
        val channel012 = mapUtils.getString(channel?.get(Definitions.NOTIFICATION_ICON))
        val default012 = DefaultsManager.getDefaultIcon(context)
        for (reference in listOf(content012, channel012, default012)) {
            if (reference.isNullOrEmpty()) continue
            val id = bitmaps.getDrawableResourceId(context, reference)
            if (id != 0) return id
        }
        val launcher = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
        return if (launcher != 0) launcher else context.applicationInfo.icon
    }

    /**
     * 0.12 `setLockedNotification`, quirk included: content `locked: true`
     * makes the notification ongoing; otherwise a channel `locked: true`
     * applies the content's own value, defaulting to true. But 0.12's content
     * model always defaults `locked` to false, so a content without `locked`
     * reads false and a locked channel alone never locks a notification.
     * Only a Boolean counts (0.12 `getValueOrDefault`).
     */
    private fun setLockedNotification(
        content: Map<String, Any?>,
        channel: Map<String, Any?>?,
        builder: NotificationCompat.Builder
    ) {
        // 0.12 content model: `locked` defaults to false (never null).
        val contentLocked = content[Definitions.NOTIFICATION_LOCKED] as? Boolean ?: false
        val channelLocked = ChannelManager.locked(channel)
        if (contentLocked) {
            builder.setOngoing(true)
        } else if (channelLocked) {
            // 0.12 `getValueOrDefault(content.locked, true)`: the content's
            // false, so the locked channel has no effect.
            builder.setOngoing(contentLocked)
        }
    }

    /** 0.12 `setCategory`: the category's raw value (e.g. `Call` → `call`). */
    private fun setCategory(content: Map<String, Any?>, builder: NotificationCompat.Builder) {
        NotificationCategory.from(content[Definitions.NOTIFICATION_CATEGORY])
            ?.let { builder.setCategory(it.rawValue) }
    }

    /**
     * 0.12 `setSound`: when the channel plays sound (Android 8+: its Android
     * channel has a sound, as 0.12 read it back), the content's `customSound`
     * or else the channel's `soundSource`, or without either the default sound
     * of the channel's `defaultRingtoneType`; otherwise no sound. (Android 8+
     * plays the channel's sound; this is what Android 7 plays.)
     */
    private fun setSound(
        context: Context,
        content: Map<String, Any?>,
        channelKey: String,
        channel: Map<String, Any?>?,
        builder: NotificationCompat.Builder
    ) {
        val playSound =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ChannelManager.getAndroidChannel(context, channelKey)?.let { it.sound != null }
                    ?: ChannelManager.playSound(channel)
            } else {
                ChannelManager.playSound(channel)
            }
        var uri: android.net.Uri? = null
        if (playSound) {
            val customSound = content[Definitions.NOTIFICATION_CUSTOM_SOUND] as? String
            val soundSource = if (stringUtils.isNullOrEmpty(customSound))
                channel?.get(Definitions.NOTIFICATION_SOUND_SOURCE) as? String
            else customSound
            uri = ChannelManager.retrieveSoundResourceUri(
                context, ChannelManager.defaultRingtoneType(channel), soundSource)
        }
        builder.setSound(uri)
    }

    /** 0.12 `setFullScreenIntent`: `fullScreenIntent: true` uses the tap intent. */
    private fun setFullScreenIntent(
        content: Map<String, Any?>,
        contentIntent: PendingIntent,
        builder: NotificationCompat.Builder
    ) {
        if (content[Definitions.NOTIFICATION_FULL_SCREEN_INTENT] as? Boolean == true) {
            builder.setFullScreenIntent(contentIntent, true)
        }
    }

    /**
     * 0.12 `setCategoryFlags`, after the build: `Alarm` is insistent and can't
     * be cleared; `Call` is also high priority.
     */
    private fun setCategoryFlags(content: Map<String, Any?>, notification: Notification) {
        when (NotificationCategory.from(content[Definitions.NOTIFICATION_CATEGORY])) {
            NotificationCategory.Alarm -> {
                notification.flags = notification.flags or
                    Notification.FLAG_INSISTENT or Notification.FLAG_NO_CLEAR
            }
            NotificationCategory.Call -> {
                @Suppress("DEPRECATION")
                notification.flags = notification.flags or Notification.FLAG_INSISTENT or
                    Notification.FLAG_HIGH_PRIORITY or Notification.FLAG_NO_CLEAR
            }
            else -> {}
        }
    }

    /**
     * 0.12 `setWakeUpScreen` / `wakeUpScreen`, after the build and before the
     * notification is shown: `wakeUpScreen: true` with the screen off turns it
     * on for 3 s (a bright screen wake lock). The app declares WAKE_LOCK
     * itself (since 0.10); without it the wake lock throws a
     * SecurityException and, as in 0.12, the notification is not shown and
     * the create call fails (see [build]).
     */
    private fun setWakeUpScreen(context: Context, content: Map<String, Any?>) {
        if (content[Definitions.NOTIFICATION_WAKE_UP_SCREEN] as? Boolean == true) {
            wakeUpScreen(context)
        }
    }

    fun wakeUpScreen(context: Context) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isInteractive) {
            @Suppress("DEPRECATION")
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                appName(context) + ":NotificationBuilder:WakeupLock"
            )
            wakeLock.acquire(3000)
        }
    }

    /** 0.12 `getAppName`. */
    private fun appName(context: Context): String {
        val info = context.applicationInfo
        return if (info.labelRes == 0) info.nonLocalizedLabel?.toString() ?: ""
        else context.getString(info.labelRes)
    }

    // MARK: - Action buttons

    @Suppress("UNCHECKED_CAST")
    fun actionButtons(model: Map<String, Any?>): List<Map<String, Any?>> =
        (model[Definitions.NOTIFICATION_BUTTONS] as? List<Map<String, Any?>>) ?: emptyList()

    /**
     * Adds an [NotificationCompat.Action] for each serialized action button and
     * returns each one's intent by key. As 0.12, a disabled button is still
     * shown, without an intent (so the media layout's compact view indexes
     * keep pointing at the right buttons).
     *
     * 0.12 `createActionButtons`, quirks included: a reply button is left out
     * below Android 7; the label is HTML, red for `isDangerousOption`, else in
     * the button's `color` (its int as a `<font color>`); and
     * `isAuthenticationRequired` asks to unlock the device first.
     */
    private fun applyActionButtons(
        context: Context,
        id: Int,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ): Map<String, PendingIntent?> {
        val intents = mutableMapOf<String, PendingIntent?>()
        actionButtons(model).forEachIndexed { index, button ->
            val key = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_KEY])
            if (key.isNullOrEmpty()) return@forEachIndexed
            val enabled = mapUtils.getBool(button[Definitions.NOTIFICATION_BUTTON_ENABLED]) != false

            val label = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_LABEL]) ?: key
            val actionType =
                ActionType.from(mapUtils.getString(button[Definitions.NOTIFICATION_ACTION_TYPE]))
            val requireInput =
                mapUtils.getBool(button[Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT]) ?: false
            val isForeground = actionType == ActionType.Default
            // 0.12: a reply is not available below Android 7.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N && requireInput) return@forEachIndexed

            val pending = if (enabled) {
                buttonPendingIntent(context, id, index, key, model, isForeground, requireInput)
            } else {
                null
            }
            intents[key] = pending
            val actionBuilder = NotificationCompat.Action.Builder(
                buttonIcon(context, button), buttonLabel(button, label), pending
            ).setAuthenticationRequired(
                button[Definitions.NOTIFICATION_AUTHENTICATION_REQUIRED] as? Boolean ?: false)
            if (requireInput) {
                actionBuilder.addRemoteInput(
                    RemoteInput.Builder(Definitions.NOTIFICATION_BUTTON_KEY_INPUT)
                        .setLabel(label)
                        .build()
                )
            }
            builder.addAction(actionBuilder.build())
        }
        return intents
    }

    /** 0.12: the button's label as HTML, red when dangerous, else in its color. */
    private fun buttonLabel(button: Map<String, Any?>, label: String): CharSequence {
        val dangerous = button[Definitions.NOTIFICATION_IS_DANGEROUS_OPTION] as? Boolean ?: false
        val color = (button[Definitions.NOTIFICATION_COLOR] as? Number)?.toInt()
        return HtmlCompat.fromHtml(
            if (dangerous) "<font color=\"16711680\">$label</font>"
            else if (color != null) "<font color=\"$color\">$label</font>"
            else label,
            HtmlCompat.FROM_HTML_MODE_LEGACY
        )
    }

    /** Resolves a button icon from a `resource://type/name` path (0 = no icon). */
    private fun buttonIcon(context: Context, button: Map<String, Any?>): Int {
        val icon = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_ICON]) ?: return 0
        if (!icon.startsWith(MediaSourcePrefix.RESOURCE)) return 0
        val parts = icon.substring(MediaSourcePrefix.RESOURCE.length).split("/")
        if (parts.size < 2) return 0
        return context.resources.getIdentifier(parts[1], parts[0], context.packageName)
    }

    /**
     * The PendingIntent fired when a button is pressed. `Default` (foreground)
     * buttons launch the app; the others broadcast to [NotificationButtonReceiver]
     * without opening it. Both carry the model JSON + the pressed key.
     */
    private fun buttonPendingIntent(
        context: Context,
        id: Int,
        index: Int,
        key: String,
        model: Map<String, Any?>,
        isForeground: Boolean,
        requireInput: Boolean
    ): PendingIntent {
        val action = Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + key
        val requestCode = id * 1000 + index + 1
        return if (isForeground) {
            val launch = context.packageManager
                .getLaunchIntentForPackage(context.packageName) ?: Intent()
            launch.action = action
            launch.putExtra(Definitions.NOTIFICATION_JSON, jsonUtils.toJson(model))
            launch.putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, key)
            launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            PendingIntent.getActivity(context, requestCode, launch, pendingFlags(requireInput))
        } else {
            val intent = Intent(context, NotificationButtonReceiver::class.java).apply {
                this.action = action
                putExtra(Definitions.NOTIFICATION_JSON, jsonUtils.toJson(model))
                putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, key)
            }
            PendingIntent.getBroadcast(context, requestCode, intent, pendingFlags(requireInput))
        }
    }

    /** A button map looked up by its key (null for the content tap / unknown). */
    fun findButton(model: Map<String, Any?>, key: String): Map<String, Any?>? {
        if (key.isEmpty()) return null
        return actionButtons(model).firstOrNull {
            (mapUtils.getString(it[Definitions.NOTIFICATION_BUTTON_KEY]) ?: "") == key
        }
    }

    fun buttonActionType(button: Map<String, Any?>?): ActionType =
        ActionType.from(mapUtils.getString(button?.get(Definitions.NOTIFICATION_ACTION_TYPE)))

    /**
     * Whether a pressed button auto-dismisses its notification. `DismissAction`
     * always dismisses; `KeepOnTop` never; otherwise honor the button's
     * `autoDismissible` flag (default true).
     */
    fun shouldButtonAutoDismiss(button: Map<String, Any?>?): Boolean {
        return when (buttonActionType(button)) {
            ActionType.DismissAction -> true
            ActionType.KeepOnTop -> false
            else ->
                mapUtils.getBool(button?.get(Definitions.NOTIFICATION_AUTO_DISMISSIBLE)) ?: true
        }
    }

    fun notificationId(model: Map<String, Any?>): Int? =
        mapUtils.getInt(contentMap(model)[Definitions.NOTIFICATION_ID])

    @Suppress("UNCHECKED_CAST")
    fun contentMap(model: Map<String, Any?>): Map<String, Any?> =
        (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>) ?: emptyMap()

    // MARK: - Payload injection (tap / dismiss)

    /** Tap intent: launches the app carrying the full model JSON. */
    private fun contentIntent(context: Context, id: Int, model: Map<String, Any?>): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: Intent()
        launch.action = Definitions.SELECT_NOTIFICATION
        launch.putExtra(Definitions.NOTIFICATION_JSON, jsonUtils.toJson(model))
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, id, launch, pendingFlags())
    }

    /** Dismiss intent: fired on swipe-away; DismissedNotificationReceiver emits. */
    private fun deleteIntent(context: Context, id: Int, model: Map<String, Any?>): PendingIntent {
        val intent = Intent(context, DismissedNotificationReceiver::class.java).apply {
            action = Definitions.DISMISSED_NOTIFICATION
            putExtra(Definitions.NOTIFICATION_JSON, jsonUtils.toJson(model))
        }
        return PendingIntent.getBroadcast(context, id, intent, pendingFlags())
    }

    /**
     * Mutable intents are required for RemoteInput (text reply) buttons so the
     * system can write the typed text back; everything else stays immutable.
     */
    private fun pendingFlags(mutable: Boolean = false): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (mutable) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                flags = flags or PendingIntent.FLAG_MUTABLE
            }
            // pre-S: PendingIntents are mutable by default, no flag needed.
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    /** Rebuilds the model map from an intent's NOTIFICATION_JSON extra. */
    fun notificationModel(intent: Intent): Map<String, Any?>? {
        val json = intent.getStringExtra(Definitions.NOTIFICATION_JSON) ?: return null
        return jsonUtils.fromJson(json)
    }

    // MARK: - Event registration (stamps date + lifecycle on the content)

    fun registerCreatedEvent(
        content: Map<String, Any?>,
        lifeCycle: NotificationLifeCycle
    ): Map<String, Any?> =
        // Preserve values already stamped into the content (e.g. a scheduling
        // decorator sets the source to Schedule); only fill what's missing.
        content + mapOf(
            Definitions.NOTIFICATION_CREATED_DATE to
                (content[Definitions.NOTIFICATION_CREATED_DATE] ?: now()),
            Definitions.NOTIFICATION_CREATED_LIFECYCLE to
                (content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] ?: lifeCycle.name),
            Definitions.NOTIFICATION_CREATED_SOURCE to
                (content[Definitions.NOTIFICATION_CREATED_SOURCE] ?: NotificationSource.Local.name)
        )

    fun registerDisplayedEvent(
        content: Map<String, Any?>,
        lifeCycle: NotificationLifeCycle
    ): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_DISPLAYED_DATE to now(),
            Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE to lifeCycle.name
        )

    fun registerActionEvent(
        content: Map<String, Any?>,
        lifeCycle: NotificationLifeCycle,
        actionType: ActionType = ActionType.Default
    ): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_ACTION_DATE to now(),
            Definitions.NOTIFICATION_ACTION_LIFECYCLE to lifeCycle.name,
            Definitions.NOTIFICATION_ACTION_TYPE to actionType.name
        )

    fun registerDismissedEvent(
        content: Map<String, Any?>,
        lifeCycle: NotificationLifeCycle
    ): Map<String, Any?> =
        content + mapOf(
            Definitions.NOTIFICATION_DISMISSED_DATE to now(),
            Definitions.NOTIFICATION_ACTION_LIFECYCLE to lifeCycle.name
        )

    // MARK: - Dismiss concepts

    fun readId(content: Map<String, Any?>): Int? =
        mapUtils.getInt(content[Definitions.NOTIFICATION_ID])

    /** A `DismissAction` tap dismisses + fires the dismiss event. */
    fun isDismissAction(content: Map<String, Any?>): Boolean =
        ActionType.from(mapUtils.getString(content[Definitions.NOTIFICATION_ACTION_TYPE])) ==
            ActionType.DismissAction

    /**
     * Whether tapping the notification auto-dismisses it (Android `setAutoCancel`).
     * DismissAction always dismisses; KeepOnTop never; otherwise honor the
     * `autoDismissible` flag (default true).
     */
    fun shouldAutoDismiss(content: Map<String, Any?>): Boolean {
        return when (
            ActionType.from(mapUtils.getString(content[Definitions.NOTIFICATION_ACTION_TYPE]))
        ) {
            ActionType.DismissAction -> true
            ActionType.KeepOnTop -> false
            else -> mapUtils.getBool(content[Definitions.NOTIFICATION_AUTO_DISMISSIBLE]) ?: true
        }
    }

    private fun now(): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone(Definitions.UTC_TIMEZONE)
        return formatter.format(Date())
    }
}
