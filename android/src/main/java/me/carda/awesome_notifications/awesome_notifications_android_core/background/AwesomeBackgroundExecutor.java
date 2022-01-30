package me.carda.awesome_notifications.awesome_notifications_android_core.background;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DefaultsManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public abstract class AwesomeBackgroundExecutor {

    private static AwesomeBackgroundExecutor runningInstance;

    protected Long dartCallbackHandle = 0L;
    protected Long silentCallbackHandle = 0L;

    private static Class<? extends AwesomeBackgroundExecutor> awesomeBackgroundExecutorClass;

    public static void setBackgroundExecutorClass (
            Class<? extends AwesomeBackgroundExecutor> awesomeBackgroundExecutorClass
    ){
        AwesomeBackgroundExecutor.awesomeBackgroundExecutorClass =
                awesomeBackgroundExecutorClass;
    }

    public abstract boolean isDone();
    public abstract boolean runBackgroundAction(Context context, Intent silentIntent);

    public static void runBackgroundExecutor(
        Context context,
        Intent silentIntent,
        Long dartCallbackHandle,
        Long silentCallbackHandle
    ) throws AwesomeNotificationException {

        try {

            if(awesomeBackgroundExecutorClass == null)
                throw new AwesomeNotificationException(
                        "There is no valid background executor available to run.");

            if(runningInstance == null || runningInstance.isDone()) {

                runningInstance =
                        awesomeBackgroundExecutorClass.newInstance();

                runningInstance.dartCallbackHandle = dartCallbackHandle;
                runningInstance.silentCallbackHandle = silentCallbackHandle;
            }

            if(!runningInstance.runBackgroundAction(
                    context,
                    silentIntent
            )){
                runningInstance = null;
                throw new AwesomeNotificationException(
                        "The background executor could not be started.");
            }

        } catch (IllegalAccessException | InstantiationException e) {
            e.printStackTrace();
        }
    }
}
