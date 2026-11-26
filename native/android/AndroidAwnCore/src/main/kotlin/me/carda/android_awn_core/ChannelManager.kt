package me.carda.android_awn_core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import java.util.concurrent.ConcurrentHashMap

/**
 * The channels the app set (process-wide, so the builder reads the same channel
 * the engine created) and the Android channel creation of 0.12
 * `ChannelManager.setAndroidChannel`, for the parts 1.0 ports:
 *  - sound: `playSound` (default true) plays `soundSource` (a
 *    `resource://raw/name`, `res_name` first) or, without one, the system's
 *    default sound of the channel's `defaultRingtoneType` (Notification,
 *    Alarm or Ringtone; default Notification), with the
 *    `CONTENT_TYPE_SONIFICATION` / `USAGE_NOTIFICATION` attributes;
 *    `playSound: false` is a silent channel;
 *  - vibration (default on) with its pattern, lights (default on) with the
 *    LED color, and the badge (default off);
 *  - critical alerts (0.12.1): `criticalAlerts: true` makes the channel
 *    bypass Do Not Disturb (`setBypassDnd`). Channel-only: nothing touches
 *    the device's interruption filter or notification policy.
 */
object ChannelManager {

    private val channels = ConcurrentHashMap<String, Map<String, Any?>>()

    /** The channel data the app set for [channelKey], if any. */
    fun getChannel(channelKey: String?): Map<String, Any?>? =
        channelKey?.let { channels[it] }

