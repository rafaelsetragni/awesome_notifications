package me.carda.awesome_notifications.awesome_notifications_core.services;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.awesome_notifications_core.logs.Logger;

import androidx.annotation.NonNull;
import androidx.core.app.JobIntentService;
import me.carda.awesome_notifications.awesome_notifications_core.background.BackgroundExecutor;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.managers.DefaultsManager;

public class BackgroundService extends JobIntentService {

    private static final String TAG = "BackgroundService";

    @Override
    protected void onHandleWork(@NonNull final Intent intent) {

        Logger.d(TAG, "A new Dart background service has started");

        Long dartCallbackHandle = getDartCallbackDispatcher(this);
        if (dartCallbackHandle == 0L) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.BACKGROUND_EXECUTION_EXCEPTION,
                            "A background message could not be handled in Dart" +
                            " because there is no onActionReceivedMethod handler registered.");
            return;
        }

        Long silentCallbackHandle = getSilentCallbackDispatcher(this);
        if (silentCallbackHandle == 0L) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.BACKGROUND_EXECUTION_EXCEPTION,
                            "A background message could not be handled in Dart" +
                            " because there is no dart background handler registered.");
            return;
        }

        try {
            BackgroundExecutor.runBackgroundExecutor(
                    this,
                    intent,
                    dartCallbackHandle,
                    silentCallbackHandle);
        } catch (AwesomeNotificationsException e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.BACKGROUND_EXECUTION_EXCEPTION,
                            "A new Dart background service could not be executed");
        }
    }

    public static Long getDartCallbackDispatcher(Context context){
        return DefaultsManager.getDartCallbackDispatcher(context);
    }

    public static Long getSilentCallbackDispatcher(Context context){
        return DefaultsManager.getSilentCallbackDispatcher(context);
    }
}