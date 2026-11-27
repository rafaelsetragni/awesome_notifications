package me.carda.awesome_notifications_calls

import android.app.Application
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Looper
import android.telecom.CallAudioState
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.TelecomManager
import androidx.test.core.app.ApplicationProvider
import java.util.Collections
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The Telecom side of a call: which devices get [CoreTelecom], the end codes,
 * and the system call driven through androidx core-telecom's self-managed
 * ConnectionService (Android 8 to 13), whose connection the test creates as
 * Telecom would.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class CallTelecomTest {

    private val context: Application = ApplicationProvider.getApplicationContext()
    private val actions: MutableList<Pair<String, CallAction>> = Collections.synchronizedList(mutableListOf())
    private val listener = CallTelecom.Listener { id, action -> actions.add(id to action) }

    private fun call(
        callId: String = "t-1",
        state: String = "incoming",
        video: Boolean = false,
        handle: String? = "tel:+1"
    ) = CallModel.parse(
        mutableMapOf<String, Any?>(
            "callId" to callId,
            "caller" to mapOf("key" to "k", "name" to "Kay"),
            "state" to state,
            "video" to video
        ).apply { if (handle != null) this["handle"] = handle }
    ).first!!

    private fun telecomManager() = context.getSystemService(TelecomManager::class.java)

    private fun allowTelecom(feature: String = PackageManager.FEATURE_TELECOM) {
        shadowOf(context.packageManager).setSystemFeature(feature, true)
        shadowOf(context).grantPermissions(android.Manifest.permission.MANAGE_OWN_CALLS)
    }

    /** Lets the coroutines (Dispatchers.Default) and the main looper run until [done]. */
    private fun waitFor(timeoutMs: Long = 4_000, done: () -> Boolean): Boolean {
        val end = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < end) {
            shadowOf(Looper.getMainLooper()).idle()
            if (done()) return true
            Thread.sleep(20)
        }
        return done()
    }

    @Suppress("UNCHECKED_CAST")
    private fun tracked(telecom: CoreTelecom): Map<String, Any> =
        CoreTelecom::class.java.getDeclaredField("calls").apply { isAccessible = true }.get(telecom) as Map<String, Any>

    private fun trackedState(telecom: CoreTelecom, callId: String): Any? {
        val tracked = tracked(telecom)[callId] ?: return null
        return tracked.javaClass.getDeclaredMethod("getState").apply { isAccessible = true }.invoke(tracked)
    }

    // MARK: - create

    @Config(sdk = [25])
    @Test fun noTelecomBeforeAndroid8() {
        @Suppress("DEPRECATION")
        allowTelecom(PackageManager.FEATURE_CONNECTION_SERVICE)
        assertSame(CallTelecom.None, CallTelecom.create(context, listener))
    }

    @Config(sdk = [32])
    @Test fun noTelecomWithoutTheConnectionServiceFeature() {
        @Suppress("DEPRECATION")
        shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_CONNECTION_SERVICE, false)
        shadowOf(context).grantPermissions(android.Manifest.permission.MANAGE_OWN_CALLS)
        assertSame(CallTelecom.None, CallTelecom.create(context, listener))
    }

    @Config(sdk = [32])
    @Test fun noTelecomWithoutManageOwnCalls() {
        @Suppress("DEPRECATION")
        shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_CONNECTION_SERVICE, true)
        shadowOf(context).denyPermissions(android.Manifest.permission.MANAGE_OWN_CALLS)
        assertSame(CallTelecom.None, CallTelecom.create(context, listener))
    }

    @Config(sdk = [32])
    @Test fun android12UsesTheConnectionServiceFeature() {
        @Suppress("DEPRECATION")
        allowTelecom(PackageManager.FEATURE_CONNECTION_SERVICE)
        val telecom = CallTelecom.create(context, listener)
        assertTrue(telecom is CoreTelecom)
        assertTrue(telecom.isAvailable)
        // The app's phone account is registered with Telecom.
        assertEquals(1, shadowOf(telecomManager()).allPhoneAccounts.size)
    }

    @Test fun android13UsesTheTelecomFeature() {
        shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_TELECOM, false)
        shadowOf(context).grantPermissions(android.Manifest.permission.MANAGE_OWN_CALLS)
        assertSame(CallTelecom.None, CallTelecom.create(context, listener))
        allowTelecom()
        assertTrue(CallTelecom.create(context, listener) is CoreTelecom)
    }

    @Test fun theNoneTelecomDoesNothing() {
        assertFalse(CallTelecom.None.isAvailable)
        CallTelecom.None.sync(call())
        CallTelecom.None.end("t-1", DisconnectCause.LOCAL)
    }

    @Test fun endReasonsMapToTheTransactionalCauses() {
        assertEquals(DisconnectCause.REMOTE, CallTelecom.causeOf(EndReason.remoteEnded))
        assertEquals(DisconnectCause.REJECTED, CallTelecom.causeOf(EndReason.declinedElsewhere))
        assertEquals(DisconnectCause.LOCAL, CallTelecom.causeOf(EndReason.answeredElsewhere))
        assertEquals(DisconnectCause.MISSED, CallTelecom.causeOf(EndReason.unanswered))
        assertEquals(DisconnectCause.REMOTE, CallTelecom.causeOf(EndReason.failed))
    }

    @Test fun theAddressIsTheHandleUriOrTheAppsOwnId() {
        assertEquals("tel:+1", CoreTelecom.addressOf(call()).toString())
        assertEquals("sip:ana@x.org", CoreTelecom.addressOf(call(handle = "sip:ana@x.org")).toString())
        assertEquals("app:ana", CoreTelecom.addressOf(call(handle = "ana")).toString())
        assertEquals("app:k", CoreTelecom.addressOf(call(handle = null)).toString())
    }

    // MARK: - The system call

    /** Creates the connection Telecom asked the app's ConnectionService for. */
    private fun connect(incoming: Boolean = true): Connection {
        val shadow = shadowOf(telecomManager())
        assertTrue(waitFor {
            if (incoming) shadow.allIncomingCalls.isNotEmpty() else shadow.allOutgoingCalls.isNotEmpty()
        })
        // core-telecom's own (internal) self-managed ConnectionService.
        @Suppress("UNCHECKED_CAST")
        val type = Class.forName("androidx.core.telecom.internal.JetpackConnectionService") as Class<ConnectionService>
        val service: ConnectionService = Robolectric.setupService(type)
        val connection = if (incoming) {
            val record = shadow.allIncomingCalls.last()
            service.onCreateIncomingConnection(
                record.phoneAccount, ConnectionRequest(record.phoneAccount, Uri.parse("tel:+1"), record.extras)
            )
        } else {
            val record = shadow.allOutgoingCalls.last()
            service.onCreateOutgoingConnection(
                record.phoneAccount, ConnectionRequest(record.phoneAccount, record.address, record.extras)
            )
        }
        assertNotNull(connection)
        return connection!!
    }

    private fun connected(): CoreTelecom {
        allowTelecom()
        return CallTelecom.create(context, listener) as CoreTelecom
    }

    @Test fun theUsersAnswerHoldAndEndReachTheSystemCall() {
        val telecom = connected()
        telecom.sync(call())
        val connection = connect()

        // The same state again changes nothing.
        telecom.sync(call())
        // Answered in the app: active.
        telecom.sync(call(state = "ongoing"))
        assertTrue(waitFor { connection.state == Connection.STATE_ACTIVE })
        // Held, then resumed.
        telecom.sync(call(state = "held"))
        assertTrue(waitFor { connection.state == Connection.STATE_HOLDING })
        telecom.sync(call(state = "ongoing"))
        assertTrue(waitFor { connection.state == Connection.STATE_ACTIVE })
        // An outgoing state on a known call does nothing; ended calls are not synced.
        telecom.sync(call(state = "outgoing"))
        telecom.sync(call(state = "ended"))
        assertEquals(setOf("t-1"), tracked(telecom).keys)

        telecom.end("t-1", DisconnectCause.REJECTED)
        assertTrue(waitFor { connection.state == Connection.STATE_DISCONNECTED })
        assertEquals(DisconnectCause.REJECTED, connection.disconnectCause.code)
        assertTrue(tracked(telecom).isEmpty())
        // A second end is ignored; the app's own changes never come back as actions.
        telecom.end("t-1", DisconnectCause.LOCAL)
        Thread.sleep(100)
        assertTrue(actions.isEmpty())
    }

    @Test fun anIncomingCallHeldAtOnceIsAnsweredThenHeld() {
        val telecom = connected()
        telecom.sync(call())
        val connection = connect()
        telecom.sync(call(state = "held"))
        // Answered (core-telecom completes its answer after its own ringing check,
        // so the platform state may settle on either) and kept as held.
        assertTrue(waitFor { connection.state == Connection.STATE_ACTIVE || connection.state == Connection.STATE_HOLDING })
        assertEquals(CallState.held, trackedState(telecom, "t-1"))
    }

    @Test fun aCallFirstSeenInProgressIsAnOutgoingCallAlreadyConnected() {
        val telecom = connected()
        telecom.sync(call(state = "held", video = true))
        val connection = connect(incoming = false)
        // Activated (no longer dialing) and kept as held.
        assertTrue(waitFor { connection.state == Connection.STATE_ACTIVE || connection.state == Connection.STATE_HOLDING })
        assertEquals(CallState.held, trackedState(telecom, "t-1"))
        assertTrue(connection.connectionCapabilities and Connection.CAPABILITY_HOLD != 0)
    }

    @Test fun theSystemsAnswerHoldResumeMuteAndEndReachTheApp() {
        val telecom = connected()
        telecom.sync(call())
        val connection = connect()
        Thread.sleep(200)

        connection.onAnswer()
        assertTrue(waitFor { actions.contains("t-1" to CallAction.accept) })
        connection.onHold()
        assertTrue(waitFor { actions.contains("t-1" to CallAction.hold) })
        connection.onUnhold()
        assertTrue(waitFor { actions.contains("t-1" to CallAction.unhold) })

        @Suppress("DEPRECATION")
        connection.onCallAudioStateChanged(CallAudioState(false, CallAudioState.ROUTE_EARPIECE, CallAudioState.ROUTE_EARPIECE))
        Thread.sleep(100)
        @Suppress("DEPRECATION")
        connection.onCallAudioStateChanged(CallAudioState(true, CallAudioState.ROUTE_EARPIECE, CallAudioState.ROUTE_EARPIECE))
        assertTrue(waitFor { actions.contains("t-1" to CallAction.mute) })
        @Suppress("DEPRECATION")
        connection.onCallAudioStateChanged(CallAudioState(false, CallAudioState.ROUTE_EARPIECE, CallAudioState.ROUTE_EARPIECE))
        assertTrue(waitFor { actions.contains("t-1" to CallAction.unmute) })

        connection.onDisconnect()
        assertTrue(waitFor { actions.contains("t-1" to CallAction.hangUp) })
        assertTrue(tracked(telecom).isEmpty())
        assertEquals(
            listOf(CallAction.accept, CallAction.hold, CallAction.unhold, CallAction.mute, CallAction.unmute, CallAction.hangUp),
            actions.map { it.second }
        )
    }

    @Test fun theSystemDecliningARingingCallIsADecline() {
        val telecom = connected()
        telecom.sync(call())
        val connection = connect()
        Thread.sleep(200)
        connection.onReject()
        assertTrue(waitFor { actions.contains("t-1" to CallAction.decline) })
        assertEquals(1, actions.size)
    }

    @Config(sdk = [34])
    @Test fun android14WithoutATelecomServiceForgetsTheCall() {
        allowTelecom(PackageManager.FEATURE_TELECOM)
        val telecom = CallTelecom.create(context, listener) as CoreTelecom
        telecom.sync(call())
        // addCall fails (no system Telecom service here): the call is not tracked.
        assertTrue(waitFor { tracked(telecom).isEmpty() })
        assertTrue(actions.isEmpty())
    }
}
