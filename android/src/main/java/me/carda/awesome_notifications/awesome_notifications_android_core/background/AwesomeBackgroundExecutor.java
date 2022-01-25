package me.carda.awesome_notifications.awesome_notifications_android_core.background;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;

public abstract class AwesomeBackgroundExecutor {

    private static AwesomeBackgroundExecutor runningInstance;

    protected Long dartCallbackHandle = 0L;
    protected Long silentCallbackHandle = 0L;

    private static Class awesomeBackgroundExecutorClass;
    public static void setBackgroundExecutorClass (
        Class awesomeBackgroundExecutorClass
    ) throws AwesomeNotificationException {

        if(AwesomeBackgroundExecutor
                .class
                .isAssignableFrom(awesomeBackgroundExecutorClass)
        ){
            AwesomeBackgroundExecutor.awesomeBackgroundExecutorClass
                    = awesomeBackgroundExecutorClass;
        }
        else
            throw new AwesomeNotificationException(
                    "Class "+awesomeBackgroundExecutorClass.getSimpleName()+
                            " does not extends AwesomeBackgroundExecutor.");
    }

    public abstract boolean isDone();
    public abstract boolean runBackgroundAction(Context context, Intent silentIntent);

    public static void runBackgroundExecutor(
        Context context,
        Intent silentIntent,
        Long dartCallbackHandle,
        Long silentCallbackHandle
    ) throws AwesomeNotificationException {

        if(awesomeBackgroundExecutorClass == null)
            throw new AwesomeNotificationException(
                    "There is no valid AwesomeBackgroundExecutorClass available to use.");

        try {
            if(runningInstance == null || runningInstance.isDone()) {

                runningInstance = (AwesomeBackgroundExecutor)
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
                        "The background execution could not be started.");
            }

        } catch (IllegalAccessException | InstantiationException e) {
            e.printStackTrace();
        }
    }
}
