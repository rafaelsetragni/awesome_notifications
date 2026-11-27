package me.carda.awesome_notifications_calls

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import org.robolectric.Shadows.shadowOf

/** The foreground service, as the test allows it. */
internal class RecordingForeground : CallForeground {
    var allowed = true
    var showing: Int? = null
    val hidden = mutableListOf<Int>()
    override fun show(context: Context, id: Int, channelKey: String?, notification: Notification, wait: Boolean): Boolean {
        if (allowed) showing = id
        return allowed
    }
    override fun isShowing(id: Int) = showing == id
    override fun hide(context: Context, id: Int, next: Pair<Int, Notification>?) {
        hidden.add(id)
        if (showing == id) showing = next?.first
    }
}

/** Telecom, recording what the package asks of it. */
internal class RecordingTelecom(val listener: CallTelecom.Listener) : CallTelecom {
    override val isAvailable = true
    val synced = mutableListOf<Pair<String, CallState>>()
    val ended = mutableListOf<Pair<String, Int>>()
    override fun sync(call: CallModel) { synced.add(call.callId to call.state) }
    override fun end(callId: String, cause: Int) { ended.add(callId to cause) }
}

/** A messenger that records the handlers set on it and the messages sent. */
internal class RecordingMessenger : BinaryMessenger {
    val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()
    val sent = mutableListOf<Pair<String, ByteBuffer?>>()
    override fun send(channel: String, message: ByteBuffer?) { sent.add(channel to message) }
    override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {
        sent.add(channel to message)
    }
    override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
        handlers[channel] = handler
    }
}

/** Seams of [Calls] pointing at the fakes, with a core that builds inline. */
internal class CallsHarness(val context: Context) {
    val direct = Executor { it.run() }
    val core = AwesomeNotifications(context, direct)
    val foreground = RecordingForeground()
    var telecom: RecordingTelecom? = null
    val streamed = mutableListOf<Map<String, Any?>>()

    fun setUp() {
        AwesomeNotificationsCallsPlugin.install()
        Calls.resetForTest()
        Calls.executor = direct
        Calls.foreground = foreground
        Calls.makeTelecom = { _, l -> RecordingTelecom(l).also { telecom = it } }
        Calls.makeCore = { core }
        Calls.clock = { 1_000_000L }
        Calls.streamSink = { streamed.add(it) }
        manager().cancelAll()
        core.setChannel(
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "calls", Definitions.NOTIFICATION_CHANNEL_NAME to "Calls")
        )
    }

    fun tearDown() = Calls.resetForTest()

    fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun idle() = shadowOf(Looper.getMainLooper()).idle()

    fun isShown(id: Int) = manager().activeNotifications.any { it.id == id }

    fun call(
        callId: String = "c-1",
        state: String = "incoming",
        target: String = "actionEvent",
        extra: Map<String, Any?> = emptyMap()
    ) = mutableMapOf<String, Any?>(
        "callId" to callId,
        "caller" to mapOf("key" to "little-mary", "name" to "Little Mary"),
        "handle" to "tel:+5511999999999",
        "state" to state,
        "ringTimeout" to 30_000,
        "commandTarget" to target,
        "texts" to CallModel.DEFAULT_TEXTS
    ).apply { putAll(extra) }

    /** Creates a call's notification through the core and returns whether it posted. */
    fun create(
        call: Map<String, Any?> = call(),
        id: Int = 300,
        content: Map<String, Any?> = emptyMap()
    ): Boolean? {
        val c = mutableMapOf<String, Any?>(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "calls",
            Definitions.NOTIFICATION_TITLE to "Little Mary"
        )
        c.putAll(content)
        var created: Boolean? = null
        core.createNotification(mapOf(Definitions.NOTIFICATION_CONTENT to c, CallKeys.CALL to call)) { created = it }
        idle()
        return created
    }
}
