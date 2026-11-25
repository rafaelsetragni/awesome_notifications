package me.carda.awesome_notifications

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
import me.carda.android_awn_core.BackgroundActions

/**
 * Runs the app's `onActionReceivedMethod` in a headless background isolate,
 * as 0.12 did, for an action that arrives while no app is listening (app
 * killed) or that must always run in the background (`SilentBackgroundAction`).
 *
 * Starts a [FlutterEngine] on the `dartIsolateMain` entry point and drains the
 * queued actions over the `awesome_notifications_reverse` channel, one at a
 * time, then tears the engine down.
 */
object ActionBackgroundExecutor : MethodChannel.MethodCallHandler, BackgroundActions.Executor {

    private const val REVERSE_CHANNEL = "awesome_notifications_reverse"
    private const val METHOD_PUSH_NEXT = "pushNext"
    private const val METHOD_SILENT_CALLBACK = "silentCallbackReference"

    private class Pending(val action: Map<String, Any?>, val done: () -> Unit)

    private val queue = ConcurrentLinkedQueue<Pending>()
    private val isRunning = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    override fun execute(context: Context, action: Map<String, Any?>, done: () -> Unit) {
        appContext = context.applicationContext
        val entryPoint = ActionHandles.get(context, ActionHandles.BACKGROUND_HANDLE)
        val handler = ActionHandles.get(context, ActionHandles.ACTION_HANDLE)
        if (entryPoint == 0L || handler == 0L) { // the app never set its listeners
            done()
            return
        }
        queue.add(Pending(action + (ActionHandles.ACTION_HANDLE to handler), done))
        if (isRunning.compareAndSet(false, true)) {
            mainHandler.post { startIsolate(entryPoint) }
        }
    }

    private fun startIsolate(entryPoint: Long) {
        val context = appContext ?: return failAll()
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationCompleteAsync(context, null, mainHandler) {
            val callback = FlutterCallbackInformation.lookupCallbackInformation(entryPoint)
                ?: return@ensureInitializationCompleteAsync failAll()
            val flutterEngine = FlutterEngine(context)
            engine = flutterEngine
            channel = MethodChannel(flutterEngine.dartExecutor, REVERSE_CHANNEL).also {
                it.setMethodCallHandler(this)
            }
            flutterEngine.dartExecutor.executeDartCallback(
                DartExecutor.DartCallback(context.assets, loader.findAppBundlePath(), callback))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // The isolate is ready: send the first action.
            METHOD_PUSH_NEXT -> {
                result.success(true)
                dischargeNext()
            }
            else -> result.notImplemented()
        }
    }

    private fun dischargeNext() {
        val next = queue.poll() ?: return closeIsolate()
        mainHandler.post {
            val finished = {
                next.done()
                dischargeNext()
            }
            channel?.invokeMethod(METHOD_SILENT_CALLBACK, HashMap(next.action), object : MethodChannel.Result {
                override fun success(r: Any?) = finished()
                override fun error(c: String, m: String?, d: Any?) = finished()
                override fun notImplemented() = finished()
            }) ?: finished()
        }
    }

    private fun failAll() {
        while (true) (queue.poll() ?: break).done()
        isRunning.set(false)
    }

    private fun closeIsolate() {
        mainHandler.post {
            channel?.setMethodCallHandler(null)
            channel = null
            engine?.destroy()
            engine = null
            isRunning.set(false)
            // An action may have arrived between the empty poll and teardown.
            if (queue.isNotEmpty() && isRunning.compareAndSet(false, true)) {
                val entryPoint = appContext?.let { ActionHandles.get(it, ActionHandles.BACKGROUND_HANDLE) } ?: 0L
                if (entryPoint != 0L) startIsolate(entryPoint) else failAll()
            }
        }
    }
}
