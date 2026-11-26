package me.carda.android_awn_core

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * The permission checks of 0.12 `PermissionManager` (`arePermissionsAllowed`,
 * `shouldShowRationale` and what they read) and the 0.12.1 plugin's
 * `getPermissionStatuses` built on them, ported as they were, quirks included:
 *  - Provisional and Car (spotted by 0.12 `getSafeEnum`, which reads the first
 *    chars only) are `notSupported`;
 *  - an allowed permission is `granted`; one 0.12 would show a rationale for
 *    is `notDetermined`; the rest is `denied`;
 *  - with the app's notifications off, nothing is allowed and every permission
 *    "needs a rationale": all are `notDetermined` (not `denied`);
 *  - Android 8+: FullScreenIntent never needs a rationale, so a missing one is
 *    `denied`; every other missing permission (an unknown name too) is
 *    `notDetermined`. Android 7: only Sound / CriticalAlert / OverrideDnD can
 *    be `notDetermined`, against the app-wide checks;
 *  - a [channelKey] that has no Android channel (Android 8+) or no channel set
 *    (Android 7) throws `INVALID_ARGUMENTS` "Channel <key> does not exist."
 *    (`arguments.invalid.channel.key`).
 */
object PermissionManager {

    private val olderAndroidRationale = listOf(
        NotificationPermission.Sound.name,
        NotificationPermission.CriticalAlert.name,
        NotificationPermission.OverrideDnD.name
    )

    private val newerAndroidNoRationale = listOf(
        NotificationPermission.FullScreenIntent.name,
        NotificationPermission.Provisional.name
    )

    /** 0.12.1 plugin `channelMethodGetPermissionStatuses`. */
    fun getPermissionStatuses(
        context: Context,
        channelKey: String?,
        permissions: List<String>
    ): Map<String, String> {
        val allowed = arePermissionsAllowed(context, channelKey, ArrayList(permissions))
        val rationale = shouldShowRationale(context, channelKey, ArrayList(permissions))

        val statuses = HashMap<String, String>()
        for (permission in permissions) {
            val safe = NotificationPermission.fromSafeName(permission)
            statuses[permission] = when {
                safe == NotificationPermission.Provisional ||
                    safe == NotificationPermission.Car -> NotificationPermissionStatus.notSupported
                allowed.contains(permission) -> NotificationPermissionStatus.granted
                rationale.contains(permission) -> NotificationPermissionStatus.notDetermined
                else -> NotificationPermissionStatus.denied
            }.name
        }
        return statuses
    }

    fun areNotificationsGloballyAllowed(context: Context): Boolean =
        NotificationManagerCompat.from(context).areNotificationsEnabled()

    /** 0.12 `arePermissionsAllowed`: the [permissions] allowed (app-wide, and on [channelKey]). */
    fun arePermissionsAllowed(
        context: Context,
        channelKey: String?,
        permissions: List<String>
    ): List<String> {
        val allowed = ArrayList<String>()
        if (!areNotificationsGloballyAllowed(context)) return allowed
        for (permission in permissions) {
            val permissionEnum = NotificationPermission.fromName(permission) ?: continue
            if (isSpecifiedPermissionGloballyAllowed(context, permissionEnum) &&
                (channelKey == null ||
                    isSpecifiedChannelPermissionAllowed(context, channelKey, permissionEnum))
            ) {
                allowed.add(permission)
            }
        }
        return allowed
    }

