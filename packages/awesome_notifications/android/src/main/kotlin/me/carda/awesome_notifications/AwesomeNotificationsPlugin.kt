package me.carda.awesome_notifications

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
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
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.Definitions

/**
 * Thin Flutter bridge: translates method-channel calls into the Flutter-free
 * AndroidAwnCore engine. All notification logic lives in the core; the bridge
 * only owns the Activity-bound bits (runtime permission request).
 */
class AwesomeNotificationsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var core: AwesomeNotifications

    private var activity: Activity? = null
    private var pendingPermissionResult: Result? = null

    private val permissionRequestCode = 101010

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "awesome_notifications")
        channel.setMethodCallHandler(this)
        core = AwesomeNotifications(binding.applicationContext)
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

            "requestNotifications" -> requestNotifications(result)

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

    private fun requestNotifications(result: Result) {
        // Before Android 13 there is no runtime notification permission.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(core.isNotificationAllowed())
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.success(core.isNotificationAllowed())
            return
        }
        val granted = ContextCompat.checkSelfPermission(
            currentActivity, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
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
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
