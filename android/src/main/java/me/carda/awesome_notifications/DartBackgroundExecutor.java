package me.carda.awesome_notifications;

import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.atomic.AtomicBoolean;

import androidx.annotation.NonNull;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.FlutterCallbackInformation;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.background.AwesomeBackgroundExecutor;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.managers.LifeCycleManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;

/**
 * An background execution abstraction which handles initializing a background isolate running a
 * callback dispatcher, used to invoke Dart callbacks while backgrounded.
 */
public class DartBackgroundExecutor extends AwesomeBackgroundExecutor implements MethodCallHandler {
    private static final String TAG = "DartBackgroundExec";

    private static final BlockingQueue<Intent> silentDataQueue = new LinkedBlockingDeque<Intent>();

    public static Context applicationContext;

    private AtomicBoolean isRunning = null;

    private MethodChannel backgroundChannel;
    private FlutterEngine backgroundFlutterEngine;

    public boolean isDone(){
        return isRunning != null && !isRunning.get();
    }

    public boolean runBackgroundAction(
            Context context,
            Intent silentIntent
    ){
        if (dartCallbackHandle == 0) return false;
        applicationContext = context;

        addSilentIntent(silentIntent);

        if (isRunning == null){
            isRunning = new AtomicBoolean(true);
            runBackgroundThread(dartCallbackHandle);
        }

        return true;
    }

    private static io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
            pluginRegistrantCallback;

    /**
     * Sets the {@code io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback} used to
     * register plugins with the newly spawned isolate.
     *
     * <p>Note: this is only necessary for applications using the V1 engine embedding API as plugins
     * are automatically registered via reflection in the V2 engine embedding API. If not set,
     * background message callbacks will not be able to utilize functionality from other plugins.
     */
    public static void setPluginRegistrant(
            io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback callback) {
        pluginRegistrantCallback = callback;
    }

    private static void addSilentIntent(Intent intent){
        silentDataQueue.add(intent);
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
        String method = call.method;
        try {
            if (method.equals(Definitions.CHANNEL_METHOD_INITIALIZE)) {
                dischargeNextSilentExecution();
                result.success(true);
            } else {
                result.notImplemented();
            }
        } catch (Exception e) {
            result.error("error", "Dart background error: " + e.getMessage(), null);
        }
    }

    public void runBackgroundThread(final Long callbackHandle) {

        if (backgroundFlutterEngine != null) {
            Log.e(TAG, "Background isolate already started.");
            return;
        }

        // giving time to debug attach (only for tests)
//        try {
//            Thread.sleep(4000);
//        } catch (InterruptedException e) {
//            e.printStackTrace();
//        }

        Handler handler = new Handler(Looper.getMainLooper());
        Runnable dartBgRunnable =
                new Runnable() {
                    @Override
                    public void run() {

                        Log.i(TAG, "Initializing Flutter global instance.");

                        FlutterInjector.instance().flutterLoader().startInitialization(applicationContext.getApplicationContext());
                        FlutterInjector.instance().flutterLoader().ensureInitializationCompleteAsync(
                                applicationContext.getApplicationContext(),
                                null,
                                handler,
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        String appBundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath();
                                        AssetManager assets = applicationContext.getApplicationContext().getAssets();

                                        Log.i(TAG, "Creating background FlutterEngine instance.");
                                        backgroundFlutterEngine =
                                                new FlutterEngine(applicationContext.getApplicationContext());

                                        // We need to create an instance of `FlutterEngine` before looking up the
                                        // callback. If we don't, the callback cache won't be initialized and the
                                        // lookup will fail.
                                        FlutterCallbackInformation flutterCallback =
                                                FlutterCallbackInformation.lookupCallbackInformation(callbackHandle);

                                        DartExecutor executor = backgroundFlutterEngine.getDartExecutor();
                                        DartBackgroundExecutor.this.initializeReverseMethodChannel(executor);

                                        // The pluginRegistrantCallback should only be set in the V1 embedding as
                                        // plugin registration is done via reflection in the V2 embedding.
                                        if (pluginRegistrantCallback != null) {
                                            pluginRegistrantCallback.registerWith(
                                                    new ShimPluginRegistry(backgroundFlutterEngine));
                                        }

                                        Log.i(TAG, "Executing background FlutterEngine instance.");
                                        DartCallback dartCallback =
                                                new DartCallback(assets, appBundlePath, flutterCallback);
                                        executor.executeDartCallback(dartCallback);
                                    }
                                });

                    }
                };

        handler.post(dartBgRunnable);
    }

    private void initializeReverseMethodChannel(BinaryMessenger isolate) {
        backgroundChannel = new MethodChannel(isolate, Definitions.DART_REVERSE_CHANNEL);
        backgroundChannel.setMethodCallHandler(this);
    }

    public void closeBackgroundIsolate() {
        if (!isDone()) {

            isRunning.set(false);

            Handler handler = new Handler(Looper.getMainLooper());
            Runnable dartBgRunnable =
                    new Runnable() {
                        @Override
                        public void run() {

                            Log.i(TAG, "Shutting down background FlutterEngine instance.");

                            if (backgroundFlutterEngine != null) {
                                backgroundFlutterEngine.destroy();
                                backgroundFlutterEngine = null;
                            }

                        }
                    };

            handler.post(dartBgRunnable);
        }
    }

    public void dischargeNextSilentExecution(){
        if (!silentDataQueue.isEmpty()) {
            try {
                Intent intent = silentDataQueue.take();
                executeDartCallbackInBackgroundIsolate(intent);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        else {
            closeBackgroundIsolate();
        }
    }

    private void finishDartBackgroundExecution(){
        if(silentDataQueue.isEmpty()) {
            if(AwesomeNotifications.debug)
                Log.i(TAG, "All silent data fetched.");
            closeBackgroundIsolate();
        }
        else {
            if (AwesomeNotifications.debug)
                Log.i(TAG, "Remaining " + silentDataQueue.size() + " silents to finish");
            dischargeNextSilentExecution();
        }
    }

    private final Result dartChannelResultHandle =
        new Result() {
            @Override
            public void success(Object result) {
                finishDartBackgroundExecution();
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                finishDartBackgroundExecution();
            }

            @Override
            public void notImplemented() {
                finishDartBackgroundExecution();
            }
        };

    public void executeDartCallbackInBackgroundIsolate(Intent intent) {

        if (backgroundFlutterEngine == null) {
            Log.i( TAG,"A background message could not be handled since " +
                    "dart callback handler has not been registered.");
            return;
        }

        ActionReceived actionReceived =
                NotificationBuilder
                        .getNewBuilder()
                        .buildNotificationActionFromIntent(
                                applicationContext,
                                intent,
                                LifeCycleManager.getApplicationLifeCycle());

        // If this intent contains a valid awesome action
        if(actionReceived != null){

            final Map<String, Object> actionData = actionReceived.toMap();
            actionData.put(Definitions.ACTION_HANDLE, silentCallbackHandle);

            // Handle the message event in Dart.
            backgroundChannel.invokeMethod(
                Definitions.CHANNEL_METHOD_SILENCED_CALLBACK,
                actionData,
                dartChannelResultHandle);

        } else {
            Log.e(TAG, "Action Notification model not found inside Intent content.");
            finishDartBackgroundExecution();
        }
    }
}