    /** 0.12 `shouldShowRationale`. */
    fun shouldShowRationale(
        context: Context,
        channelKey: String?,
        permissions: MutableList<String>
    ): List<String> {
        if (!areNotificationsGloballyAllowed(context)) return permissions

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            permissions.removeAll(newerAndroidNoRationale)
            val allowed = arePermissionsAllowed(context, channelKey, permissions)
            permissions.removeAll(allowed)
            permissions
        } else {
            val needing = olderAndroidRationale.filter { permissions.contains(it) }.toMutableList()
            val allowed = arePermissionsAllowed(context, null, needing)
            needing.removeAll(allowed)
            needing
        }
    }

    /** 0.12 `isSpecifiedPermissionGloballyAllowed`. */
    fun isSpecifiedPermissionGloballyAllowed(
        context: Context,
        permission: NotificationPermission
    ): Boolean {
        when (permission) {
            NotificationPermission.PreciseAlarms -> return isPreciseAlarmGloballyAllowed(context)
            NotificationPermission.CriticalAlert -> return isCriticalAlertsGloballyAllowed(context)
            NotificationPermission.Badge -> return isBadgeGloballyAllowed(context)
            NotificationPermission.OverrideDnD -> return isDndOverrideAllowed(context)
            NotificationPermission.Sound ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    return isNotificationSoundGloballyAllowed(context)
                }
            else -> {}
        }
        val code = manifestPermissionCode(permission) ?: return true
        return ContextCompat.checkSelfPermission(context, code) == PackageManager.PERMISSION_GRANTED
    }

    /** 0.12 `isSpecifiedChannelPermissionAllowed`. */
    fun isSpecifiedChannelPermissionAllowed(
        context: Context,
        channelKey: String,
        permission: NotificationPermission
    ): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = ChannelManager.getAndroidChannel(context, channelKey)
                ?: throw channelNotFound(channelKey)
            if (channel.importance == NotificationManager.IMPORTANCE_NONE) return false
            return when (permission) {
                NotificationPermission.Alert ->
                    channel.importance >= NotificationManager.IMPORTANCE_HIGH
                NotificationPermission.Sound ->
                    channel.importance >= NotificationManager.IMPORTANCE_DEFAULT && channel.sound != null
                NotificationPermission.Vibration ->
                    channel.importance >= NotificationManager.IMPORTANCE_DEFAULT && channel.shouldVibrate()
                NotificationPermission.Light -> channel.shouldShowLights()
                NotificationPermission.Badge -> channel.canShowBadge()
                NotificationPermission.CriticalAlert -> channel.canBypassDnd()
                else -> true
            }
        }

        // Android 7: the channel as the app set it (0.12 channel model defaults).
        val channel = ChannelManager.getChannel(channelKey) ?: throw channelNotFound(channelKey)
        val importance = (channel[Definitions.NOTIFICATION_IMPORTANCE] as? String)
            ?.let { NotificationImportance.from(it) } ?: NotificationImportance.Default
        if (importance == NotificationImportance.None) return false
        return when (permission) {
            NotificationPermission.Alert -> importance.ordinal >= NotificationImportance.High.ordinal
            NotificationPermission.Sound ->
                importance.ordinal >= NotificationImportance.Default.ordinal &&
                    ChannelManager.playSound(channel)
            NotificationPermission.Vibration ->
                importance.ordinal >= NotificationImportance.Default.ordinal &&
                    (channel[KEY_ENABLE_VIBRATION] as? Boolean ?: true)
            NotificationPermission.Light -> channel[KEY_ENABLE_LIGHTS] as? Boolean ?: true
            NotificationPermission.Badge -> channel[KEY_SHOW_BADGE] as? Boolean ?: false
            NotificationPermission.CriticalAlert -> ChannelManager.criticalAlerts(channel)
            else -> true
        }
    }

    private const val KEY_ENABLE_VIBRATION = "enableVibration"
    private const val KEY_ENABLE_LIGHTS = "enableLights"
    private const val KEY_SHOW_BADGE = "channelShowBadge"

    private fun channelNotFound(channelKey: String) = AwesomeNotificationsException(
        Definitions.CODE_INVALID_ARGUMENTS,
        "Channel $channelKey does not exist.",
        Definitions.DETAILED_INVALID_ARGUMENTS + ".channel.key"
    )

    private fun isNotificationSoundGloballyAllowed(context: Context): Boolean {
        val importance = notificationManager(context).importance
        return importance < 0 || importance >= NotificationManager.IMPORTANCE_DEFAULT
    }

    /** 0.12: critical alerts count as allowed unless the device's DnD silences everything. */
    private fun isCriticalAlertsGloballyAllowed(context: Context): Boolean =
        notificationManager(context).currentInterruptionFilter !=
            NotificationManager.INTERRUPTION_FILTER_NONE

    private fun isDndOverrideAllowed(context: Context): Boolean =
        notificationManager(context).isNotificationPolicyAccessGranted

    /** 0.12 `ScheduleManager.isPreciseAlarmGloballyAllowed`. */
    private fun isPreciseAlarmGloballyAllowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            return alarmManager.canScheduleExactAlarms()
        }
        return true
    }

    /** 0.12 `BadgeManager.isBadgeGloballyAllowed`: the device's badge setting (absent = on). */
    private fun isBadgeGloballyAllowed(context: Context): Boolean = try {
        Settings.Secure.getInt(context.contentResolver, "notification_badging") == 1
    } catch (_: Settings.SettingNotFoundException) {
        true
    }

    /** 0.12 `getManifestPermissionCode`. */
    private fun manifestPermissionCode(permission: NotificationPermission): String? =
        when (permission) {
            NotificationPermission.FullScreenIntent ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                    Manifest.permission.USE_FULL_SCREEN_INTENT
                else null
            NotificationPermission.PreciseAlarms ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                    Manifest.permission.SCHEDULE_EXACT_ALARM
                else null
            else -> null
        }

    private fun notificationManager(context: Context): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
}
