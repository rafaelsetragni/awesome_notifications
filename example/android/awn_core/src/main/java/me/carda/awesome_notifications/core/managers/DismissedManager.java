package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DismissedManager {

    private static final SharedManager<ActionReceived> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "DismissedManager",
                    ActionReceived.class,
                    "ActionReceived");

    public static Boolean removeDismissed(Context context, Integer id) throws AwesomeNotificationsException {
        return shared.remove(context, Definitions.SHARED_DISMISSED, id.toString());
    }

    public static List<ActionReceived> listDismisses(Context context) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
    }

    public static void saveDismissed(Context context, ActionReceived received) throws AwesomeNotificationsException {
        shared.set(context, Definitions.SHARED_DISMISSED, received.id.toString(), received);
    }

    public static ActionReceived getDismissedByKey(Context context, Integer id) throws AwesomeNotificationsException {
        return shared.get(context, Definitions.SHARED_DISMISSED, id.toString());
    }

    public static void clearAllDismissed(Context context) throws AwesomeNotificationsException {
        List<ActionReceived> receivedList = shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
        if (receivedList != null){
            for (ActionReceived received : receivedList) {
                cancelDismissed(context, received.id);
            }
        }
    }

    public static void cancelDismissed(Context context, Integer id) throws AwesomeNotificationsException {
        ActionReceived received = getDismissedByKey(context, id);
        if(received !=null)
            removeDismissed(context, received.id);
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }
}
