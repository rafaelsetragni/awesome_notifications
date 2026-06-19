package me.carda.awesome_notifications

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.TimeZone
import me.carda.android_awn_core.AwesomeEventSink
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.MapJson

/**
 * Thin Flutter bridge: translates method-channel calls into the Flutter-free
 * AndroidAwnCore engine. All notification logic lives in the core; the bridge
 * only owns the Activity-bound bits (runtime permission request).
 */
class AwesomeNotificationsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.NewIntentListener {

    private lateinit var channel: MethodChannel
    private lateinit var core: AwesomeNotifications

    private val mainHandler = Handler(Looper.getMainLooper())

    private var activity: Activity? = null
    private var pendingPermissionResult: Result? = null
    private var pendingRequestedPermissions: List<String> = emptyList()

    private val permissionRequestCode = 101010

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "awesome_notifications")
        channel.setMethodCallHandler(this)
        core = AwesomeNotifications(binding.applicationContext)

        // Forward core lifecycle events (created/displayed/tap/dismiss) to Dart,
        // always on the main thread.
        AwesomeEventSink.emitter = { eventName, data ->
            mainHandler.post { channel.invokeMethod(eventName, data) }
        }
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<String, Any?>
                val channels =
                    (args?.get(Definitions.INITIALIZE_CHANNELS) as? List<Map<String, Any?>>)
                        ?: emptyList()
                core.initialize(channels)
                result.success(true)
            }

            "getLocalTimeZoneIdentifier" -> result.success(TimeZone.getDefault().id)
            "getUtcTimeZoneIdentifier" -> result.success("UTC")

            "isNotificationAllowed" -> result.success(core.isNotificationAllowed())

            "requestNotifications" -> {
                val args = call.arguments as? Map<String, Any?>
                val requested =
                    (args?.get(Definitions.PERMISSIONS) as? List<String>) ?: emptyList()
                requestNotifications(requested, result)
            }

            "setNotificationChannel" -> {
                (call.arguments as? Map<String, Any?>)?.let { core.setChannel(it) }
                result.success(true)
            }

            "createNewNotification" -> {
                val data = call.arguments as? Map<String, Any?>
                result.success(if (data != null) core.createNotification(data) else false)
            }

            "dismissNotification" -> {
                AwesomeNotifications.readInt(call.arguments)?.let { core.dismiss(it) }
                result.success(true)
            }

            "cancelNotification" -> {
                AwesomeNotifications.readInt(call.arguments)?.let { core.cancel(it) }
                result.success(true)
            }

            "dismissAllNotifications" -> { core.dismissAll(); result.success(true) }
            "cancelAllNotifications" -> { core.cancelAll(); result.success(true) }

            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

            else -> result.notImplemented()
        }
    }

    // Dart expects back the list of permissions still MISSING after the request
    // (empty list = everything granted).
    private fun requestNotifications(requested: List<String>, result: Result) {
        fun missing(): List<String> =
            if (core.isNotificationAllowed()) emptyList() else requested

        // Before Android 13 there is no runtime notification permission.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(missing())
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.success(missing())
            return
        }
        val granted = ContextCompat.checkSelfPermission(
            currentActivity, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(emptyList<String>())
            return
        }
        pendingPermissionResult = result
        pendingRequestedPermissions = requested
        currentActivity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS), permissionRequestCode
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != permissionRequestCode) return false
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(
            if (granted) emptyList<String>() else pendingRequestedPermissions
        )
        pendingPermissionResult = null
        pendingRequestedPermissions = emptyList()
        return true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        AwesomeEventSink.emitter = null
    }

    // MARK: - Notification tap (defaultAction)

    override fun onNewIntent(intent: Intent): Boolean {
        handleNotificationIntent(intent)
        return false
    }

    /** Emits a defaultAction when the app is (re)opened by tapping a notification. */
    private fun handleNotificationIntent(intent: Intent) {
        if (intent.action != Definitions.ACTION_SELECT_NOTIFICATION) return
        val json = intent.getStringExtra(Definitions.NOTIFICATION_JSON) ?: return
        val content = MapJson.fromJson(json)
        AwesomeEventSink.emit(
            Definitions.EVENT_DEFAULT_ACTION,
            content + mapOf(
                Definitions.ACTION_TYPE to "Default",
                Definitions.ACTION_LIFECYCLE to "Foreground"
            )
        )
        // Consume so it is not re-emitted on the next attach / config change.
        intent.removeExtra(Definitions.NOTIFICATION_JSON)
        intent.action = null
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
        // Cold start: the app may have been launched by tapping a notification.
        activity?.intent?.let { handleNotificationIntent(it) }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
