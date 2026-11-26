package me.carda.android_awn_core

/**
 * Origin of a notification. The enum name is the exact string the Dart
 * `NotificationSource` enum (de)serializes, so it is the single source of truth
 * shared across the channel — no magic strings at the call sites.
 */
enum class NotificationSource { Local, Schedule, Firebase, OneSignal, CallKit }

/**
 * App lifecycle state when a notification event happened. The name matches the
 * Dart `NotificationLifeCycle` enum exactly (note: `Terminated`, not the
 * deprecated `AppKilled`, which the Dart side no longer parses).
 */
enum class NotificationLifeCycle { Foreground, Background, Terminated }

/**
 * Type of a notification action button / content tap. The enum name matches the
 * Dart `ActionType` enum exactly (the wire format is the enum `.name`).
 */
enum class ActionType {
    Default, InputField, DisabledAction, KeepOnTop,
    SilentAction, SilentBackgroundAction, DismissAction;

    companion object {
        /**
         * Parses the wire value, tolerating a legacy "ActionType."-prefixed form;
         * an unknown/null/empty value falls back to [Default].
         */
        fun from(raw: String?): ActionType {
            if (raw.isNullOrEmpty()) return Default
            val name = raw.substringAfterLast('.')
            return values().firstOrNull { it.name == name } ?: Default
        }
    }
}

/**
 * Scheme prefixes that identify a media reference's source, matching the Dart
 * `MediaSourcePrefix` constants. Single source of truth for scheme handling.
 */
object MediaSourcePrefix {
    const val RESOURCE = "resource://"
    const val ASSET = "asset://"
    const val FILE = "file://"
    const val NETWORK_HTTPS = "https://"
    const val NETWORK_HTTP = "http://"
    /** Loose prefix used to keep any http(s) URL whole. */
    const val HTTP = "http"
}

/**
 * Notification importance, mirroring the Dart `NotificationImportance` enum, plus
 * the mapping to Android's `NotificationManager.IMPORTANCE_*`.
 */
enum class NotificationImportance {
    None, Min, Low, Default, High, Max;

    /**
     * 0.12 `toAndroidImportance`: the ordinal, which is Android's
     * `IMPORTANCE_*` (None 0 … High 4), so `Max` is `IMPORTANCE_MAX` (5).
     */
    fun toAndroidImportance(): Int = ordinal

    /** 0.12 `toAndroidPriority`: the pre-Android 8 priority of a notification. */
    fun toAndroidPriority(): Int = when (this) {
        None, Min -> androidx.core.app.NotificationCompat.PRIORITY_MIN
        Low -> androidx.core.app.NotificationCompat.PRIORITY_LOW
        High -> androidx.core.app.NotificationCompat.PRIORITY_HIGH
        Max -> androidx.core.app.NotificationCompat.PRIORITY_MAX
        Default -> androidx.core.app.NotificationCompat.PRIORITY_DEFAULT
    }

    companion object {
        /** 0.12 `fromAndroidImportance`: the ordinal, clamped to 0…5. */
        fun fromAndroidImportance(importance: Int): NotificationImportance =
            values()[importance.coerceIn(0, 5)]

        /** Parses the wire value (tolerating an "Enum."-prefixed form); default [Default]. */
        fun from(raw: String?): NotificationImportance {
            if (raw.isNullOrEmpty()) return Default
            val name = raw.substringAfterLast('.')
            return values().firstOrNull { it.name.equals(name, ignoreCase = true) } ?: Default
        }
    }
}

/**
 * Notification layout, mirroring the Dart `NotificationLayout` enum. The name is
 * the exact wire value (`.name`).
 */
enum class NotificationLayout {
    Default, BigPicture, BigText, Inbox, ProgressBar, Messaging, MessagingGroup, MediaPlayer;

    companion object {
        fun from(raw: String?): NotificationLayout {
            if (raw.isNullOrEmpty()) return Default
            val name = raw.substringAfterLast('.')
            return values().firstOrNull { it.name == name } ?: Default
        }
    }
}

/**
 * 0.12 `SafeEnum.charMatches`: whether the char at [pos] of [text], lowercased,
 * is [match]. The 0.12 enums parse by these chars only, not the whole name.
 */
internal fun safeCharMatches(text: String, pos: Int, match: Char): Boolean =
    text.length > pos && text[pos].lowercaseChar() == match

