package me.carda.awesome_notifications.core.managers;

import android.app.NotificationChannelGroup;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import androidx.annotation.RequiresApi;

import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.NotificationChannelGroupModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class ChannelGroupManager {

    private static final SharedManager<NotificationChannelGroupModel> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "ChannelGroupManager",
                    NotificationChannelGroupModel.class,
                    "NotificationChannelGroup");

    public static Boolean removeChannelGroup(Context context, String channelGroupKey) throws AwesomeNotificationsException {
        return shared.remove(context, Definitions.SHARED_CHANNEL_GROUP, channelGroupKey);
    }

    public static List<NotificationChannelGroupModel> listChannelGroup(Context context) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNEL_GROUP);
    }

    public static void saveChannelGroup(Context context, NotificationChannelGroupModel channelGroupModel) {
        try {
            channelGroupModel.validate(context);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                setAndroidChannelGroup(context, channelGroupModel);

            shared.set(context, Definitions.SHARED_CHANNEL_GROUP, channelGroupModel.channelGroupKey, channelGroupModel);
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
    }

    public static NotificationChannelGroupModel getChannelGroupByKey(Context context, String channelGroupKey) throws AwesomeNotificationsException {
        return shared.get(context, Definitions.SHARED_CHANNEL_GROUP, channelGroupKey);
    }

    public static void cancelAllChannelGroup(Context context) throws AwesomeNotificationsException {
        List<NotificationChannelGroupModel> channelGroupList = shared.getAllObjects(context, Definitions.SHARED_CHANNEL_GROUP);
        if (channelGroupList != null){
            for (NotificationChannelGroupModel channelGroup : channelGroupList) {
                cancelChannelGroup(context, channelGroup.channelGroupKey);
            }
        }
    }

    public static void cancelChannelGroup(Context context, String channelGroupKey) throws AwesomeNotificationsException {
        NotificationChannelGroupModel channelGroup = getChannelGroupByKey(context, channelGroupKey);
        if(channelGroup !=null)
            removeChannelGroup(context, channelGroupKey);
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    public static void setAndroidChannelGroup(Context context, NotificationChannelGroupModel newChannelGroup) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.createNotificationChannelGroup(new NotificationChannelGroup(newChannelGroup.channelGroupKey, newChannelGroup.channelGroupName));
    }
}
