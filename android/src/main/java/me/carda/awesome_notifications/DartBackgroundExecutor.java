package me.carda.awesome_notifications;

import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.FlutterCallbackInformation;
import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.background.BackgroundExecutor;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.LifeCycleManager;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;

/**
 * An background execution abstraction which handles initializing a background isolate running a
 * callback dispatcher, used to invoke Dart callbacks while backgrounded.
 */
public class DartBackgroundExecutor extends BackgroundExecutor implements MethodCallHandler {
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
            if (method.equals(Definitions.CHANNEL_METHOD_PUSH_NEXT_DATA)) {
                dischargeNextSilentExecution();
                result.success(true);
            } else {
                result.notImplemented();
            }
        } catch (Exception e) {
            AwesomeNotificationsException awesomeException =
                ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                            "An unexpected exception was found in a silent background execution",
                            ExceptionCode.DETAILED_UNEXPECTED_ERROR);
            result.error(
                    awesomeException.getCode(),
                    awesomeException.getMessage(),
                    awesomeException.getDetailedCode());
        }
    }

    public void runBackgroundThread(final Long callbackHandle) {

        if (backgroundFlutterEngine != null) {
            Logger.e(TAG, "Background isolate already started.");
            return;
        }

        // giving time to debug attach (only for tests)
//        try {
//            Thread.sleep(4000);
//        } catch (InterruptedException e) {
//            e.printStackTrace();
//        }

        final Handler handler = new Handler(Looper.getMainLooper());
        Runnable dartBgRunnable =
                new Runnable() {
                    @Override
                    public void run() {

                        Logger.i(TAG, "Initializing Flutter global instance.");

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

                                        Logger.i(TAG, "Creating background FlutterEngine instance.");
                                        backgroundFlutterEngine =
                                                new FlutterEngine(applicationContext.getApplicationContext());

                                        // We need to create an instance of `FlutterEngine` before looking up the
                                        // callback. If we don't, the callback cache won't be initialized and the
                                        // lookup will fail.
                                        FlutterCallbackInformation flutterCallback =
                                                FlutterCallbackInformation.lookupCallbackInformation(callbackHandle);

                                        if (flutterCallback == null){
                                            ExceptionFactory
                                                    .getInstance()
                                                    .registerNewAwesomeException(
                                                            TAG,
                                                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                                                            "The flutter background reference for dart background action is invalid",
                                                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".FlutterCallbackInformation");
                                        }
                                        else {
                                            DartExecutor executor = backgroundFlutterEngine.getDartExecutor();
                                            initializeReverseMethodChannel(executor);

                                            Logger.i(TAG, "Executing background FlutterEngine instance.");
                                            DartCallback dartCallback =
                                                    new DartCallback(assets, appBundlePath, flutterCallback);
                                            executor.executeDartCallback(dartCallback);
                                        }
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
                            Logger.i(TAG, "Shutting down background FlutterEngine instance.");

                            if (backgroundFlutterEngine != null) {
                                backgroundFlutterEngine.destroy();
                                backgroundFlutterEngine = null;
                            }

                            Logger.i(TAG, "FlutterEngine instance terminated.");
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
                ExceptionFactory
                        .getInstance()
                        .registerNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_BACKGROUND_EXECUTION_EXCEPTION,
                                ExceptionCode.DETAILED_UNEXPECTED_ERROR+".background.silentExecution",
                                e);
            }
        }
        else {
            closeBackgroundIsolate();
        }
    }

    private void finishDartBackgroundExecution(){
        if(silentDataQueue.isEmpty()) {
            if(AwesomeNotifications.debug)
                Logger.i(TAG, "All silent data fetched.");
            closeBackgroundIsolate();
        }
        else {
            if (AwesomeNotifications.debug)
                Logger.i(TAG, "Remaining " + silentDataQueue.size() + " silents to finish");
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

    public void executeDartCallbackInBackgroundIsolate(Intent intent) throws AwesomeNotificationsException {

        if (backgroundFlutterEngine == null) {
            Logger.i( TAG,"A background message could not be handled since " +
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
            actionData.put(
                    Definitions.ACTION_HANDLE,
                    silentCallbackHandle);

            // Handle the message event in Dart.
            backgroundChannel.invokeMethod(
                Definitions.CHANNEL_METHOD_SILENT_CALLBACK,
                actionData,
                dartChannelResultHandle);

        } else {
            Logger.e(TAG, "Silent data model not found inside Intent content.");
            finishDartBackgroundExecution();
        }
    }
}