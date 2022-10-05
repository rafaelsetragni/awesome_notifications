package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class CreatedManager {

    private static final SharedManager<NotificationReceived> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "CreatedManager",
                    NotificationReceived.class,
                    "NotificationReceived");

    public static Boolean removeCreated(Context context, Integer id) throws AwesomeNotificationsException {
        return shared.remove(context, Definitions.SHARED_CREATED, id.toString());
    }

    public static List<NotificationReceived> listCreated(Context context) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_CREATED);
    }

    public static void saveCreated(Context context, NotificationReceived received) throws AwesomeNotificationsException {
        shared.set(context, Definitions.SHARED_CREATED, received.id.toString(), received);
    }

    public static NotificationReceived getCreatedByKey(Context context, Integer id) throws AwesomeNotificationsException {
        return shared.get(context, Definitions.SHARED_CREATED, id.toString());
    }

    public static void cancelAllCreated(Context context) throws AwesomeNotificationsException {
        List<NotificationReceived> receivedList = shared.getAllObjects(context, Definitions.SHARED_CREATED);
        if (receivedList != null){
            for (NotificationReceived received : receivedList) {
                cancelCreated(context, received.id);
            }
        }
    }

    public static void cancelCreated(Context context, Integer id) throws AwesomeNotificationsException {
        NotificationReceived received = getCreatedByKey(context, id);
        if(received !=null)
            removeCreated(context, received.id);
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }
}
