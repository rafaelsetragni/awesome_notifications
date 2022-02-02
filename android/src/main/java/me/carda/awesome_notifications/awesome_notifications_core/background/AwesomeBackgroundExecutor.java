package me.carda.awesome_notifications.awesome_notifications_core.background;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

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
    ) throws AwesomeNotificationsException {

        try {

            if(awesomeBackgroundExecutorClass == null)
                throw new AwesomeNotificationsException(
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
                throw new AwesomeNotificationsException(
                        "The background executor could not be started.");
            }

        } catch (IllegalAccessException | InstantiationException e) {
            e.printStackTrace();
        }
    }
}
