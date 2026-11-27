package me.carda.android_awn_core

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.util.concurrent.ConcurrentLinkedQueue
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
 *
 * And 0.12 `requestUserPermissions`, the request behind
 * `requestPermissionToSendNotifications`:
 *  - the app's notifications off: Android 13+ shows the system dialog while
 *    it can (no rationale needed yet); once the user denied it (a rationale
 *    is due), or before Android 13, it opens the app's notification settings;
 *  - else, for the missing permissions needing a rationale: one without a
 *    manifest permission (or whose rationale is due) opens its settings page
 *    (the channel's for Alert / Sound / Badge / Light / Vibration /
 *    CriticalAlert, exact alarms, DnD access, else the app's); otherwise the
 *    system dialog asks for the manifest ones;
 *  - it answers the permissions still missing when the dialog answers or the
 *    app comes back to the foreground ([onForeground]), or right away when
 *    nothing was shown.
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

    /** The request code of the system dialog (the plugin routes its result to [onDialogResult]). */
    const val REQUEST_CODE = 101

    private const val TAG = "PermissionManager"

    /** What answers once the user is back from a dialog or a settings page. */
    private val waiting = ConcurrentLinkedQueue<() -> Unit>()

    /** 0.12 `requestUserPermissions`: [completion] receives the permissions still missing. */
    fun requestUserPermissions(
        activity: Activity?,
        context: Context,
        channelKey: String?,
        permissions: List<String>,
        completion: (List<String>) -> Unit
    ) {
        if (permissions.isNotEmpty()) {
            if (!areNotificationsGloballyAllowed(context)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && activity != null) {
                    val code = Manifest.permission.POST_NOTIFICATIONS
                    if (!activity.shouldShowRequestPermissionRationale(code)) {
                        showDialog(activity, context, channelKey, permissions, listOf(code), completion)
                        return
                    }
                }
                showRationalePage(context, channelKey, null, permissions, completion)
                return
            }

            val requested = ArrayList(permissions)
            requested.removeAll(arePermissionsAllowed(context, channelKey, ArrayList(requested)).toSet())
            val needingRationale = shouldShowRationale(context, channelKey, ArrayList(requested))

            val manifestPermissions = ArrayList<String>()
            for (needed in needingRationale) {
                val permission = NotificationPermission.fromName(needed)
                val code = requestCode(permission)
                if (code == null || activity != null && activity.shouldShowRequestPermissionRationale(code)) {
                    showRationalePage(context, channelKey, permission, requested, completion)
                    return
                }
                manifestPermissions.add(code)
            }

            if (activity != null && manifestPermissions.isNotEmpty()) {
                showDialog(activity, context, channelKey, requested, manifestPermissions, completion)
                return
            }
        }
        refreshReturnedPermissions(context, channelKey, ArrayList(permissions), completion)
    }

    /** The system dialog answered (0.12 `handlePermissionResult`). */
    fun onDialogResult(requestCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        fireWaiting()
        return true
    }

    /** The app is back in the foreground (0.12 answered the requests there too). */
    fun onForeground() = fireWaiting()

    private fun fireWaiting() {
        while (true) {
            val next = waiting.poll() ?: return
            next()
        }
    }

    private fun showDialog(
        activity: Activity,
        context: Context,
        channelKey: String?,
        permissions: List<String>,
        manifestPermissions: List<String>,
        completion: (List<String>) -> Unit
    ) {
        activity.requestPermissions(manifestPermissions.toTypedArray(), REQUEST_CODE)
        waiting.add { refreshReturnedPermissions(context, channelKey, ArrayList(permissions), completion) }
    }

    private fun showRationalePage(
        context: Context,
        channelKey: String?,
        permission: NotificationPermission?,
        permissions: List<String>,
        completion: (List<String>) -> Unit
    ) {
        val shown = when (permission) {
            null -> openAppNotificationPage(context)
            NotificationPermission.PreciseAlarms -> openPreciseAlarmPage(context)
            NotificationPermission.OverrideDnD -> openDnDAccessPage(context)
            NotificationPermission.Badge, NotificationPermission.Alert, NotificationPermission.Sound,
            NotificationPermission.Light, NotificationPermission.Vibration,
            NotificationPermission.CriticalAlert -> openChannelPage(context, channelKey)
            else -> openAppNotificationPage(context)
        }
        if (shown) {
            waiting.add { refreshReturnedPermissions(context, channelKey, ArrayList(permissions), completion) }
        } else {
            refreshReturnedPermissions(context, channelKey, ArrayList(permissions), completion)
        }
    }

    /** 0.12 `refreshReturnedPermissions`: the permissions still missing (all of them if the check fails). */
    private fun refreshReturnedPermissions(
        context: Context,
        channelKey: String?,
        permissions: MutableList<String>,
        completion: (List<String>) -> Unit
    ) {
        try {
            if (permissions.isNotEmpty()) {
                if (!channelKey.isNullOrEmpty()) {
                    updateChannelThroughPermissions(context, channelKey, permissions)
                }
                permissions.removeAll(arePermissionsAllowed(context, channelKey, ArrayList(permissions)).toSet())
            }
        } catch (e: AwesomeNotificationsException) {
            Log.e(TAG, e.message ?: "", e)
        }
        completion(permissions)
    }

    /**
     * 0.12 `updateChannelModelThroughPermissions`: Android 7 keeps the
     * channel's settings in its own model; they follow what is allowed now.
     */
    private fun updateChannelThroughPermissions(context: Context, channelKey: String, permissions: List<String>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) return
        val channel = ChannelManager.getChannel(channelKey)?.toMutableMap() ?: return
        for (name in permissions) {
            val permission = NotificationPermission.fromName(name) ?: continue
            val allowed = isSpecifiedPermissionGloballyAllowed(context, permission)
            when (permission) {
                NotificationPermission.Alert -> {
                    val importance = ChannelManager.importance(channel)
                    if (allowed && importance.ordinal < NotificationImportance.High.ordinal) {
                        channel[Definitions.NOTIFICATION_IMPORTANCE] = NotificationImportance.High.name
                    } else if (!allowed && importance.ordinal >= NotificationImportance.High.ordinal) {
                        channel[Definitions.NOTIFICATION_IMPORTANCE] = NotificationImportance.Default.name
                    }
                }
                NotificationPermission.Sound -> channel[Definitions.NOTIFICATION_PLAY_SOUND] = allowed
                NotificationPermission.Badge -> channel[Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE] = allowed
                NotificationPermission.Vibration -> channel[Definitions.NOTIFICATION_ENABLE_VIBRATION] = allowed
                NotificationPermission.Light -> channel[Definitions.NOTIFICATION_ENABLE_LIGHTS] = allowed
                NotificationPermission.CriticalAlert -> channel[Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS] = allowed
                else -> {}
            }
        }
        ChannelManager.setChannel(context, channel)
    }

    /** 0.12 `getManifestPermissionCode`, with null (an unknown name) as the notifications permission. */
    private fun requestCode(permission: NotificationPermission?): String? =
        if (permission == null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Manifest.permission.POST_NOTIFICATIONS else null
        } else {
            manifestPermissionCode(permission)
        }

    private fun openAppNotificationPage(context: Context): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        } else {
            Intent("android.settings.APP_NOTIFICATION_SETTINGS")
                .putExtra("app_package", context.packageName)
                .putExtra("app_uid", context.applicationInfo.uid)
        }
        return startVerified(context, intent)
    }

    private fun openChannelPage(context: Context, channelKey: String?): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            val channel = ChannelManager.getAndroidChannel(context, channelKey)
            when {
                channel != null -> intent.putExtra(Settings.EXTRA_CHANNEL_ID, channel.id)
                !channelKey.isNullOrEmpty() -> intent.putExtra(Settings.EXTRA_CHANNEL_ID, channelKey)
            }
            if (startVerified(context, intent)) return true
        }
        return openAppNotificationPage(context)
    }

    private fun openPreciseAlarmPage(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                .setData(Uri.parse("package:" + context.packageName))
            if (startVerified(context, intent)) return true
        }
        return openAppNotificationPage(context)
    }

    private fun openDnDAccessPage(context: Context): Boolean {
        if (startVerified(context, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))) return true
        return openAppNotificationPage(context)
    }

    /** 0.12 `startVerifiedActivity`: false when nothing opens the page. */
    private fun startVerified(context: Context, intent: Intent): Boolean {
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        if (intent.resolveActivity(context.packageManager) == null) {
            Log.e(TAG, "Activity permission action '${intent.action}' not found!")
            return false
        }
        context.startActivity(intent)
        return true
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
