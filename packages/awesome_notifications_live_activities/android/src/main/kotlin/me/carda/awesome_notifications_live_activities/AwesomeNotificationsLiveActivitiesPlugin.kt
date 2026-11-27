package me.carda.awesome_notifications_live_activities

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.CancelInterceptorRegistry
import me.carda.android_awn_core.NotificationBuilderRegistry

/**
 * Live activities decorator plugin (Android). Installs the [LiveBuilder] in
 * the core's decorator chain, answers the AwesomeNotificationsLiveActivities
 * methods through the core's channel and streams the activities' state
 * changes on its own EventChannel.
 */
class AwesomeNotificationsLiveActivitiesPlugin :
    FlutterPlugin,
    ActivityAware,
    EventChannel.StreamHandler,
    PluginRegistry.ActivityResultListener {

    private var appContext: android.content.Context? = null
    private var methodHandler: LiveMethodHandler? = null
    private var events: EventChannel? = null
    private var sink: ((Map<String, Any?>) -> Unit)? = null

    private var binding: ActivityPluginBinding? = null
    private var activity: Activity? = null
    private var pendingPermission: ((Boolean) -> Unit)? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        install()
        val context = binding.applicationContext
        appContext = context
        methodHandler = LiveMethodHandler(context) { answer -> requestPermission(answer) }.also {
            AwesomeMethodHandlerRegistry.register(it)
        }
        events = EventChannel(binding.binaryMessenger, LiveKeys.EVENTS_CHANNEL).also {
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
        LiveActivities.streamSink = sink
    }

    override fun onCancel(arguments: Any?) = stopListening()

    /** Another engine (a background isolate) may be the one listening. */
    private fun stopListening() {
        if (LiveActivities.streamSink === sink) LiveActivities.streamSink = null
        sink = null
    }

    // MARK: - Activity: the live notifications permission

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attach(binding)
    override fun onDetachedFromActivityForConfigChanges() = detach()
    override fun onDetachedFromActivity() = detach()

    private fun attach(binding: ActivityPluginBinding) {
        this.binding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    private fun detach() {
        binding?.removeActivityResultListener(this)
        binding = null
        activity = null
        pendingPermission?.invoke(appContext?.let { LiveMethodHandler.areEnabled(it) } ?: false)
        pendingPermission = null
    }

    /** Android 16+: opens the app's "Live notifications" settings; answers when the user is back. */
    private fun requestPermission(answer: (Boolean) -> Unit) {
        val activity = activity
        if (android.os.Build.VERSION.SDK_INT < LiveNotifications.PROMOTED_SDK || activity == null) {
            answer(appContext?.let { LiveMethodHandler.areEnabled(it) } ?: false)
            return
        }
        try {
            pendingPermission?.invoke(LiveMethodHandler.areEnabled(activity))
            pendingPermission = answer
            activity.startActivityForResult(
                Intent(ACTION_PROMOTION_SETTINGS).apply {
                    putExtra(EXTRA_APP_PACKAGE, activity.packageName)
                    data = Uri.fromParts("package", activity.packageName, null)
                },
                REQUEST_PROMOTION
            )
        } catch (e: Exception) {
            pendingPermission = null
            answer(LiveMethodHandler.areEnabled(activity))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PROMOTION) return false
        val activity = activity ?: return true
        pendingPermission?.invoke(LiveMethodHandler.areEnabled(activity))
        pendingPermission = null
        return true
    }

    companion object {
        /** Localization is 100 (outermost), calls 60, media / chat 50, scheduling 10 (innermost). */
        const val PRIORITY = 55
        private const val REQUEST_PROMOTION = 0x0A11
        /** Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS (API 36). */
        private const val ACTION_PROMOTION_SETTINGS = "android.settings.APP_NOTIFICATION_PROMOTION_SETTINGS"
        /** Settings.EXTRA_APP_PACKAGE. */
        private const val EXTRA_APP_PACKAGE = "android.provider.extra.APP_PACKAGE"
        @Volatile private var installed = false

        /** Puts the decorator in the core's chain, once per process. */
        @Synchronized
        fun install() {
            if (installed) return
            installed = true
            NotificationBuilderRegistry.register(priority = PRIORITY) { inner -> LiveBuilder(inner) }
            CancelInterceptorRegistry.register(LiveActivities.cancelInterceptor)
        }
    }
}
