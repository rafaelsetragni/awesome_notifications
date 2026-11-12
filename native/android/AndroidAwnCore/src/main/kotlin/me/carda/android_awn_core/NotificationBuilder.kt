package me.carda.android_awn_core

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
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
        val notification = createNotificationContent(context, stamped)
            ?: return BuildOutcome.Invalid
        val id = notificationId(stamped) ?: return BuildOutcome.Invalid
        return BuildOutcome.Post(id, notification, stamped)
    }

    /** Delegates to the wrapped inner builder (called by decorators). */
    fun next(context: Context, model: Map<String, Any?>): BuildOutcome =
        inner?.build(context, model) ?: BuildOutcome.Invalid

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

    /** Builds an Android notification from a serialized model, or null if invalid. */
    fun createNotificationContent(context: Context, model: Map<String, Any?>): Notification? {
        val content = contentMap(model)
        val id = mapUtils.getInt(content[Definitions.NOTIFICATION_ID]) ?: return null
        val channelKey =
            mapUtils.getString(content[Definitions.NOTIFICATION_CHANNEL_KEY]) ?: return null

        val builder = NotificationCompat.Builder(context, channelKey)
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(shouldAutoDismiss(content))
            .setContentIntent(contentIntent(context, id, model))
            .setDeleteIntent(deleteIntent(context, id, model))

        val title = mapUtils.getString(content[Definitions.NOTIFICATION_TITLE])
        if (!stringUtils.isNullOrEmpty(title)) builder.setContentTitle(title)
        val body = mapUtils.getString(content[Definitions.NOTIFICATION_BODY])
        if (!stringUtils.isNullOrEmpty(body)) builder.setContentText(body)

        applyImages(context, content, builder)
        applyActionButtons(context, id, model, builder)

        return builder.build()
    }

    // MARK: - Action buttons

    @Suppress("UNCHECKED_CAST")
    fun actionButtons(model: Map<String, Any?>): List<Map<String, Any?>> =
        (model[Definitions.NOTIFICATION_BUTTONS] as? List<Map<String, Any?>>) ?: emptyList()

    /** Adds an [NotificationCompat.Action] for each serialized action button. */
    private fun applyActionButtons(
        context: Context,
        id: Int,
        model: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        actionButtons(model).forEachIndexed { index, button ->
            val key = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_KEY])
            if (key.isNullOrEmpty()) return@forEachIndexed
            if (mapUtils.getBool(button[Definitions.NOTIFICATION_BUTTON_ENABLED]) == false) {
                return@forEachIndexed
            }

            val label = mapUtils.getString(button[Definitions.NOTIFICATION_BUTTON_LABEL]) ?: key
            val actionType =
                ActionType.from(mapUtils.getString(button[Definitions.NOTIFICATION_ACTION_TYPE]))
            val requireInput =
                mapUtils.getBool(button[Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT]) ?: false
            val isForeground = actionType == ActionType.Default

            val pending = buttonPendingIntent(
                context, id, index, key, model, isForeground, requireInput
            )
            val actionBuilder = NotificationCompat.Action.Builder(
                buttonIcon(context, button), label, pending
            )
            if (requireInput) {
                actionBuilder.addRemoteInput(
                    RemoteInput.Builder(Definitions.NOTIFICATION_BUTTON_KEY_INPUT)
                        .setLabel(label)
                        .build()
                )
            }
            builder.addAction(actionBuilder.build())
        }
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

    /**
     * Applies the large icon and (for the BigPicture layout) the big picture,
     * loading bitmaps from any of the four media sources. Runs I/O — call build()
     * off the main thread.
     */
    private fun applyImages(
        context: Context,
        content: Map<String, Any?>,
        builder: NotificationCompat.Builder
    ) {
        val layout =
            NotificationLayout.from(mapUtils.getString(content[Definitions.NOTIFICATION_LAYOUT]))
        val bigPicturePath = mapUtils.getString(content[Definitions.NOTIFICATION_BIG_PICTURE])
        val largeIconPath = mapUtils.getString(content[Definitions.NOTIFICATION_LARGE_ICON])
        val isBigPicture =
            layout == NotificationLayout.BigPicture && !bigPicturePath.isNullOrEmpty()

        if (isBigPicture) {
            val bigPicture = bitmapUtils.getBitmapFromSource(context, bigPicturePath)
            val largeIcon = if (!largeIconPath.isNullOrEmpty()) {
                bitmapUtils.getBitmapFromSource(context, largeIconPath)
            } else {
                null
            }
            if (largeIcon != null) builder.setLargeIcon(largeIcon)
            if (bigPicture != null) {
                builder.setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(bigPicture)
                        .bigLargeIcon(null as android.graphics.Bitmap?)
                )
            }
        } else if (!largeIconPath.isNullOrEmpty()) {
            bitmapUtils.getBitmapFromSource(context, largeIconPath)
                ?.let { builder.setLargeIcon(it) }
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
