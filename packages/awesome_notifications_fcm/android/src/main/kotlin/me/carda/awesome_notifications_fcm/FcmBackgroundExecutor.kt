package me.carda.awesome_notifications_fcm

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Runs the Dart silent-data handler in a headless background isolate.
 *
 * When a silent (data-only) push arrives while no Flutter UI engine is attached
 * (app terminated), this spins up a dedicated [FlutterEngine] executing the
 * `silentPushBackgroundMain` entry point (looked up from the stored callback
 * handle) and drains a queue of silent messages over the `AWFcmReverse` channel,
 * one at a time, then tears the engine down.
 */
object FcmBackgroundExecutor : MethodChannel.MethodCallHandler {

    private val queue = ConcurrentLinkedQueue<Map<String, Any?>>()
    private val isRunning = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var silentCallbackHandle: Long = 0L
    private var appContext: Context? = null

    /** Enqueues one silent message and starts the isolate if it is not running. */
    fun enqueue(context: Context, silentData: SilentDataModel) {
        appContext = context.applicationContext
        silentCallbackHandle = FcmDefaultsManager.getSilentCallbackHandle(context)
        val dartHandle = FcmDefaultsManager.getDartBackgroundHandle(context)
        if (dartHandle == 0L || silentCallbackHandle == 0L) return // never initialized

        queue.add(silentData.toMap())
        if (isRunning.compareAndSet(false, true)) {
            mainHandler.post { startIsolate(dartHandle) }
        }
    }

    private fun startIsolate(dartCallbackHandle: Long) {
        val context = appContext ?: return
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationCompleteAsync(context, null, mainHandler) {
            val callbackInfo =
                FlutterCallbackInformation.lookupCallbackInformation(dartCallbackHandle)
            if (callbackInfo == null) {
                isRunning.set(false)
                return@ensureInitializationCompleteAsync
            }
            val flutterEngine = FlutterEngine(context)
            engine = flutterEngine
            val executor = flutterEngine.dartExecutor
            channel = MethodChannel(executor, FcmDefinitions.DART_FCM_REVERSE_CHANNEL).also {
                it.setMethodCallHandler(this)
            }
            executor.executeDartCallback(
                DartExecutor.DartCallback(
                    context.assets,
                    loader.findAppBundlePath(),
                    callbackInfo
                )
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // The isolate is ready (or finished the previous item): send the next.
            FcmDefinitions.CHANNEL_METHOD_PUSH_NEXT_DATA -> {
                result.success(true)
                dischargeNext()
            }
            else -> result.notImplemented()
        }
    }

    private fun dischargeNext() {
        val next = queue.poll()
        if (next == null) {
            closeIsolate()
            return
        }
        val payload = HashMap(next).apply {
            put(FcmDefinitions.SILENT_HANDLE, silentCallbackHandle)
        }
        mainHandler.post {
            channel?.invokeMethod(
                FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK,
                payload,
                object : MethodChannel.Result {
                    override fun success(r: Any?) = dischargeNext()
                    override fun error(c: String, m: String?, d: Any?) = dischargeNext()
                    override fun notImplemented() = dischargeNext()
                }
            )
        }
    }

    private fun closeIsolate() {
        mainHandler.post {
            channel?.setMethodCallHandler(null)
            channel = null
            engine?.destroy()
            engine = null
            isRunning.set(false)
            // A message may have arrived between the empty poll and teardown.
            if (queue.isNotEmpty()) {
                val handle = appContext?.let { FcmDefaultsManager.getDartBackgroundHandle(it) } ?: 0L
                if (handle != 0L && isRunning.compareAndSet(false, true)) startIsolate(handle)
            }
        }
    }
}
