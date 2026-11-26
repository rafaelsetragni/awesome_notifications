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

    /** The matching Android channel importance constant. */
    fun toAndroidImportance(): Int = when (this) {
        None -> android.app.NotificationManager.IMPORTANCE_NONE
        Min -> android.app.NotificationManager.IMPORTANCE_MIN
        Low -> android.app.NotificationManager.IMPORTANCE_LOW
        Default -> android.app.NotificationManager.IMPORTANCE_DEFAULT
        High, Max -> android.app.NotificationManager.IMPORTANCE_HIGH
    }

    companion object {
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
