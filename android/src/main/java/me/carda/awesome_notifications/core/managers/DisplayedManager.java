package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DisplayedManager {

    private static final SharedManager<NotificationReceived> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "DisplayedManager",
                    NotificationReceived.class,
                    "NotificationReceived");

    public static Boolean removeDisplayed(Context context, Integer id) throws AwesomeNotificationsException {
        return shared.remove(context, Definitions.SHARED_DISPLAYED, id.toString());
    }

    public static List<NotificationReceived> listDisplayed(Context context) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_DISPLAYED);
    }

    public static void saveDisplayed(Context context, NotificationReceived received) throws AwesomeNotificationsException {
        shared.set(context, Definitions.SHARED_DISPLAYED, received.id.toString(), received);
    }

    public static NotificationReceived getDisplayedByKey(Context context, Integer id) throws AwesomeNotificationsException {
        return shared.get(context, Definitions.SHARED_DISPLAYED, id.toString());
    }

    public static void cancelAllDisplayed(Context context) throws AwesomeNotificationsException {
        List<NotificationReceived> displayedList = shared.getAllObjects(context, Definitions.SHARED_DISPLAYED);
        if(displayedList != null)
            for(NotificationReceived displayed : displayedList){
                cancelDisplayed(context, displayed.id);
            }
    }

    public static void cancelDisplayed(Context context, Integer id) throws AwesomeNotificationsException {
        NotificationReceived received = getDisplayedByKey(context, id);
        if(received != null)
            removeDisplayed(context, received.id);
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }
}
