package me.carda.awesome_notifications.awesome_notifications_core.threads;

import android.os.*;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import me.carda.awesome_notifications.awesome_notifications_core.enumerators.MediaSource;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BitmapUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public abstract class NotificationThread<T>{

    protected abstract T doInBackground();
    protected abstract void onPostExecute(T received);

    public void execute(NotificationModel notificationModel){
        if(itMustRunOnBackgroundThread(notificationModel)){
            runOnBackgroundThread();
        }
        else
            this.onPostExecute(this.doInBackground());
    }

    private void runOnBackgroundThread() {
        final ExecutorService executor = Executors.newSingleThreadExecutor();
        final Handler handler = new Handler(Looper.getMainLooper());
        final NotificationThread<T> threadReference = this;

        executor.execute(new Runnable() {
            @Override
            public void run() {
                final T response = threadReference.doInBackground();
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        threadReference.onPostExecute(response);
                    }
                });
            }
        });
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
