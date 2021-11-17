package me.carda.awesome_notifications.notifications.managers;

import android.app.NotificationChannelGroup;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import java.util.List;

import androidx.annotation.RequiresApi;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelGroupModel;

public class ChannelGroupManager {

    private static final SharedManager<NotificationChannelGroupModel> shared
            = new SharedManager<>(
                    "ChannelGroupManager",
                    NotificationChannelGroupModel.class,
                    "NotificationChannelGroup");

    public static Boolean removeChannelGroup(Context context, String channelGroupKey) {
        return shared.remove(context, Definitions.SHARED_CHANNEL_GROUP, channelGroupKey);
    }

    public static List<NotificationChannelGroupModel> listChannelGroup(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNEL_GROUP);
    }

    public static void saveChannelGroup(Context context, NotificationChannelGroupModel channelGroupModel) {
        try {
            channelGroupModel.validate(context);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                setAndroidChannelGroup(context, channelGroupModel);

            shared.set(context, Definitions.SHARED_CHANNEL_GROUP, channelGroupModel.channelGroupKey, channelGroupModel);
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
    }

    public static NotificationChannelGroupModel getChannelGroupByKey(Context context, String channelGroupKey){
        return shared.get(context, Definitions.SHARED_CHANNEL_GROUP, channelGroupKey);
    }

    public static void cancelAllChannelGroup(Context context) {
        List<NotificationChannelGroupModel> channelGroupList = shared.getAllObjects(context, Definitions.SHARED_CHANNEL_GROUP);
        if (channelGroupList != null){
            for (NotificationChannelGroupModel channelGroup : channelGroupList) {
                cancelChannelGroup(context, channelGroup.channelGroupKey);
            }
        }
    }

    public static void cancelChannelGroup(Context context, String channelGroupKey) {
        NotificationChannelGroupModel channelGroup = getChannelGroupByKey(context, channelGroupKey);
        if(channelGroup !=null)
            removeChannelGroup(context, channelGroupKey);
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    public static void setAndroidChannelGroup(Context context, NotificationChannelGroupModel newChannelGroup) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.createNotificationChannelGroup(new NotificationChannelGroup(newChannelGroup.channelGroupKey, newChannelGroup.channelGroupName));
    }
}
