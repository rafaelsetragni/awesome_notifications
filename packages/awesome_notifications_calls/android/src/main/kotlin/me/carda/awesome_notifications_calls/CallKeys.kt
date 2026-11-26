package me.carda.awesome_notifications_calls

/** Keys of the `call` block and channel names (same names as the Dart `CallKeys`). */
internal object CallKeys {
    const val CALL = "call"

    const val CALL_ID = "callId"
    const val CALLER = "caller"
    const val HANDLE = "handle"
    const val VIDEO = "video"
    const val GROUP_NAME = "groupName"
    const val STATE = "state"
    const val STARTED_AT = "startedAt"
    const val RING_TIMEOUT = "ringTimeout"
    const val MISSED_NOTIFICATION = "missedNotification"
    const val CONTROLS = "controls"
    const val COMMAND_TARGET = "commandTarget"
    const val SYSTEM_CALL_UI = "systemCallUI"
    const val TEXTS = "texts"

    const val TEXT_INCOMING = "incoming"
    const val TEXT_INCOMING_VIDEO = "incomingVideo"
    const val TEXT_OUTGOING = "outgoing"
    const val TEXT_ONGOING = "ongoing"
    const val TEXT_MISSED = "missed"
    const val TEXT_MISSED_VIDEO = "missedVideo"
    const val TEXT_ACCEPT = "accept"
    const val TEXT_DECLINE = "decline"
    const val TEXT_HANG_UP = "hangUp"
    const val TEXT_HELD = "held"
    const val TEXT_MUTE = "mute"
    const val TEXT_UNMUTE = "unmute"
    const val TEXT_HOLD = "hold"
    const val TEXT_RESUME = "resume"

    /** Added to the content payload: which call an action came from. */
    const val PAYLOAD_CALL_ID = "callId"

    /** `buttonKeyPressed` prefix of a call command (`awn.call.accept`). */
    const val COMMAND_PREFIX = "awn.call."

    const val METHOD_END = "callEnd"
    const val METHOD_ACTIVE_CALLS = "callActiveCalls"
    const val METHOD_VOIP_TOKEN = "callVoipToken"
    const val METHOD_CAN_USE_FULL_SCREEN_INTENT = "callCanUseFullScreenIntent"
    const val METHOD_REQUEST_FULL_SCREEN_INTENT = "callRequestFullScreenIntent"
    const val METHOD_CAPABILITIES = "callCapabilities"
    const val REASON = "reason"

    const val EVENTS_CHANNEL = "awesome_notifications_calls/events"
    const val KIND = "kind"
    const val KIND_COMMAND = "command"
    const val ACTION = "action"

    /** The model's schedule entry (awesome_notifications_schedules). */
    const val SCHEDULE = "schedule"

    // 0.12 exception codes
    const val CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    const val DETAILED_INVALID_CALL = "arguments.invalid.notificationCall"

    // Internal model entries (never reach Dart)
    /** The call's microphone is muted (the model has no such field: the package keeps it). */
    const val MODEL_MUTED = "awn.call.muted"
    /** CallStyle can't be used for this build (no foreground service where Android needs one). */
    const val MODEL_PLAIN = "awn.call.plain"

    // Intent extras / actions
    const val EXTRA_ACTION = "awn.call.action"
    const val EXTRA_CALL_ID = "awn.call.callId"
    const val EXTRA_NOTIFICATION_ID = "awn.call.notificationId"
    const val EXTRA_CHANNEL_KEY = "awn.call.channelKey"
    const val INTENT_COMMAND = "me.carda.awesome_notifications_calls.COMMAND"
    const val INTENT_TIMEOUT = "me.carda.awesome_notifications_calls.TIMEOUT"
}
