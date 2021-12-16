package me.carda.awesome_notifications.awesome_notifications_android_core.services;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.JobIntentService;
import me.carda.awesome_notifications.awesome_notifications_android_core.background.DartBackgroundExecutor;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DefaultsManager;

public class BackgroundService extends JobIntentService {

    private static final String TAG = "BackgroundService";

    @Override
    protected void onHandleWork(@NonNull final Intent intent) {

        Log.d(TAG, "A new Dart background service has started");

        long dartCallbackHandle = getDartCallbackDispatcher(this);
        if (dartCallbackHandle == 0L) {
            Log.w(TAG, "A background message could not be handled in Dart" +
                            " because there is no onActionReceivedMethod handler registered.");
            return;
        }

        long silentCallbackHandle = getSilentCallbackDispatcher(this);
        if (silentCallbackHandle == 0L) {
            Log.w(TAG,"A background message could not be handled in Dart" +
                            " because there is no dart background handler registered.");
            return;
        }

        DartBackgroundExecutor.runBackgroundExecutor(
                this,
                intent,
                dartCallbackHandle,
                silentCallbackHandle);
    }

    public static long getDartCallbackDispatcher(Context context){
        return DefaultsManager.getDartCallbackDispatcher(context);
    }

    public static long getSilentCallbackDispatcher(Context context){
        return DefaultsManager.getSilentCallbackDispatcher(context);
    }

    /**
     * Sets the {@link io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback} used to
     * register the plugins used by an application with the newly spawned background isolate.
     *
     * <p>This should be invoked in {@link MainApplication.onCreate} with {@link
     * GeneratedPluginRegistrant} in applications using the V1 embedding API in order to use other
     * plugins in the background isolate. For applications using the V2 embedding API, it is not
     * necessary to set a {@link io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback} as
     * plugins are registered automatically.
     */
    @SuppressWarnings({"deprecation", "JavadocReference"})
    public static void setPluginRegistrant(
            io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback callback) {
        // Indirectly set in FlutterFirebaseMessagingBackgroundExecutor for backwards compatibility.
        DartBackgroundExecutor.setPluginRegistrant(callback);
    }
}