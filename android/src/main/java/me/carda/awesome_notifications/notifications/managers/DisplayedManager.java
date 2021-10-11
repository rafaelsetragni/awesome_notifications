package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;

import com.google.common.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.List;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

public class DisplayedManager {

    private static final SharedManager<NotificationReceived> shared
            = new SharedManager<>(
                    "DisplayedManager",
                    NotificationReceived.class,
                    "NotificationReceived");

    public static Boolean removeDisplayed(Context context, Integer id) {
        return shared.remove(context, Definitions.SHARED_DISPLAYED, id.toString());
    }

    public static List<NotificationReceived> listDisplayed(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_DISPLAYED);
    }

    public static void saveDisplayed(Context context, NotificationReceived received) {
        shared.set(context, Definitions.SHARED_DISPLAYED, received.id.toString(), received);
    }

    public static NotificationReceived getDisplayedByKey(Context context, Integer id){
        return shared.get(context, Definitions.SHARED_DISPLAYED, id.toString());
    }

    public static void cancelAllDisplayed(Context context) {
        List<NotificationReceived> displayedList = shared.getAllObjects(context, Definitions.SHARED_DISPLAYED);
        if(displayedList != null)
            for(NotificationReceived displayed : displayedList){
                cancelDisplayed(context, displayed.id);
            }
    }

    public static void cancelDisplayed(Context context, Integer id) {
        NotificationReceived received = getDisplayedByKey(context, id);
        if(received != null)
            removeDisplayed(context, received.id);
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }
}
