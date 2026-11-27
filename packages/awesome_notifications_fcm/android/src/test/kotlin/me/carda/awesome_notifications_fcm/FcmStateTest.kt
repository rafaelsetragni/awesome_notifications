package me.carda.awesome_notifications_fcm

import android.app.ActivityManager
import android.content.Context
import android.content.ContextWrapper
import androidx.test.core.app.ApplicationProvider
import me.carda.android_awn_core.NotificationLifeCycle
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** The persisted handles / token, the process-global event bridge and the lifecycle stamp. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class FcmStateTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()

    private class TokenRecorder : FcmEventsReceiver.TokenListener {
        val fcm = mutableListOf<String?>()
        val native = mutableListOf<String?>()
        override fun onNewFcmToken(token: String?) { fcm.add(token) }
        override fun onNewNativeToken(token: String?) { native.add(token) }
    }

    private class SilentRecorder(val consume: Boolean) : FcmEventsReceiver.SilentListener {
        val received = mutableListOf<SilentDataModel>()
        override fun onSilentData(silentData: SilentDataModel): Boolean {
            received.add(silentData)
            return consume
        }
    }

    private val tokens = TokenRecorder()
    private val silent = SilentRecorder(consume = true)
    private val passive = SilentRecorder(consume = false)

    @After fun tearDown() {
        FcmEventsReceiver.unsubscribeToken(tokens)
        FcmEventsReceiver.unsubscribeSilent(silent)
        FcmEventsReceiver.unsubscribeSilent(passive)
    }

    // MARK: - FcmDefaultsManager

    @Test fun nothingIsStoredBeforeInitialization() {
        assertEquals(0L, FcmDefaultsManager.getDartBackgroundHandle(context))
        assertEquals(0L, FcmDefaultsManager.getSilentCallbackHandle(context))
        assertFalse(FcmDefaultsManager.isDebug(context))
        assertNull(FcmDefaultsManager.getLastToken(context))
    }

    @Test fun handlesAndDebugArePersisted() {
        FcmDefaultsManager.saveHandles(context, 11L, 22L, true)
        assertEquals(11L, FcmDefaultsManager.getDartBackgroundHandle(context))
        assertEquals(22L, FcmDefaultsManager.getSilentCallbackHandle(context))
        assertTrue(FcmDefaultsManager.isDebug(context))

        // Missing handles keep the stored ones; the debug flag is always rewritten.
        FcmDefaultsManager.saveHandles(context, null, null, false)
        assertEquals(11L, FcmDefaultsManager.getDartBackgroundHandle(context))
        assertEquals(22L, FcmDefaultsManager.getSilentCallbackHandle(context))
        assertFalse(FcmDefaultsManager.isDebug(context))
    }

    @Test fun theLastTokenIsPersistedAndCanBeCleared() {
        FcmDefaultsManager.setLastToken(context, "tok-1")
        assertEquals("tok-1", FcmDefaultsManager.getLastToken(context))
        FcmDefaultsManager.setLastToken(context, null)
        assertNull(FcmDefaultsManager.getLastToken(context))
    }

    // MARK: - FcmEventsReceiver

    @Test fun tokenEventsReachEachListenerOnce() {
        FcmEventsReceiver.subscribeToken(tokens)
        FcmEventsReceiver.subscribeToken(tokens)
        FcmEventsReceiver.notifyFcmToken("fcm")
        FcmEventsReceiver.notifyNativeToken("apns")
        assertEquals(listOf<String?>("fcm"), tokens.fcm)
        assertEquals(listOf<String?>("apns"), tokens.native)

        FcmEventsReceiver.unsubscribeToken(tokens)
        FcmEventsReceiver.notifyFcmToken("again")
        assertEquals(listOf<String?>("fcm"), tokens.fcm)
    }

    @Test fun silentDataIsConsumedOnlyWhenSomeListenerTakesIt() {
        val data = SilentDataModel().fromData(mapOf("k" to "v"))
        assertFalse(FcmEventsReceiver.hasSilentListener())
        assertFalse(FcmEventsReceiver.notifySilentData(data))

        FcmEventsReceiver.subscribeSilent(passive)
        FcmEventsReceiver.subscribeSilent(passive)
        assertTrue(FcmEventsReceiver.hasSilentListener())
        assertFalse(FcmEventsReceiver.notifySilentData(data))
        assertEquals(1, passive.received.size)

        FcmEventsReceiver.subscribeSilent(silent)
        assertTrue(FcmEventsReceiver.notifySilentData(data))
        assertEquals(listOf(data), silent.received)

        FcmEventsReceiver.unsubscribeSilent(silent)
        FcmEventsReceiver.unsubscribeSilent(passive)
        assertFalse(FcmEventsReceiver.hasSilentListener())
    }

    // MARK: - FcmLifecycle

    private fun setImportance(importance: Int?, pid: Int = android.os.Process.myPid()) {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val processes = if (importance == null) emptyList() else listOf(
            ActivityManager.RunningAppProcessInfo().apply {
                this.pid = pid
                this.processName = context.packageName
                this.importance = importance
            }
        )
        shadowOf(am).setProcesses(processes)
    }

    @Test fun aForegroundOrVisibleProcessIsForeground() {
        for (importance in listOf(
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND,
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE,
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE
        )) {
            setImportance(importance)
            assertEquals(NotificationLifeCycle.Foreground, FcmLifecycle.current(context))
        }
    }

    @Test fun aLiveBackgroundProcessIsBackground() {
        setImportance(ActivityManager.RunningAppProcessInfo.IMPORTANCE_CACHED)
        assertEquals(NotificationLifeCycle.Background, FcmLifecycle.current(context))
    }

    @Test fun noProcessRecordIsTerminated() {
        setImportance(null)
        assertEquals(NotificationLifeCycle.Terminated, FcmLifecycle.current(context))
        setImportance(ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND, pid = -1)
        assertEquals(NotificationLifeCycle.Terminated, FcmLifecycle.current(context))
    }

    @Test fun noActivityManagerIsTerminated() {
        val noServices = object : ContextWrapper(context) {
            override fun getSystemService(name: String): Any? = null
        }
        assertEquals(NotificationLifeCycle.Terminated, FcmLifecycle.current(noServices))
    }
}
