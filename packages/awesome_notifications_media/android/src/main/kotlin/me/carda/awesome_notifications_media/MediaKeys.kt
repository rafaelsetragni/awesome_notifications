package me.carda.awesome_notifications_media

/** Keys of the `media` block and channel names (same names as the Dart `MediaKeys`). */
internal object MediaKeys {
    const val MEDIA = "media"

    const val SESSION_ID = "sessionId"
    const val TITLE = "title"
    const val ARTIST = "artist"
    const val ALBUM = "album"
    const val ARTWORK = "artwork"
    const val DURATION = "duration"
    const val POSITION = "position"
    const val PLAYBACK_SPEED = "playbackSpeed"
    const val STATE = "state"
    const val CONTROLS = "controls"
    const val SKIP_INTERVAL = "skipInterval"
    const val COMMAND_TARGET = "commandTarget"

    /** Added to the content payload: which session a command came from. */
    const val PAYLOAD_SESSION_ID = "mediaSessionId"

    /** `buttonKeyPressed` prefix of a media command (`awn.media.pause`). */
    const val COMMAND_PREFIX = "awn.media."

    const val METHOD_STOP = "mediaStop"
    const val METHOD_UPDATE_POSITION = "mediaUpdatePosition"
    const val METHOD_CAPABILITIES = "mediaCapabilities"

    const val COMMANDS_CHANNEL = "awesome_notifications_media/commands"
    const val CONTROL = "control"

    const val LAYOUT_MEDIA_PLAYER = "MediaPlayer"

    /** The model's schedule entry (awesome_notifications_schedules). */
    const val SCHEDULE = "schedule"

    /** Content `createdSource` of a push (awesome_notifications_fcm). */
    const val SOURCE_FIREBASE = "Firebase"

    // 0.12 exception codes
    const val CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    const val DETAILED_INVALID_ARGUMENTS = "arguments.invalid"

    // Intent extras of the notification actions
    const val EXTRA_CONTROL = "awn.media.control"
}
