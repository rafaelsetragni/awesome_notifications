package me.carda.awesome_notifications_calls

import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationPerson

/** Dart `CallState`. */
internal enum class CallState {
    incoming, outgoing, ongoing, held, ended, missed;

    /** A call the system shows (ringing, calling or in progress). */
    val isLive: Boolean get() = this != ended && this != missed

    companion object {
        fun from(name: Any?): CallState? = values().firstOrNull { it.name == name }
    }
}

/** Dart `CallControl`. */
internal enum class CallControl {
    accept, decline, hangUp, mute, hold;

    companion object {
        fun from(name: Any?): CallControl? = values().firstOrNull { it.name == name }
    }
}

/** Dart `CallAction`: what happened to a call, from the user or the system. */
internal enum class CallAction {
    accept, decline, hangUp, mute, unmute, hold, unhold, timeout, audioActivated, audioDeactivated;

    /** The `buttonKeyPressed` of this action's commands. */
    val key: String get() = CallKeys.COMMAND_PREFIX + name

    companion object {
        fun from(name: String?): CallAction? = values().firstOrNull { it.name == name }
    }
}

/** Dart `CallCommandTarget`. */
internal enum class CommandTarget(val toActionEvent: Boolean, val toStream: Boolean) {
    actionEvent(true, false), stream(false, true), both(true, true);

    companion object {
        fun from(name: Any?): CommandTarget? = values().firstOrNull { it.name == name }
    }
}

/** Dart `CallEndReason`, with the Telecom disconnect cause it maps to. */
internal enum class EndReason {
    remoteEnded, declinedElsewhere, answeredElsewhere, unanswered, failed;

    companion object {
        fun from(name: Any?): EndReason = values().firstOrNull { it.name == name } ?: remoteEnded
    }
}

