package me.carda.awesome_notifications_calls

import android.Manifest
import android.app.Application
import android.app.Notification
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.ContextWrapper
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config

/** The `phoneCall` foreground service: when it may run, how it starts, enters and leaves the foreground. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CallServiceTest {

    private val context: Application = ApplicationProvider.getApplicationContext()
    private val controllers = mutableListOf<ServiceController<CallService>>()

    private fun notification(text: String = "call"): Notification =
        Notification.Builder(context, "calls").setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentText(text).build()

    private fun grant(vararg permissions: String) = shadowOf(context).grantPermissions(*permissions)

    private fun grantAll() = grant(
        Manifest.permission.FOREGROUND_SERVICE,
        Manifest.permission.FOREGROUND_SERVICE_PHONE_CALL,
        Manifest.permission.MANAGE_OWN_CALLS
    )

    /** Starts the service as the system would for [intent]. */
    private fun startService(intent: Intent): CallService =
        Robolectric.buildService(CallService::class.java, intent).also { controllers.add(it) }
            .create().startCommand(0, 1).get()

    private fun serviceIntent(id: Int) = Intent(context, CallService::class.java).putExtra(CallKeys.EXTRA_NOTIFICATION_ID, id)

    @Before fun setUp() {
        CallService.pending.clear()
        CallService.waiting.clear()
        CallService.instance = null
        shadowOf(context).clearStartedServices()
    }

    @After fun tearDown() {
        controllers.forEach { runCatching { it.destroy() } }
        CallService.pending.clear()
        CallService.waiting.clear()
        CallService.instance = null
    }

    // MARK: - canRun

    @Test fun android14NeedsBothForegroundPermissionsAndManageOwnCallsOrTheDialerRole() {
        assertFalse(CallService.canRun(context))
        grant(Manifest.permission.FOREGROUND_SERVICE)
        assertFalse(CallService.canRun(context))
        grant(Manifest.permission.FOREGROUND_SERVICE_PHONE_CALL)
        assertFalse(CallService.canRun(context))
        // The default dialer doesn't need MANAGE_OWN_CALLS.
        shadowOf(context.getSystemService(RoleManager::class.java)).addHeldRole(RoleManager.ROLE_DIALER)
        assertTrue(CallService.canRun(context))
        shadowOf(context.getSystemService(RoleManager::class.java)).removeHeldRole(RoleManager.ROLE_DIALER)
        assertFalse(CallService.canRun(context))
        grant(Manifest.permission.MANAGE_OWN_CALLS)
        assertTrue(CallService.canRun(context))
    }

    @Config(sdk = [28])
    @Test fun android9NeedsOnlyTheForegroundServicePermission() {
        shadowOf(context).denyPermissions(Manifest.permission.FOREGROUND_SERVICE)
        assertFalse(CallService.canRun(context))
        grant(Manifest.permission.FOREGROUND_SERVICE)
        assertTrue(CallService.canRun(context))
    }

    @Config(sdk = [26])
    @Test fun android8NeedsNoPermission() {
        assertTrue(CallService.canRun(context))
    }

    // MARK: - show

    @Test fun withoutThePermissionsTheServiceIsNotStarted() {
        assertFalse(CallForeground.Service.show(context, 7, "calls", notification(), wait = false))
        assertNull(shadowOf(context).nextStartedService)
        assertTrue(CallService.pending.isEmpty())
    }

    @Test fun showStartsTheServiceWhichEntersTheForegroundWithTheCallsNotification() {
        grantAll()
        val n = notification()
        assertTrue(CallForeground.Service.show(context, 7, "calls", n, wait = false))
        assertSame(n, CallService.pending[7])

        val started = shadowOf(context).nextStartedService
        assertEquals(ComponentName(context, CallService::class.java), started.component)
        assertEquals(7, started.getIntExtra(CallKeys.EXTRA_NOTIFICATION_ID, 0))
        assertEquals("calls", started.getStringExtra(CallKeys.EXTRA_CHANNEL_KEY))

        val service = startService(started)
        assertEquals(7, service.foregroundId)
        assertSame(n, shadowOf(service).lastForegroundNotification)
        assertTrue(CallForeground.Service.isShowing(7))
        assertFalse(CallForeground.Service.isShowing(8))
        // The latch the caller could wait on was released and dropped.
        assertTrue(CallService.waiting.isEmpty())
    }

    @Test fun showOnTheMainThreadNeverWaits() {
        grantAll()
        // No service comes up, yet the main thread returns at once.
        assertTrue(CallForeground.Service.show(context, 7, "calls", notification(), wait = true))
        assertTrue(CallService.waiting.containsKey(7))
    }

    @Test fun showOffTheMainThreadWaitsForTheServiceToBeInTheForeground() {
        grantAll()
        var shown: Boolean? = null
        val worker = Thread { shown = CallForeground.Service.show(context, 9, "calls", notification(), wait = true) }
        worker.start()
        val deadline = System.currentTimeMillis() + 2_000
        var started: Intent? = null
        while (started == null && System.currentTimeMillis() < deadline) {
            started = shadowOf(context).peekNextStartedService()
            if (started == null) Thread.sleep(10)
        }
        startService(started!!)
        worker.join(3_000)
        assertEquals(true, shown)
        assertTrue(CallService.waiting.isEmpty())
    }

    @Test fun showOffTheMainThreadIsFalseWhenTheServiceNeverComes() {
        grantAll()
        var shown: Boolean? = null
        val worker = Thread { shown = CallForeground.Service.show(context, 9, "calls", notification(), wait = true) }
        worker.start()
        worker.join(5_000)
        assertEquals(false, shown)
        assertTrue(CallService.waiting.isEmpty())
    }

    @Test fun aRunningServiceSwitchesToTheNewCallAtOnce() {
        grantAll()
        val first = notification("first")
        CallService.pending[1] = first
        val service = startService(serviceIntent(1))
        assertEquals(1, service.foregroundId)

        shadowOf(context).clearStartedServices()
        val second = notification("second")
        assertTrue(CallForeground.Service.show(context, 2, "calls", second, wait = true))
        assertEquals(2, service.foregroundId)
        assertSame(second, shadowOf(service).lastForegroundNotification)
        assertNull(shadowOf(context).nextStartedService)
    }

    @Test fun aRunningServiceOutOfTheForegroundIsStartedAgain() {
        grantAll()
        CallService.pending[1] = notification()
        val service = startService(serviceIntent(1))
        CallForeground.Service.hide(context, 1, null)
        assertNull(service.foregroundId)
        // Not destroyed yet: the next call goes through startForegroundService again.
        shadowOf(context).clearStartedServices()
        assertTrue(CallForeground.Service.show(context, 3, "calls", notification(), wait = false))
        assertEquals(3, shadowOf(context).nextStartedService.getIntExtra(CallKeys.EXTRA_NOTIFICATION_ID, 0))
    }

    @Test fun anAppInTheBackgroundCantStartTheService() {
        grantAll()
        val background = object : ContextWrapper(context) {
            override fun startForegroundService(service: Intent) =
                throw IllegalStateException("ForegroundServiceStartNotAllowedException")
        }
        assertFalse(CallForeground.Service.show(background, 7, "calls", notification(), wait = false))
        assertTrue(CallService.waiting.isEmpty())
    }

    // MARK: - hide

    @Test fun hideWithoutAServiceForgetsThePendingNotification() {
        CallService.pending[7] = notification()
        CallForeground.Service.hide(context, 7, null)
        assertTrue(CallService.pending.isEmpty())
        assertFalse(CallForeground.Service.isShowing(7))
    }

    @Test fun hideOfAnotherCallLeavesTheServiceAsItIs() {
        CallService.pending[1] = notification()
        val service = startService(serviceIntent(1))
        CallForeground.Service.hide(context, 2, null)
        assertEquals(1, service.foregroundId)
        assertFalse(shadowOf(service).isStoppedBySelf)
    }

    @Test fun hideWithANextCallMovesTheForegroundToIt() {
        CallService.pending[1] = notification()
        val service = startService(serviceIntent(1))
        val next = notification("next")
        CallForeground.Service.hide(context, 1, 5 to next)
        assertEquals(5, service.foregroundId)
        assertSame(next, shadowOf(service).lastForegroundNotification)
        assertFalse(shadowOf(service).isStoppedBySelf)
    }

    @Test fun theServiceIsNotBindable() {
        CallService.pending[1] = notification()
        val service = startService(serviceIntent(1))
        assertNull(service.onBind(serviceIntent(1)))
    }

    @Test fun aServiceStartedWithoutAnIntentLeaves() {
        val service = Robolectric.buildService(CallService::class.java, null).also { controllers.add(it) }
            .create().get()
        service.onStartCommand(null, 0, 1)
        assertNull(service.foregroundId)
        assertTrue(shadowOf(service).isStoppedBySelf)
    }
}