/**
 * Notification category, mirroring the Dart `NotificationCategory` enum, with
 * the raw value 0.12 gave Android (`builder.setCategory(rawValue)`).
 */
enum class NotificationCategory(val rawValue: String) {
    Alarm("alarm"),
    Call("call"),
    Email("email"),
    Error("err"),
    Event("event"),
    LocalSharing("location_sharing"),
    Message("msg"),
    MissedCall("missed_call"),
    Navigation("navigation"),
    Progress("progress"),
    Promo("promo"),
    Recommendation("recommendation"),
    Reminder("reminder"),
    Service("service"),
    Social("social"),
    Status("status"),
    StopWatch("stopwatch"),
    Transport("transport"),
    Workout("workout");

    companion object {
        /**
         * 0.12 `NotificationCategory.getSafeEnum`, quirks included: it reads a
         * few chars of the value only (so any text starting with `c` is
         * `Call`); null / empty / no match is null. A value that is not a
         * String is null (0.12 `getValueOrDefault`).
         */
        fun from(raw: Any?): NotificationCategory? {
            val r = raw as? String ?: return null
            if (r.isEmpty()) return null
            return when {
                safeCharMatches(r, 0, 'a') -> Alarm
                safeCharMatches(r, 0, 'c') -> Call
                safeCharMatches(r, 0, 'm') ->
                    if (safeCharMatches(r, 1, 'e')) Message else MissedCall
                safeCharMatches(r, 0, 'r') ->
                    if (safeCharMatches(r, 2, 'c')) Recommendation else Reminder
                safeCharMatches(r, 0, 'l') -> LocalSharing
                safeCharMatches(r, 0, 'n') -> Navigation
                safeCharMatches(r, 0, 'p') ->
                    if (safeCharMatches(r, 3, 'g')) Progress else Promo
                safeCharMatches(r, 0, 'e') -> when {
                    safeCharMatches(r, 1, 'm') -> Email
                    safeCharMatches(r, 1, 'r') -> Error
                    else -> Event
                }
                safeCharMatches(r, 0, 's') -> when {
                    safeCharMatches(r, 1, 'e') -> Service
                    safeCharMatches(r, 1, 'o') -> Social
                    safeCharMatches(r, 2, 'a') -> Status
                    else -> StopWatch
                }
                safeCharMatches(r, 0, 'w') -> Workout
                safeCharMatches(r, 0, 't') -> Transport
                else -> null
            }
        }
    }
}

/**
 * The system sound a channel plays when it has no `soundSource` (0.12
 * `DefaultRingtoneType`), with its `RingtoneManager.TYPE_*`.
 */
enum class DefaultRingtoneType {
    Ringtone, Notification, Alarm;

    fun toRingtoneManagerType(): Int = when (this) {
        Ringtone -> android.media.RingtoneManager.TYPE_RINGTONE
        Alarm -> android.media.RingtoneManager.TYPE_ALARM
        Notification -> android.media.RingtoneManager.TYPE_NOTIFICATION
    }

    companion object {
        /**
         * 0.12 `NotificationChannelModel.fromMap`: absent (or not a String) is
         * `Notification`; otherwise 0.12 `getSafeEnum` reads the first char
         * only (`n` / `r` / `a`). An unknown text was null in 0.12 and made the
         * channel creation throw; here it falls back to `Notification`.
         */
        fun from(raw: Any?): DefaultRingtoneType {
            val r = raw as? String ?: return Notification
            return when {
                safeCharMatches(r, 0, 'n') -> Notification
                safeCharMatches(r, 0, 'r') -> Ringtone
                safeCharMatches(r, 0, 'a') -> Alarm
                else -> Notification
            }
        }
    }
}

/**
 * A notification permission, mirroring the Dart `NotificationPermission` enum
 * (the name is the wire value).
 */
enum class NotificationPermission {
    Alert, Sound, Badge, Vibration, Light, CriticalAlert, OverrideDnD,
    Provisional, PreciseAlarms, FullScreenIntent, Car;