    /** Keeps the channel data and creates its Android channel (Android 8+). */
    fun setChannel(context: Context, channelData: Map<String, Any?>) {
        val key = channelData[Definitions.NOTIFICATION_CHANNEL_KEY] as? String ?: return
        channels[key] = channelData
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createAndroidChannel(context, key, channelData)
        }
    }

    private fun createAndroidChannel(context: Context, key: String, channelData: Map<String, Any?>) {
        val name = channelData[Definitions.NOTIFICATION_CHANNEL_NAME] as? String ?: key
        val importance = NotificationImportance
            .from(channelData[Definitions.NOTIFICATION_IMPORTANCE] as? String)
            .toAndroidImportance()
        val channel = NotificationChannel(key, name, importance)
        (channelData[Definitions.NOTIFICATION_CHANNEL_DESCRIPTION] as? String)?.let {
            channel.description = it
        }

        if (playSound(channelData)) {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()
            channel.setSound(
                retrieveSoundResourceUri(
                    context,
                    defaultRingtoneType(channelData),
                    channelData[Definitions.NOTIFICATION_SOUND_SOURCE] as? String
                ),
                audioAttributes
            )
        } else {
            channel.setSound(null, null)
        }

        channel.enableVibration(enableVibration(channelData))
        vibrationPattern(channelData)?.takeIf { it.isNotEmpty() }?.let { channel.vibrationPattern = it }

        val enableLights = enableLights(channelData)
        channel.enableLights(enableLights)
        if (enableLights) ledColor(channelData)?.let { channel.lightColor = it }

        if (criticalAlerts(channelData)) channel.setBypassDnd(true)

        channel.setShowBadge(showBadge(channelData))

        notificationManager(context).createNotificationChannel(channel)
    }

    // MARK: - Channel fields (0.12 NotificationChannelModel.fromMap defaults)

    /** 0.12: only a Boolean counts; default true. */
    fun playSound(channelData: Map<String, Any?>?): Boolean =
        channelData?.get(Definitions.NOTIFICATION_PLAY_SOUND) as? Boolean ?: true

    fun defaultRingtoneType(channelData: Map<String, Any?>?): DefaultRingtoneType =
        DefaultRingtoneType.from(channelData?.get(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE))

    /** 0.12: only a Boolean counts; default true. */
    fun enableVibration(channelData: Map<String, Any?>?): Boolean =
        channelData?.get(Definitions.NOTIFICATION_ENABLE_VIBRATION) as? Boolean ?: true

    /** 0.12: only a Boolean counts; default true. */
    fun enableLights(channelData: Map<String, Any?>?): Boolean =
        channelData?.get(Definitions.NOTIFICATION_ENABLE_LIGHTS) as? Boolean ?: true

    /** 0.12: only a Boolean counts; default false. */
    fun showBadge(channelData: Map<String, Any?>?): Boolean =
        channelData?.get(Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE) as? Boolean ?: false

    /** Dart's `Int64List` arrives as a LongArray (a list from JSON). */
    fun vibrationPattern(channelData: Map<String, Any?>?): LongArray? =
        when (val value = channelData?.get(Definitions.NOTIFICATION_VIBRATION_PATTERN)) {
            is LongArray -> value
            is IntArray -> value.map { it.toLong() }.toLongArray()
            is List<*> -> value.mapNotNull { (it as? Number)?.toLong() }.toLongArray()
            else -> null
        }

    /** 0.12 default: white. An ARGB above Int.MAX_VALUE arrives as a Long. */
    fun ledColor(channelData: Map<String, Any?>?): Int? =
        when (val value = channelData?.get(Definitions.NOTIFICATION_LED_COLOR)) {
            null -> 0xFFFFFFFF.toInt()
            is Number -> value.toInt()
            else -> null
        }

    /** 0.12: only a Boolean counts; default false. */
    fun criticalAlerts(channelData: Map<String, Any?>?): Boolean =
        channelData?.get(Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS) as? Boolean ?: false

    /** 0.12: only a Boolean counts; default false. */
    fun locked(channelData: Map<String, Any?>?): Boolean =
        channelData?.get(Definitions.NOTIFICATION_LOCKED) as? Boolean ?: false

    // MARK: - Sound

    /**
     * 0.12 `retrieveSoundResourceUri`: without a [soundSource], the system's
     * default sound of [ringtoneType]; with one, the raw resource it names
     * (`android.resource://<package>/<id>`), or null when it does not exist.
     */
    fun retrieveSoundResourceUri(
        context: Context,
        ringtoneType: DefaultRingtoneType,
        soundSource: String?
    ): Uri? {
        if (soundSource.isNullOrEmpty()) {
            return RingtoneManager.getDefaultUri(ringtoneType.toRingtoneManagerType())
        }
        val resourceId = audioResourceId(context, soundSource)
        return if (resourceId > 0) Uri.parse("android.resource://${context.packageName}/$resourceId")
        else null
    }

    /**
     * 0.12 `AudioUtils.getAudioResourceId`: `resource://type/name` looks up
     * `res_name` first (kept from obfuscation), then `name`. Anything else is 0.
     */
    private fun audioResourceId(context: Context, reference: String): Int {
        val lower = reference.lowercase()
        if (!lower.startsWith(MediaSourcePrefix.RESOURCE)) return 0
        val parts = reference.substring(MediaSourcePrefix.RESOURCE.length).split("/")
        if (parts.size < 2) return 0
        return try {
            val (type, label) = parts
            var id = context.resources.getIdentifier("res_$label", type, context.packageName)
            if (id == 0) id = context.resources.getIdentifier(label, type, context.packageName)
            id
        } catch (_: Exception) {
            0
        }
    }

    // MARK: - Android channel lookup

    /**
     * 0.12 `getAndroidChannel(context, channelKey)`: the channel with that id,
     * or else one whose id starts with `"<channelKey>_"` (a force-updated
     * channel of 0.12).
     */
    fun getAndroidChannel(context: Context, channelKey: String?): NotificationChannel? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val manager = notificationManager(context)
        if (channelKey != null) manager.getNotificationChannel(channelKey)?.let { return it }
        return manager.notificationChannels.firstOrNull { it.id.startsWith(channelKey + "_") }
    }

    private fun notificationManager(context: Context): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** Forgets the channels set so far (tests). */
    internal fun clearForTest() = channels.clear()
}
