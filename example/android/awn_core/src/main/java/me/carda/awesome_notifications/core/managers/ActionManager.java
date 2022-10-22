package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.ActionType;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class ActionManager {

//    private static final SharedManager<ActionReceived> shared
//            = new SharedManager<>(
//                    StringUtils.getInstance(),
//                    "ActionManager",
//                    ActionReceived.class,
//                    "ActionReceived");

    private static Map<Integer, ActionReceived> actionCache = new HashMap<>();
    private static ActionReceived initialActionReceived;

    public static Boolean removeAction(Context context, Integer id) throws AwesomeNotificationsException {
        actionCache.remove(id);
        return true;
//        return shared.remove(context, Definitions.SHARED_DISMISSED, id.toString());
    }

    public static List<ActionReceived> listActions(Context context) throws AwesomeNotificationsException {
        return new ArrayList<ActionReceived>(actionCache.values());
//        return shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
    }

    public static void setInitialNotificationAction(Context context, ActionReceived received){
        initialActionReceived = received;
    }

    public static void saveAction(Context context, ActionReceived received) throws AwesomeNotificationsException {
        actionCache.put(received.id, received);
//        shared.set(context, Definitions.SHARED_DISMISSED, received.id.toString(), received);
    }

    public static ActionReceived getActionByKey(Context context, Integer id) throws AwesomeNotificationsException {
        return actionCache.get(id);
//        return shared.get(context, Definitions.SHARED_DISMISSED, id.toString());
    }

    public static void clearAllActions(Context context) throws AwesomeNotificationsException {
//        List<ActionReceived> receivedList = shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
//        if (receivedList != null){
//            for (ActionReceived received : receivedList) {
//                removeAction(context, received.id);
//            }
//        }
        initialActionReceived = null;
        actionCache.clear();
    }

    public static ActionReceived getInitialActionReceived(){
        return initialActionReceived;
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
//        shared.commit(context);
    }
}
