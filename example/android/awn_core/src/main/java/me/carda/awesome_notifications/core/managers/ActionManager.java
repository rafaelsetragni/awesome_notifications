package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import org.checkerframework.checker.nullness.qual.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;

public class ActionManager extends EventManager {

//    private static final SharedManager<ActionReceived> shared
//            = new SharedManager<>(
//                    StringUtils.getInstance(),
//                    "ActionManager",
//                    ActionReceived.class,
//                    "ActionReceived");

    // ************** SINGLETON PATTERN ***********************

    private static ActionManager instance;

    private ActionManager(){}
    public static ActionManager getInstance() {
        if (instance == null)
            instance = new ActionManager();
        return instance;
    }

    // ************** SINGLETON PATTERN ***********************

    private final Map<Integer, ActionReceived> actionCache = new HashMap<>();
    private ActionReceived initialActionReceived;

    public boolean saveAction(
            @NonNull Context context,
            @NonNull ActionReceived received
    ) throws AwesomeNotificationsException {
        return actionCache.put(received.id, received) != null;
//        shared.set(context, Definitions.SHARED_DISMISSED, received.id.toString(), received);
    }

    public boolean clearAction(
            @NonNull Context context,
            @NonNull Integer id
    ) throws AwesomeNotificationsException {
        actionCache.remove(id);
        return true;
//        return shared.remove(context, Definitions.SHARED_DISMISSED, id.toString());
    }

    public List<ActionReceived> listActions(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return new ArrayList<ActionReceived>(actionCache.values());
//        return shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
    }

    public void setInitialNotificationAction(
            @NonNull Context context,
            @NonNull ActionReceived received
    ){
        initialActionReceived = received;
    }

    public ActionReceived getActionByKey(
            @NonNull Context context,
            @NonNull Integer id
    ) throws AwesomeNotificationsException {
        return actionCache.get(id);
//        return shared.get(context, Definitions.SHARED_DISMISSED, id.toString());
    }

    public boolean clearAllActions(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
//        List<ActionReceived> receivedList = shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
//        if (receivedList != null){
//            for (ActionReceived received : receivedList) {
//                removeAction(context, received.id);
//            }
//        }
        initialActionReceived = null;
        actionCache.clear();
        return true;
    }

    public ActionReceived getInitialActionReceived(){
        return initialActionReceived;
    }

    public boolean commitChanges(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
//        shared.commit(context);
        return true;
    }
}