/** The `call` block of a model, validated as `NotificationCall.validate` does. */
internal data class CallModel(
    val callId: String,
    val caller: NotificationPerson,
    val handle: String?,
    val video: Boolean,
    val groupName: String?,
    val state: CallState,
    /** Milliseconds since the epoch (UTC). */
    val startedAt: Long?,
    val ringTimeoutMs: Long,
    val missedNotification: Boolean,
    val controls: Set<CallControl>,
    val target: CommandTarget,
    val texts: Map<String, String>,
    /** The block as received (kept to re-send it with a new state). */
    val raw: Map<String, Any?>
) {
    /** What the system shows as the caller: the group's name for a group call. */
    val displayName: String get() = groupName ?: caller.name

    fun text(key: String): String = texts[key] ?: DEFAULT_TEXTS.getValue(key)

    /** The block with a new [state] (and [startedAt]), as the model carries it. */
    fun toMap(state: CallState = this.state, startedAt: Long? = this.startedAt): Map<String, Any?> =
        raw.toMutableMap().apply {
            this[CallKeys.STATE] = state.name
            if (startedAt != null) this[CallKeys.STARTED_AT] = startedAt else remove(CallKeys.STARTED_AT)
        }

    companion object {
        /** Dart `CallTexts` defaults. */
        val DEFAULT_TEXTS = mapOf(
            CallKeys.TEXT_INCOMING to "Incoming call",
            CallKeys.TEXT_INCOMING_VIDEO to "Incoming video call",
            CallKeys.TEXT_OUTGOING to "Calling…",
            CallKeys.TEXT_ONGOING to "Ongoing call",
            CallKeys.TEXT_MISSED to "Missed call",
            CallKeys.TEXT_MISSED_VIDEO to "Missed video call",
            CallKeys.TEXT_ACCEPT to "Accept",
            CallKeys.TEXT_DECLINE to "Decline",
            CallKeys.TEXT_HANG_UP to "Hang up",
            CallKeys.TEXT_HELD to "On hold",
            CallKeys.TEXT_MUTE to "Mute",
            CallKeys.TEXT_UNMUTE to "Unmute",
            CallKeys.TEXT_HOLD to "Hold",
            CallKeys.TEXT_RESUME to "Resume"
        )

        /**
         * Parses the block, or returns why it is invalid. A push may carry it
         * as a JSON string, and with strings for its booleans and numbers.
         */
        fun parse(block: Any?): Pair<CallModel?, String?> {
            val map = when (block) {
                is Map<*, *> -> block
                is String -> try {
                    JsonUtils.getInstance().fromJson(block)
                } catch (_: Exception) {
                    null
                }
                else -> null
            } ?: return null to "The call block must be a map"

            val callId = map[CallKeys.CALL_ID] as? String
            if (callId == null || callId.trim().isEmpty()) return null to "The call needs a non-empty callId"

            val rawCaller = map[CallKeys.CALLER] as? Map<*, *>
            val key = rawCaller?.get(NotificationPerson.KEY) as? String
            val name = rawCaller?.get(NotificationPerson.NAME) as? String
            if (key == null || name == null) return null to "The call needs a caller with a key and a name"
            if (key.trim().isEmpty()) return null to "The caller needs a non-empty key"
            if (name.trim().isEmpty()) return null to "The caller needs a non-empty name"
            val caller = NotificationPerson.from(rawCaller)
                ?: return null to "The call needs a caller with a key and a name"

            val handle = map[CallKeys.HANDLE]
            if (handle != null && (handle !is String || handle.trim().isEmpty()))
                return null to "The call handle can't be empty (leave it out to use the caller's key)"
            val groupName = map[CallKeys.GROUP_NAME]
            if (groupName != null && (groupName !is String || groupName.trim().isEmpty()))
                return null to "The call groupName can't be empty"

            val video = bool(map[CallKeys.VIDEO], false) ?: return null to "The call video must be a bool"

            val state = CallState.from(map[CallKeys.STATE])
                ?: return null to "Unknown call state: ${map[CallKeys.STATE]}"

            val rawStarted = map[CallKeys.STARTED_AT]
            val startedAt = if (rawStarted == null) null
            else number(rawStarted)?.toLong() ?: return null to "The call startedAt must be milliseconds"

            val ringTimeout = number(map[CallKeys.RING_TIMEOUT] ?: 60_000)?.toLong()
            if (ringTimeout == null || ringTimeout <= 0) return null to "The ring timeout must be positive"

            val missed = bool(map[CallKeys.MISSED_NOTIFICATION], true)
                ?: return null to "The call missedNotification must be a bool"

            val rawControls = map[CallKeys.CONTROLS]
            val controls: Set<CallControl> = when (rawControls) {
                null -> CallControl.values().toSet()
                is List<*> -> rawControls.map {
                    CallControl.from(it) ?: return null to "Unknown call control: $it"
                }.toSet()
                else -> return null to "The call controls must be a list"
            }
            if (state == CallState.incoming &&
                CallControl.accept !in controls && CallControl.decline !in controls
            ) return null to "An incoming call needs the accept or the decline control"

            val rawTarget = map[CallKeys.COMMAND_TARGET] ?: CommandTarget.actionEvent.name
            val target = CommandTarget.from(rawTarget)
                ?: return null to "Unknown call commandTarget: $rawTarget"

            val rawTexts = map[CallKeys.TEXTS]
            if (rawTexts != null && rawTexts !is Map<*, *>) return null to "The call texts must be a map"
            val texts = DEFAULT_TEXTS.toMutableMap()
            (rawTexts as Map<*, *>?)?.forEach { (k, v) -> if (k is String && v is String) texts[k] = v }

            @Suppress("UNCHECKED_CAST")
            return CallModel(
                callId = callId,
                caller = caller,
                handle = handle,
                video = video,
                groupName = groupName,
                state = state,
                startedAt = startedAt,
                ringTimeoutMs = ringTimeout,
                missedNotification = missed,
                controls = controls,
                target = target,
                texts = texts,
                raw = (map as Map<String, Any?>).toMutableMap().apply {
                    this[CallKeys.STATE] = state.name
                }
            ) to null
        }

        private fun bool(value: Any?, default: Boolean): Boolean? = when (value) {
            null -> default
            is Boolean -> value
            "true" -> true
            "false" -> false
            else -> null
        }

        private fun number(value: Any?): Number? = when (value) {
            is Number -> value
            is String -> value.toLongOrNull() ?: value.toDoubleOrNull()
            else -> null
        }
    }
}
