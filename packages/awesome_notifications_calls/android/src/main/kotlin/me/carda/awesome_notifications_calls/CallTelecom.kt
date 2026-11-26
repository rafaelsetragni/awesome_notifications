package me.carda.awesome_notifications_calls

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telecom.DisconnectCause
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.telecom.CallAttributesCompat
import androidx.core.telecom.CallControlScope
import androidx.core.telecom.CallsManager
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch

/**
 * The system call of each call (Android Telecom): what lets Bluetooth
 * headsets, cars, watches and the system answer, end, hold and mute it, and
 * routes its audio. The package keeps the system call in the call's state; the
 * system's requests come back through [Listener].
 */
internal interface CallTelecom {

    fun interface Listener {
        /** The system (a headset, a car, a watch…) asked for [action] on [callId]. */
        fun onSystemAction(callId: String, action: CallAction)
    }

    /** Whether calls reach Telecom on this device. */
    val isAvailable: Boolean

    /** Brings the system call of [call] to its state, adding it on first sight. */
    fun sync(call: CallModel)

    /** Ends the system call with a [DisconnectCause] code (no callback follows). */
    fun end(callId: String, cause: Int)

    companion object {
        /** Telecom (androidx core-telecom) from API 26 where the device has it; nothing below. */
        fun create(context: Context, listener: Listener): CallTelecom {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return None
            val app = context.applicationContext
            val feature = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) PackageManager.FEATURE_TELECOM
            else @Suppress("DEPRECATION") PackageManager.FEATURE_CONNECTION_SERVICE
            if (!app.packageManager.hasSystemFeature(feature)) return None
            if (app.checkSelfPermission(android.Manifest.permission.MANAGE_OWN_CALLS) !=
                PackageManager.PERMISSION_GRANTED
            ) return None
            return CoreTelecom(app, listener)
        }

        /** The Telecom code of an end. */
        fun causeOf(reason: EndReason): Int = when (reason) {
            EndReason.remoteEnded -> DisconnectCause.REMOTE
            EndReason.declinedElsewhere -> DisconnectCause.REJECTED
            EndReason.answeredElsewhere -> DisconnectCause.LOCAL
            EndReason.unanswered -> DisconnectCause.MISSED
            // Transactional calls only take LOCAL, REMOTE, REJECTED or MISSED.
            EndReason.failed -> DisconnectCause.REMOTE
        }
    }

    /** No Telecom (API < 26, no connection service, no MANAGE_OWN_CALLS). */
    object None : CallTelecom {
        override val isAvailable = false
        override fun sync(call: CallModel) {}
        override fun end(callId: String, cause: Int) {}
    }
}

/**
 * Telecom through androidx core-telecom's [CallsManager]: the platform's
 * transactional calls on Android 14+, a self-managed ConnectionService on
 * Android 8 to 13 (both handled by the library).
 */
