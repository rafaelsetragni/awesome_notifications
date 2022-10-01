package me.carda.awesome_notifications.core.threads;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.Nullable;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import me.carda.awesome_notifications.core.enumerators.MediaSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.utils.BitmapUtils;

public abstract class NotificationThread<T>{

    private final String TAG = "NotificationThread";

    protected abstract T doInBackground() throws Exception;
    protected abstract T onPostExecute(@Nullable T received) throws AwesomeNotificationsException;
    protected abstract void whenComplete(@Nullable T returnedValue, @Nullable AwesomeNotificationsException exception) throws AwesomeNotificationsException;

    public void execute(){
        runOnBackgroundThread();
    }

    public void execute(NotificationModel notificationModel){
        if(itMustRunOnBackgroundThread(notificationModel))
            runOnBackgroundThread();
        else
            runOnForegroundThread();
    }

    private void runOnBackgroundThread() {
        final ExecutorService executor = Executors.newSingleThreadExecutor();
        final Handler handler = new Handler(Looper.getMainLooper());
        final NotificationThread<T> threadReference = this;

        executor.execute(new Runnable() {
            @Override
            public void run() {
                try{
                    final T response = threadReference.doInBackground();
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            T returnedValue = null;
                            try{
                                returnedValue = threadReference.onPostExecute(response);
                                whenComplete(returnedValue, null);
                            } catch (AwesomeNotificationsException awesomeException) {
                                try {
                                    whenComplete(null, awesomeException);
                                } catch (AwesomeNotificationsException e) {
                                    e.printStackTrace();
                                }
                            } catch (Exception exception){
                                try {
                                    whenComplete(
                                            null,
                                            ExceptionFactory
                                                    .getInstance()
                                                    .createNewAwesomeException(
                                                            TAG,
                                                            ExceptionCode.CODE_NOTIFICATION_THREAD_EXCEPTION,
                                                            ExceptionCode.DETAILED_UNEXPECTED_ERROR,
                                                            exception));
                                } catch (AwesomeNotificationsException e) {
                                    e.printStackTrace();
                                }
                            }
                        }
                    });
                } catch (AwesomeNotificationsException awesomeException) {
                    try {
                        whenComplete(null, awesomeException);
                    } catch (AwesomeNotificationsException e) {
                        e.printStackTrace();
                    }
                } catch (Exception exception) {
                    try {
                        whenComplete(
                                null,
                                ExceptionFactory
                                        .getInstance()
                                        .createNewAwesomeException(
                                                TAG,
                                                ExceptionCode.CODE_NOTIFICATION_THREAD_EXCEPTION,
                                                ExceptionCode.DETAILED_UNEXPECTED_ERROR,
                                                exception));
                    } catch (AwesomeNotificationsException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

    private void runOnForegroundThread() {
        if(Looper.myLooper() == Looper.getMainLooper()) {
            T returnedValue = null;
            try{
                returnedValue = onPostExecute(doInBackground());
                whenComplete(returnedValue, null);
            } catch (AwesomeNotificationsException awesomeException) {
                try {
                    whenComplete(null, awesomeException);
                } catch (AwesomeNotificationsException e) {
                    e.printStackTrace();
                }
            } catch (Exception exception){
                try {
                    whenComplete(
                            null,
                            ExceptionFactory
                                    .getInstance()
                                    .createNewAwesomeException(
                                            TAG,
                                            ExceptionCode.CODE_NOTIFICATION_THREAD_EXCEPTION,
                                            ExceptionCode.DETAILED_UNEXPECTED_ERROR,
                                            exception));
                } catch (AwesomeNotificationsException e) {
                    e.printStackTrace();
                }
            }
        }
        else {
            final Handler handler = new Handler(Looper.getMainLooper());
            final NotificationThread<T> threadReference = this;

            handler.post(new Runnable() {
                @Override
                public void run() {
                    T returnedValue = null;
                    try {
                        final T response = threadReference.doInBackground();
                        returnedValue = threadReference.onPostExecute(response);
                        whenComplete(returnedValue, null);
                    } catch (AwesomeNotificationsException awesomeException) {
                        try {
                            whenComplete(null, awesomeException);
                        } catch (AwesomeNotificationsException e) {
                            e.printStackTrace();
                        }
                    } catch (Exception exception){
                        try {
                            whenComplete(
                                    null,
                                    ExceptionFactory
                                            .getInstance()
                                            .createNewAwesomeException(
                                                    TAG,
                                                    ExceptionCode.CODE_NOTIFICATION_THREAD_EXCEPTION,
                                                    ExceptionCode.DETAILED_UNEXPECTED_ERROR,
                                                    exception));
                        } catch (AwesomeNotificationsException e) {
                            e.printStackTrace();
                        }
                    }
                }
            });
        }
    }

    private boolean itMustRunOnBackgroundThread(NotificationModel notificationModel){
        BitmapUtils bitmapUtils = BitmapUtils.getInstance();
        return
                MediaSource.Network == bitmapUtils
                        .getMediaSourceType(notificationModel.content.bigPicture)
                ||
                MediaSource.Network == bitmapUtils
                        .getMediaSourceType(notificationModel.content.largeIcon);
    }

}
