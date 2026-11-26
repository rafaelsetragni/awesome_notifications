package me.carda.awesome_notifications_calls

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.CancelInterceptorRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Calls decorator plugin (Android). Installs the [CallBuilder] in the core's
 * decorator chain, answers the AwesomeNotificationsCalls methods through the
 * core's channel, streams the commands on its own EventChannel and shows the
 * app's activity over the lock screen while a call it was opened for lasts.
 */
class AwesomeNotificationsCallsPlugin :
    FlutterPlugin,
    ActivityAware,
    EventChannel.StreamHandler,
    PluginRegistry.NewIntentListener,
    PluginRegistry.ActivityResultListener {

    private var methodHandler: CallMethodHandler? = null
    private var events: EventChannel? = null
    private var sink: ((Map<String, Any?>) -> Unit)? = null

    private var binding: ActivityPluginBinding? = null
    private var activity: Activity? = null
    private var overLockScreen = false
    private var pendingFullScreen: ((Boolean) -> Unit)? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        install()
        val context = binding.applicationContext
        methodHandler = CallMethodHandler(context) { answer -> requestFullScreenIntent(answer) }.also {
            AwesomeMethodHandlerRegistry.register(it)
        }
        events = EventChannel(binding.binaryMessenger, CallKeys.EVENTS_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodHandler?.let { AwesomeMethodHandlerRegistry.unregister(it) }
        methodHandler = null
        events?.setStreamHandler(null)
        events = null
        stopListening()
    }

    // MARK: - Events

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sink: (Map<String, Any?>) -> Unit = { events.success(it) }
        this.sink = sink
        Calls.streamSink = sink
    }

    override fun onCancel(arguments: Any?) = stopListening()

    /** Another engine (a background isolate) may be the one listening. */
    private fun stopListening() {
        if (Calls.streamSink === sink) Calls.streamSink = null
        sink = null
    }

    // MARK: - Activity: lock screen and the full-screen intent permission

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attach(binding)
    override fun onDetachedFromActivityForConfigChanges() = detach()
    override fun onDetachedFromActivity() = detach()

    private fun attach(binding: ActivityPluginBinding) {
        this.binding = binding
        activity = binding.activity
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
        Calls.onCallsChanged = { if (!Calls.hasLiveCalls()) setOverLockScreen(false) }
        openedForCall(binding.activity.intent)
    }

    private fun detach() {
        binding?.removeOnNewIntentListener(this)
        binding?.removeActivityResultListener(this)
        binding = null
        activity = null
        overLockScreen = false
        Calls.onCallsChanged = null
        pendingFullScreen?.invoke(CallMethodHandler.canUseFullScreenIntent(activityContext() ?: return))
        pendingFullScreen = null
    }

    private fun activityContext() = activity?.applicationContext

    override fun onNewIntent(intent: Intent): Boolean {
        openedForCall(intent)
        return false
    }

    /**
     * Opened by a call (its full-screen intent, a tap, Answer): the activity
     * shows over the lock screen and turns the screen on until the calls end.
     * The core consumes its own extras; the call's mark stays.
     */
    private fun openedForCall(intent: Intent?) {
        val callId = intent?.getStringExtra(CallKeys.EXTRA_CALL_ID) ?: return
        intent.removeExtra(CallKeys.EXTRA_CALL_ID)
        val entry = Calls.entry(callId)
        if (entry == null && Calls.hasLiveCalls()) return
        setOverLockScreen(true)
    }

    private fun setOverLockScreen(on: Boolean) {
        val activity = activity ?: return
        if (overLockScreen == on) return
        overLockScreen = on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            activity.setShowWhenLocked(on)
            activity.setTurnScreenOn(on)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (on) activity.window.addFlags(flags) else activity.window.clearFlags(flags)
        }
    }

    private fun requestFullScreenIntent(answer: (Boolean) -> Unit) {
        val activity = activity
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE || activity == null) {
            answer(activity?.let { CallMethodHandler.canUseFullScreenIntent(it) } ?: false)
            return
        }
        try {
            pendingFullScreen?.invoke(CallMethodHandler.canUseFullScreenIntent(activity))
            pendingFullScreen = answer
            activity.startActivityForResult(
                Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                    Uri.fromParts("package", activity.packageName, null)
                ),
                REQUEST_FULL_SCREEN_INTENT
            )
        } catch (e: Exception) {
            pendingFullScreen = null
            answer(CallMethodHandler.canUseFullScreenIntent(activity))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_FULL_SCREEN_INTENT) return false
        val activity = activity ?: return true
        pendingFullScreen?.invoke(CallMethodHandler.canUseFullScreenIntent(activity))
        pendingFullScreen = null
        return true
    }

    companion object {
        /** Localization is 100 (outermost), media / chat 50, scheduling 10 (innermost). */
        const val PRIORITY = 60
        private const val REQUEST_FULL_SCREEN_INTENT = 0x0CA11
        @Volatile private var installed = false

        /** Puts the decorator in the core's chain, once per process. */
        @Synchronized
        fun install() {
            if (installed) return
            installed = true
            NotificationBuilderRegistry.register(priority = PRIORITY) { inner -> CallBuilder(inner) }
            CancelInterceptorRegistry.register(Calls.cancelInterceptor)
        }
    }
}