    companion object {
        /**
         * 0.12 `StringUtils.getEnumFromString`: the exact (trimmed) name, or
         * null. Used to decide what is allowed.
         */
        fun fromName(raw: String?): NotificationPermission? {
            val name = raw?.trim() ?: return null
            return values().firstOrNull { it.name == name }
        }

        /**
         * 0.12 `NotificationPermission.getSafeEnum`, quirks included: it reads
         * a few chars only. Used by `getPermissionStatuses` to spot the
         * permissions Android does not support.
         */
        fun fromSafeName(raw: String?): NotificationPermission? {
            if (raw.isNullOrEmpty()) return null
            return when {
                safeCharMatches(raw, 0, 'a') -> Alert
                safeCharMatches(raw, 0, 's') -> Sound
                safeCharMatches(raw, 0, 'b') -> Badge
                safeCharMatches(raw, 0, 'v') -> Vibration
                safeCharMatches(raw, 0, 'p') ->
                    if (safeCharMatches(raw, 2, 'e')) PreciseAlarms else Provisional
                safeCharMatches(raw, 0, 'o') -> OverrideDnD
                safeCharMatches(raw, 0, 'c') ->
                    if (safeCharMatches(raw, 1, 'r')) CriticalAlert else Car
                safeCharMatches(raw, 0, 'l') -> Light
                safeCharMatches(raw, 0, 'f') -> FullScreenIntent
                else -> null
            }
        }
    }
}

/** The status `getPermissionStatuses` answers per permission (the wire value is the name). */
enum class NotificationPermissionStatus { granted, denied, notDetermined, notSupported }

/**
 * 0.12 `NotificationPrivacy`, the lock screen visibility of a notification,
 * with its `toAndroidPrivacy`.
 */
enum class NotificationPrivacy {
    Secret, Private, Public;

    companion object {
        /**
         * 0.12 `getSafeEnum`, quirks included: `s…` is Secret, then a second
         * char `u` is Public and `r` is Private; null / empty / no match is
         * null.
         */
        fun fromSafeName(raw: String?): NotificationPrivacy? {
            if (raw.isNullOrEmpty()) return null
            return when {
                safeCharMatches(raw, 0, 's') -> Secret
                safeCharMatches(raw, 1, 'u') -> Public
                safeCharMatches(raw, 1, 'r') -> Private
                else -> null
            }
        }

        /**
         * 0.12 `getValueOrDefault`: absent is [default]; a String is parsed
         * (null when it matches nothing); any other value is [default].
         */
        fun fromMapValue(raw: Any?, default: NotificationPrivacy?): NotificationPrivacy? = when (raw) {
            null -> default
            is String -> fromSafeName(raw)
            else -> default
        }

        /** 0.12 `toAndroidPrivacy`: null is Private. */
        fun toAndroidPrivacy(privacy: NotificationPrivacy?): Int = when (privacy ?: Private) {
            Secret -> android.app.Notification.VISIBILITY_SECRET
            Public -> android.app.Notification.VISIBILITY_PUBLIC
            Private -> android.app.Notification.VISIBILITY_PRIVATE
        }
    }
}

/** 0.12 `GroupSort`: how a channel's grouped notifications are ordered. */
enum class GroupSort {
    Asc, Desc;

    companion object {
        /**
         * 0.12 `fromMap` + `getSafeEnum`: absent (or not a String) is Desc;
         * `a…` is Asc, `d…` Desc, anything else null (which 0.12 then
         * treated as "not Asc").
         */
        fun from(raw: Any?): GroupSort? {
            val r = raw as? String ?: return Desc
            return when {
                safeCharMatches(r, 0, 'a') -> Asc
                safeCharMatches(r, 0, 'd') -> Desc
                else -> null
            }
        }
    }
}

/**
 * 0.12 `GroupAlertBehaviour`: which notifications of a group alert. The
 * ordinal is `NotificationCompat.GROUP_ALERT_*` (All 0, Summary 1, Children 2).
 */
enum class GroupAlertBehaviour {
    All, Summary, Children;

    companion object {
        /**
         * 0.12 `fromMap` + `getSafeEnum`: absent (or not a String) is All;
         * `c…` Children, `a…` All, `s…` Summary. An unknown text was null in
         * 0.12 and made the build throw; here it falls back to All.
         */
        fun from(raw: Any?): GroupAlertBehaviour {
            val r = raw as? String ?: return All
            return when {
                safeCharMatches(r, 0, 'c') -> Children
                safeCharMatches(r, 0, 'a') -> All
                safeCharMatches(r, 0, 's') -> Summary
                else -> All
            }
        }
    }
}
