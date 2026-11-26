package me.carda.awesome_notifications_live_activities

/** Keys of the `liveActivity` block and channel names (same names as the Dart `LiveActivityKeys`). */
internal object LiveKeys {
    const val LIVE_ACTIVITY = "liveActivity"

    const val ACTIVITY_ID = "activityId"
    const val STATE = "state"
    const val PROGRESS = "progress"
    const val TIMER = "timer"
    const val METRICS = "metrics"
    const val SHORT_TEXT = "shortText"
    const val ACCENT_COLOR = "accentColor"
    const val STALE_AT = "staleAt"
    const val RELEVANCE = "relevance"
    const val ALERT = "alert"
    const val DISMISSAL = "dismissal"
    const val PUSH_CHANNEL = "pushChannel"

    const val SEGMENTS = "segments"
    const val POINTS = "points"
    const val TRACKER_ICON = "trackerIcon"
    const val START_ICON = "startIcon"
    const val END_ICON = "endIcon"
    const val LENGTH = "length"
    const val POSITION = "position"
    const val COLOR = "color"

    const val START = "start"
    const val END = "end"
    const val COUNT_DOWN = "countDown"

    const val LABEL = "label"
    const val VALUE = "value"
    const val UNIT = "unit"

    const val DISMISSAL_DEFAULT = "default"
    const val DISMISSAL_IMMEDIATE = "immediate"

    /** Added to the content payload: which activity an action came from. */
    const val PAYLOAD_ACTIVITY_ID = "activityId"

    const val METHOD_END = "liveActivityEnd"
    const val METHOD_LIST = "liveActivityList"
    const val METHOD_CAPABILITIES = "liveActivityCapabilities"
    const val METHOD_ARE_ENABLED = "liveActivityAreEnabled"
    const val METHOD_REQUEST_PERMISSION = "liveActivityRequestPermission"
    const val METHOD_PUSH_TO_START_TOKEN = "liveActivityPushToStartToken"
    const val METHOD_PUSH_TOKEN = "liveActivityPushToken"

    const val EVENTS_CHANNEL = "awesome_notifications_live_activities/events"
    const val KIND = "kind"
    const val KIND_STATE = "state"

    // LiveActivityStatus names
    const val STATUS_ACTIVE = "active"
    const val STATUS_ENDED = "ended"
    const val STATUS_DISMISSED = "dismissed"

    const val CAP_SYSTEM_SURFACE = "systemSurface"
    const val CAP_PROGRESS_SEGMENTS = "progressSegments"
    const val CAP_METRICS = "metrics"
    const val CAP_BUTTONS = "buttons"
    const val CAP_PUSH = "push"

    /** The model's schedule entry (awesome_notifications_schedules). */
    const val SCHEDULE = "schedule"

    // 0.12 exception codes
    const val CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    const val DETAILED_INVALID_LIVE_ACTIVITY = "arguments.invalid.notificationLiveActivity"
}
