package me.carda.awesome_notifications.awesome_notifications_android_core.background;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.DartBackgroundExecutor;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;

public abstract class AwesomeBackgroundExecutor {

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

    public abstract void receiveBackgroundAction(
            Context context,
            Intent silentIntent,
            long dartCallbackHandle,
            long silentCallbackHandle);

    public static void runBackgroundExecutor(
        Context context,
        Intent silentIntent,
        long dartCallbackHandle,
        long silentCallbackHandle
    ){
        if(
            AwesomeBackgroundExecutor
                    .class
                    .isAssignableFrom(awesomeBackgroundExecutorClass)
        ){
            try {
                AwesomeBackgroundExecutor backgroundExecutor
                        = (AwesomeBackgroundExecutor)
                            awesomeBackgroundExecutorClass
                                .newInstance();

                backgroundExecutor.receiveBackgroundAction(
                        context,
                        silentIntent,
                        dartCallbackHandle,
                        silentCallbackHandle);

            } catch (IllegalAccessException | InstantiationException e) {
                e.printStackTrace();
            }
        }
    }
}
