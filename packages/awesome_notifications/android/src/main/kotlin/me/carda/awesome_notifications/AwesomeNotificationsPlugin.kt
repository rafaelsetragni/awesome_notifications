package me.carda.awesome_notifications

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.RemoteInput
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
import me.carda.android_awn_core.ActionType
import me.carda.android_awn_core.AwesomeEventListener
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.AwesomeNotificationsException
import me.carda.android_awn_core.BackgroundActions
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.MapUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationLifeCycle

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
    PluginRegistry.NewIntentListener,
    AwesomeEventListener {

    private lateinit var channel: MethodChannel
    private lateinit var core: AwesomeNotifications
    private lateinit var appContext: Context

    private val mainHandler = Handler(Looper.getMainLooper())

    private var activity: Activity? = null
    /// The action that launched the app from a killed state (via the Activity's
    /// initial intent), if any — returned by getInitialAction.
    private var initialAction: Map<String, Any?>? = null
    private var pendingPermissionResult: Result? = null
    private var pendingRequestedPermissions: List<String> = emptyList()

    private val permissionRequestCode = 101010

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "awesome_notifications")
        channel.setMethodCallHandler(this)
        appContext = binding.applicationContext
        core = AwesomeNotifications(binding.applicationContext)
        // Also installed at process start (AwesomeNotificationsInitializer).
        BackgroundActions.executor = ActionBackgroundExecutor
    }

    // MARK: - AwesomeEventListener

    override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
        // Always deliver on the main thread.
        mainHandler.post { channel.invokeMethod(eventType, content) }
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<String, Any?>
                val channels =
                    (args?.get(Definitions.INITIALIZE_CHANNELS) as? List<Map<String, Any?>>)
                        ?: emptyList()
                val channelGroups =
                    (args?.get(Definitions.INITIALIZE_CHANNEL_GROUPS) as? List<Map<String, Any?>>)
                        ?: emptyList()
                core.initialize(
                    channels,
                    args?.get(Definitions.INITIALIZE_DEFAULT_ICON) as? String,
                    channelGroups)
                ActionHandles.save(
                    appContext, ActionHandles.BACKGROUND_HANDLE,
                    MapUtils.getInstance().getLong(args?.get(ActionHandles.BACKGROUND_HANDLE)))
                // The app is listening from now on: its events (created,
                // displayed, actions…) come here instead of a background
                // isolate. A background engine attaches the plugin too, but
                // its isolate does not initialize it.
                AwesomeEventsReceiver.subscribe(this)
                result.success(true)
            }

            "getLocalTimeZoneIdentifier" -> result.success(TimeZone.getDefault().id)
            "getUtcTimeZoneIdentifier" -> result.success(Definitions.UTC_TIMEZONE)

            "setEventHandles" -> {
                // Live events come through this channel; the action handle is
                // kept for a killed app's background isolate.
                val args = call.arguments as? Map<String, Any?>
                ActionHandles.save(
                    appContext, ActionHandles.ACTION_HANDLE,
                    MapUtils.getInstance().getLong(args?.get(ActionHandles.ACTION_HANDLE)))
                result.success(true)
            }

            "getInitialAction" -> {
                // Returns the action that launched the app (killed state), or null.
                val removeFromEvents = call.arguments as? Boolean ?: false
                val action = initialAction
                if (removeFromEvents) initialAction = null
                result.success(action)
            }

            "isNotificationAllowed" -> result.success(core.isNotificationAllowed())

            "requestNotifications" -> {
                val args = call.arguments as? Map<String, Any?>
                val requested =
                    (args?.get(Definitions.NOTIFICATION_PERMISSIONS) as? List<String>) ?: emptyList()
                requestNotifications(requested, result)
            }

            "getPermissionStatuses" -> getPermissionStatuses(call.arguments, result)

            "setNotificationChannel" -> {
                (call.arguments as? Map<String, Any?>)?.let { core.setChannel(it) }
                result.success(true)
            }

            "createNewNotification" -> {
                val data = call.arguments as? Map<String, Any?>
                if (data == null) {
                    result.success(false)
                } else {
                    // Async: builds off the main thread; the result comes back on it.
                    // A decorator may reject the model (e.g. an invalid schedule).
                    core.createNotification(
                        data,
                        onError = { code, message, details -> result.error(code, message, details) }
                    ) { created -> result.success(created) }
                }
            }

            "dismissNotification" -> {
                MapUtils.getInstance().getInt(call.arguments)?.let { core.dismiss(it) }
                result.success(true)
            }

            "cancelNotification" -> {
                MapUtils.getInstance().getInt(call.arguments)?.let { core.cancel(it) }
                result.success(true)
            }

            "dismissNotificationsByChannelKey" -> {
                (call.arguments as? String)?.let { core.dismissByChannelKey(it) }
                result.success(true)
            }
            "cancelNotificationsByChannelKey" -> {
                (call.arguments as? String)?.let { core.cancelByChannelKey(it) }
                result.success(true)
            }
            "dismissNotificationsByGroupKey" -> {
                (call.arguments as? String)?.let { core.dismissByGroupKey(it) }
                result.success(true)
            }
            "cancelNotificationsByGroupKey" -> {
                (call.arguments as? String)?.let { core.cancelByGroupKey(it) }
                result.success(true)
            }

            "dismissAllNotifications" -> { core.dismissAll(); result.success(true) }
            "cancelAllNotifications" -> { core.cancelAll(); result.success(true) }

            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

            else -> {
                // Let registered decorators (e.g. localization) answer their methods.
                val handled = AwesomeMethodHandlerRegistry.handle(
                    call.method,
                    call.arguments,
                    { value -> result.success(value) },
                    { code, message, details -> result.error(code, message, details) }
                )
                if (!handled) result.notImplemented()
            }
        }
    }

    /**
     * 0.12.1 `channelMethodGetPermissionStatuses`: args `channelKey` (String?)
     * and `permissions` (permission names); answers a map permission name →
     * `granted` / `denied` / `notDetermined` / `notSupported`. Missing args
     * fail with MISSING_ARGUMENTS, an empty list with INVALID_ARGUMENTS, an
     * unknown channel with INVALID_ARGUMENTS (`arguments.invalid.channel.key`),
     * anything else with UNKNOWN_EXCEPTION, as 0.12.1 did.
     */
    @Suppress("UNCHECKED_CAST")
    internal fun getPermissionStatuses(arguments: Any?, result: Result) {
        try {
            val args = arguments as? Map<String, Any?>
                ?: throw AwesomeNotificationsException(
                    Definitions.CODE_MISSING_ARGUMENTS,
                    "Arguments are missing",
                    Definitions.DETAILED_REQUIRED_ARGUMENTS)
            val channelKey = args[Definitions.NOTIFICATION_CHANNEL_KEY] as String?
            val permissions = args[Definitions.NOTIFICATION_PERMISSIONS] as List<String>?
            if (permissions.isNullOrEmpty())
                throw AwesomeNotificationsException(
                    Definitions.CODE_INVALID_ARGUMENTS,
                    "Permission list is required",
                    Definitions.DETAILED_REQUIRED_ARGUMENTS + ".permissionList")
            result.success(core.getPermissionStatuses(channelKey, permissions))
        } catch (e: AwesomeNotificationsException) {
            result.error(e.code, e.message, e.detailedCode)
        } catch (e: Exception) {
            result.error(
                Definitions.CODE_UNKNOWN_EXCEPTION,
                "${e.localizedMessage}",
                Definitions.DETAILED_UNEXPECTED_ERROR + "." + e.javaClass.simpleName)
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
        AwesomeEventsReceiver.unsubscribe(this)
    }

    // MARK: - Notification tap (defaultAction)

    override fun onNewIntent(intent: Intent): Boolean {
        handleNotificationIntent(intent)
        return false
    }

    /**
     * Emits an action event when the app is (re)opened by tapping a notification
     * or one of its foreground (`Default`) action buttons. Non-foreground buttons
     * never reach here — they broadcast to NotificationButtonReceiver instead.
     */
    private fun handleNotificationIntent(intent: Intent, isLaunch: Boolean = false) {
        val action = intent.action ?: return
        val isTap = action == Definitions.SELECT_NOTIFICATION
        val isButton = action.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX)
        if (!isTap && !isButton) return

        val builder = NotificationBuilder.getNewBuilder()
        val model = builder.notificationModel(intent) ?: return
        var content = builder.contentMap(model)

        val buttonKey =
            if (isButton) intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED) ?: ""
            else ""
        val button = builder.findButton(model, buttonKey)

        if (isButton) {
            // Carry the pressed key + any typed reply back to Dart.
            content = content + (Definitions.NOTIFICATION_BUTTON_KEY_PRESSED to buttonKey)
            RemoteInput.getResultsFromIntent(intent)
                ?.getCharSequence(Definitions.NOTIFICATION_BUTTON_KEY_INPUT)
                ?.let {
                    content = content + (Definitions.NOTIFICATION_BUTTON_KEY_INPUT to it.toString())
                }
            if (builder.shouldButtonAutoDismiss(button)) {
                builder.readId(content)?.let { core.dismiss(it) }
            }
        }

        val isDismiss =
            if (isButton) builder.buttonActionType(button) == ActionType.DismissAction
            else builder.isDismissAction(content)

        if (isDismiss) {
            // A notification-level DismissAction tap also removes the notification
            // (button dismissals were already handled by the auto-dismiss above).
            if (!isButton) builder.readId(content)?.let { core.dismiss(it) }
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_NOTIFICATION_DISMISSED,
                builder.registerDismissedEvent(content, NotificationLifeCycle.Foreground)
            )
        } else {
            val actionType = if (isButton) builder.buttonActionType(button) else ActionType.Default
            // A cold start from a notification tap is the initial action: capture it
            // (terminated lifecycle) so getInitialAction() can return it.
            val lifeCycle =
                if (isLaunch) NotificationLifeCycle.Terminated else NotificationLifeCycle.Foreground
            val actionEvent = builder.registerActionEvent(content, lifeCycle, actionType)
            if (isLaunch) initialAction = actionEvent
            AwesomeEventsReceiver.notifyAwesomeEvent(
                Definitions.EVENT_DEFAULT_ACTION,
                actionEvent
            )
        }
        // Consume so it is not re-emitted on the next attach / config change.
        intent.removeExtra(Definitions.NOTIFICATION_JSON)
        intent.removeExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED)
        intent.action = null
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
        // Cold start: the app may have been launched by tapping a notification.
        activity?.intent?.let { handleNotificationIntent(it, isLaunch = true) }
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
