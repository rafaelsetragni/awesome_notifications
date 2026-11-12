package me.carda.awesome_notifications_fcm

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter bridge for the FCM decorator. Owns the `awesome_notifications_fcm`
 * method channel and the Firebase token / topic operations, and forwards token
 * refreshes and (foreground) silent data from the [FcmEventsReceiver] to Dart.
 *
 * Notification display is NOT handled here — it happens natively in
 * [AwnFcmService], which posts through the shared awesome_notifications engine.
 */
class AwesomeNotificationsFcmPlugin :
    FlutterPlugin,
    MethodCallHandler,
    FcmEventsReceiver.TokenListener,
    FcmEventsReceiver.SilentListener {

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    private var silentHandle: Long = 0L

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, FcmDefinitions.CHANNEL_FLUTTER_PLUGIN)
        channel.setMethodCallHandler(this)
        FcmEventsReceiver.subscribeToken(this)
        FcmEventsReceiver.subscribeSilent(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        FcmEventsReceiver.unsubscribeToken(this)
        FcmEventsReceiver.unsubscribeSilent(this)
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            FcmDefinitions.CHANNEL_METHOD_INITIALIZE -> {
                val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                val debug = args[FcmDefinitions.DEBUG_MODE] as? Boolean ?: false
                val dartBgHandle = (args[FcmDefinitions.DART_BG_HANDLE] as? Number)?.toLong()
                silentHandle = (args[FcmDefinitions.SILENT_HANDLE] as? Number)?.toLong() ?: 0L
                FcmDefaultsManager.saveHandles(applicationContext, dartBgHandle, silentHandle, debug)
                // Deliver the current token so the app has it right after init.
                requestAndDeliverToken()
                result.success(true)
            }

            FcmDefinitions.CHANNEL_METHOD_IS_FCM_AVAILABLE ->
                result.success(FirebaseApp.getApps(applicationContext).isNotEmpty())

            FcmDefinitions.CHANNEL_METHOD_GET_FCM_TOKEN -> {
                firebaseMessaging()?.token
                    ?.addOnCompleteListener { task ->
                        result.success(if (task.isSuccessful) task.result ?: "" else "")
                    } ?: result.success("")
            }

            FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC -> {
                val topic = (call.arguments as? Map<String, Any?>)
                    ?.get(FcmDefinitions.NOTIFICATION_TOPIC) as? String
                if (topic == null) { result.success(false); return }
                firebaseMessaging()?.subscribeToTopic(topic)
                    ?.addOnCompleteListener { result.success(it.isSuccessful) }
                    ?: result.success(false)
            }

            FcmDefinitions.CHANNEL_METHOD_UNSUBSCRIBE_TOPIC -> {
                val topic = (call.arguments as? Map<String, Any?>)
                    ?.get(FcmDefinitions.NOTIFICATION_TOPIC) as? String
                if (topic == null) { result.success(false); return }
                firebaseMessaging()?.unsubscribeFromTopic(topic)
                    ?.addOnCompleteListener { result.success(it.isSuccessful) }
                    ?: result.success(false)
            }

            FcmDefinitions.CHANNEL_METHOD_DELETE_TOKEN -> {
                firebaseMessaging()?.deleteToken()
                    ?.addOnCompleteListener { result.success(it.isSuccessful) }
                    ?: result.success(false)
            }

            else -> result.notImplemented()
        }
    }

    // MARK: - FcmEventsReceiver listeners

    override fun onNewFcmToken(token: String?) {
        mainHandler.post {
            channel.invokeMethod(FcmDefinitions.CHANNEL_METHOD_NEW_FCM_TOKEN, token)
        }
    }

    override fun onNewNativeToken(token: String?) {
        mainHandler.post {
            channel.invokeMethod(FcmDefinitions.CHANNEL_METHOD_NEW_NATIVE_TOKEN, token)
        }
    }

    override fun onSilentData(silentData: SilentDataModel): Boolean {
        val payload = HashMap(silentData.toMap()).apply {
            put(FcmDefinitions.SILENT_HANDLE, silentHandle)
        }
        mainHandler.post {
            channel.invokeMethod(FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK, payload)
        }
        return true
    }

    // MARK: - Helpers

    private fun firebaseMessaging(): FirebaseMessaging? =
        if (FirebaseApp.getApps(applicationContext).isEmpty()) null
        else FirebaseMessaging.getInstance()

    private fun requestAndDeliverToken() {
        firebaseMessaging()?.token?.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                task.result?.let { token ->
                    FcmDefaultsManager.setLastToken(applicationContext, token)
                    onNewFcmToken(token)
                }
            }
        }
    }
}
