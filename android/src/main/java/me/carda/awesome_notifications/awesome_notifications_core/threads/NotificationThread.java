package me.carda.awesome_notifications.awesome_notifications_core.threads;

import android.os.*;

import me.carda.awesome_notifications.awesome_notifications_core.enumerators.MediaSource;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BitmapUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public abstract class NotificationThread<Params, Progress, Result> extends AsyncTask<Params, Progress, Result> {

    public void executeNotificationThread(NotificationModel notificationModel, Params... params){
        if(itMustRunOnBackgroundThread(notificationModel))
            this.execute(params);
        else
            this.onPostExecute(this.doInBackground(params));
    }

    private boolean itMustRunOnBackgroundThread(NotificationModel notificationModel){
        BitmapUtils bitmapUtils = BitmapUtils.getInstance();

        if(MediaSource.Network == bitmapUtils
                .getMediaSourceType(notificationModel.content.largeIcon)
        ) return true;

        if(MediaSource.Network == bitmapUtils
                .getMediaSourceType(notificationModel.content.bigPicture)
        ) return true;

        return false;
    }

}
