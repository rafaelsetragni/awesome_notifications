package me.carda.awesome_notifications_calls

import android.Manifest
import android.app.Notification
import android.app.Service
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Keeps the app's process (its ring timer, its Telecom call) alive while a call
 * lasts and makes the call's notification a `phoneCall` foreground service's:
 * Android 12+ shows an ongoing CallStyle only for a foreground service.
 */
internal interface CallForeground {
    /**
     * Makes [notification] (posted with [id]) the foreground service's. With
     * [wait], returns once the service is in the foreground (false when it
     * can't be: permissions missing, started from the background…). Never
     * waits on the main thread.
     */
    fun show(context: Context, id: Int, channelKey: String?, notification: Notification, wait: Boolean): Boolean

    /** Whether the service is in the foreground with [id]. */
    fun isShowing(id: Int): Boolean

    /** Leaves the foreground with [id]: stops when no call is left, else shows [next]. */
    fun hide(context: Context, id: Int, next: Pair<Int, Notification>?)

    /** The real service. */
    object Service : CallForeground {
        override fun show(
            context: Context, id: Int, channelKey: String?, notification: Notification, wait: Boolean
        ): Boolean {
            if (!CallService.canRun(context)) return false
            CallService.pending[id] = notification
            CallService.instance?.let { running ->
                if (running.foregroundId != null) return running.enterForeground(id, notification)
            }
            val latch = CountDownLatch(1)
            CallService.waiting[id] = latch
            try {
                ContextCompat.startForegroundService(
                    context,
                    Intent(context, CallService::class.java)
                        .putExtra(CallKeys.EXTRA_NOTIFICATION_ID, id)
                        .putExtra(CallKeys.EXTRA_CHANNEL_KEY, channelKey)
                )
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException: the app is in the background.
                Log.w(TAG, "The call service can't start: ${e.message}")
                CallService.waiting.remove(id)
                return false
            }
            if (!wait || Looper.myLooper() == Looper.getMainLooper()) return true
            val started = latch.await(3, TimeUnit.SECONDS)
            CallService.waiting.remove(id)
            return started && CallService.instance?.foregroundId == id
        }

        override fun isShowing(id: Int): Boolean = CallService.instance?.foregroundId == id

        override fun hide(context: Context, id: Int, next: Pair<Int, Notification>?) {
            CallService.pending.remove(id)
            val running = CallService.instance ?: return
            if (running.foregroundId != id) return
            if (next != null) running.enterForeground(next.first, next.second)
            else running.leave()
        }
    }

    companion object {
        private const val TAG = "AwnCalls"
    }
}

class CallService : Service() {

    /** The notification id the service is in the foreground with. */
    @Volatile internal var foregroundId: Int? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getIntExtra(CallKeys.EXTRA_NOTIFICATION_ID, 0) ?: 0
        // startForegroundService requires startForeground, even for a call that already ended.
        val notification = pending[id] ?: placeholder(intent?.getStringExtra(CallKeys.EXTRA_CHANNEL_KEY))
        val entered = enterForeground(id, notification)
        waiting.remove(id)?.countDown()
        if (!entered || pending[id] == null) leave()
        return START_NOT_STICKY
    }

    internal fun enterForeground(id: Int, notification: Notification): Boolean = try {
        ServiceCompat.startForeground(this, id, notification, TYPE)
        foregroundId = id
        true
    } catch (e: Exception) {
        Log.w(TAG, "The call service can't enter the foreground: ${e.message}")
        false
    }

    internal fun leave() {
        foregroundId = null
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        foregroundId = null
        super.onDestroy()
    }

    private fun placeholder(channelKey: String?): Notification =
        NotificationCompat.Builder(this, channelKey ?: "")
            .setSmallIcon(applicationInfo.icon)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setSilent(true)
            .build()

    companion object {
        private const val TAG = "AwnCalls"

        private val TYPE: Int =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL else 0

        @Volatile internal var instance: CallService? = null

        /** The notification each call's foreground starts with (in-process: no Binder size limit). */
        internal val pending = java.util.concurrent.ConcurrentHashMap<Int, Notification>()
        internal val waiting = java.util.concurrent.ConcurrentHashMap<Int, CountDownLatch>()

        /**
         * Whether the app can run a `phoneCall` foreground service: a service
         * that can't enter the foreground after `startForegroundService`
         * crashes the app, so this is checked first. Android 9+ needs
         * FOREGROUND_SERVICE; Android 14+ also FOREGROUND_SERVICE_PHONE_CALL
         * and MANAGE_OWN_CALLS (or being the default dialer).
         */
        fun canRun(context: Context): Boolean {
            fun granted(permission: String) =
                ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && !granted(Manifest.permission.FOREGROUND_SERVICE))
                return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                if (!granted(Manifest.permission.FOREGROUND_SERVICE_PHONE_CALL)) return false
                if (!granted(Manifest.permission.MANAGE_OWN_CALLS) && !isDefaultDialer(context)) return false
            }
            return true
        }

        private fun isDefaultDialer(context: Context): Boolean =
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) false
            else context.getSystemService(RoleManager::class.java)?.isRoleHeld(RoleManager.ROLE_DIALER) == true
    }
}