@RequiresApi(Build.VERSION_CODES.O)
internal class CoreTelecom(
    private val context: Context,
    private val listener: CallTelecom.Listener
) : CallTelecom {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    private val manager: CallsManager? by lazy {
        try {
            CallsManager(context).also {
                it.registerAppWithTelecom(
                    CallsManager.CAPABILITY_BASELINE or CallsManager.CAPABILITY_SUPPORTS_VIDEO_CALLING
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "Telecom is not available: ${e.message}")
            null
        }
    }

    override val isAvailable: Boolean get() = manager != null

    /** One system call: its operations run in order once Telecom added it. */
    private class Tracked(val callId: String, @Volatile var state: CallState) {
        val ops = Channel<suspend CallControlScope.() -> Unit>(Channel.UNLIMITED)
        @Volatile var ended = false
    }

    private val calls = ConcurrentHashMap<String, Tracked>()

    override fun sync(call: CallModel) {
        if (!call.state.isLive) return
        val tracked = calls[call.callId]
        if (tracked == null) {
            add(call)
            return
        }
        val from = tracked.state
        val to = call.state
        if (from == to) return
        tracked.state = to
        val type = callType(call)
        when {
            from == CallState.incoming && to == CallState.ongoing -> tracked.run { answer(type) }
            from == CallState.incoming && to == CallState.held -> tracked.run { answer(type); setInactive() }
            to == CallState.ongoing -> tracked.run { setActive() }
            to == CallState.held -> tracked.run { setInactive() }
            else -> {}
        }
    }

    override fun end(callId: String, cause: Int) {
        val tracked = calls.remove(callId) ?: return
        tracked.ended = true
        tracked.run { disconnect(DisconnectCause(cause)) }
        tracked.ops.close()
    }

    private fun Tracked.run(op: suspend CallControlScope.() -> Unit) {
        ops.trySend(op)
    }

    private fun add(call: CallModel) {
        val manager = manager ?: return
        val incoming = call.state == CallState.incoming
        val tracked = Tracked(call.callId, call.state)
        calls[call.callId] = tracked
        // A call seen first in progress: an outgoing call already connected.
        if (call.state == CallState.ongoing || call.state == CallState.held) tracked.run { setActive() }
        if (call.state == CallState.held) tracked.run { setInactive() }

        val attributes = CallAttributesCompat(
            displayName = call.displayName,
            address = addressOf(call),
            direction = if (incoming) CallAttributesCompat.DIRECTION_INCOMING
            else CallAttributesCompat.DIRECTION_OUTGOING,
            callType = callType(call),
            callCapabilities = CallAttributesCompat.SUPPORTS_SET_INACTIVE
        )
        scope.launch {
            try {
                manager.addCall(
                    attributes,
                    onAnswer = {
                        if (tracked.state == CallState.incoming) {
                            tracked.state = CallState.ongoing
                            listener.onSystemAction(tracked.callId, CallAction.accept)
                        }
                    },
                    onDisconnect = {
                        if (!tracked.ended) {
                            tracked.ended = true
                            calls.remove(tracked.callId, tracked)
                            val action =
                                if (tracked.state == CallState.incoming) CallAction.decline else CallAction.hangUp
                            listener.onSystemAction(tracked.callId, action)
                        }
                    },
                    onSetActive = {
                        val wasHeld = tracked.state == CallState.held
                        tracked.state = CallState.ongoing
                        if (wasHeld) listener.onSystemAction(tracked.callId, CallAction.unhold)
                    },
                    onSetInactive = {
                        if (tracked.state != CallState.held) {
                            tracked.state = CallState.held
                            listener.onSystemAction(tracked.callId, CallAction.hold)
                        }
                    }
                ) {
                    val control = this
                    // The system's microphone mute (a headset's mute button, the car…).
                    launch {
                        isMuted.drop(1).distinctUntilChanged().collect { muted ->
                            if (!tracked.ended) listener.onSystemAction(
                                tracked.callId, if (muted) CallAction.mute else CallAction.unmute
                            )
                        }
                    }
                    launch {
                        for (op in tracked.ops) {
                            try {
                                control.op()
                            } catch (e: Exception) {
                                Log.w(TAG, "Telecom operation failed for ${tracked.callId}: ${e.message}")
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Telecom did not add the call ${call.callId}: ${e.message}")
                calls.remove(tracked.callId, tracked)
            }
        }
    }

    private fun callType(call: CallModel) =
        if (call.video) CallAttributesCompat.CALL_TYPE_VIDEO_CALL else CallAttributesCompat.CALL_TYPE_AUDIO_CALL

    companion object {
        private const val TAG = "AwnCalls"

        /** The handle as a uri (`tel:`, `mailto:`, `sip:`…), or the app's own id. */
        fun addressOf(call: CallModel): Uri {
            val handle = call.handle
            if (handle != null && Regex("^[a-zA-Z][a-zA-Z0-9+.-]*:.+").matches(handle)) return Uri.parse(handle)
            return Uri.fromParts("app", handle ?: call.caller.key, null)
        }
    }
}
