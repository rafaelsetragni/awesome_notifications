package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.listeners.AwesomeLifeCycleEventListener;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.models.AbstractModel;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;

public class LostEventsManager {
    private static final String TAG = "LostEventsManager";

    // ************** SINGLETON PATTERN ***********************

    private static LostEventsManager instance;

    private LostEventsManager(){}
    public static LostEventsManager getInstance() {
        if (instance == null)
            instance = new LostEventsManager();
        return instance;
    }

    // ************** PUBLIC METHODS ***********************

    public void recoverLostNotificationEvents(
            @NonNull Context context,
            @NonNull boolean recoverCreated,
            @NonNull boolean recoverDisplayed,
            @NonNull boolean recoverActions,
            @NonNull boolean recoverDismissed
    ) throws AwesomeNotificationsException {
        Map<String, AbstractModel> events = new TreeMap<>();

        if(recoverCreated){
            Map<String, AbstractModel> recoveredCreated = recoverNotificationCreated(context);
            events.putAll(recoveredCreated);
        } else {
            CreatedManager
                    .getInstance()
                    .removeAllCreated(context);
        }

        if (recoverDisplayed) {
            Map<String, AbstractModel> recoveredDisplayed = recoverNotificationDisplayed(context);
            events.putAll(recoveredDisplayed);
        } else {
            DisplayedManager
                    .getInstance()
                    .removeAllDisplayed(context);
        }

        if (recoverActions) {
            Map<String, AbstractModel> recoveredActions = recoverNotificationActions(context);
            events.putAll(recoveredActions);
        } else {
            ActionManager
                    .getInstance()
                    .removeAllActions(context);
        }

        if (recoverDismissed) {
            Map<String, AbstractModel> recoveredDismissed = recoverNotificationsDismissed(context);
            events.putAll(recoveredDismissed);
        } else {
            DismissedManager
                    .getInstance()
                    .removeAllDismissed(context);
        }

        if (events.isEmpty()) return;

        // Deliver events in the same order they were added to the queue
        for (String key : events.keySet()) {
            int lastIndex = key.lastIndexOf("::");
            String eventReference = key.substring(lastIndex + 2);
            switch (eventReference) {
                case "created":
                    BroadcastSender
                            .getInstance()
                            .sendBroadcastNotificationCreated(
                                    context,
                                    (NotificationReceived) events.get(key)
                            );
                    break;
                case "displayed":
                    BroadcastSender
                            .getInstance()
                            .sendBroadcastNotificationDisplayed(
                                    context,
                                    (NotificationReceived) events.get(key)
                            );
                    break;
                case "action":
                    BroadcastSender
                            .getInstance()
                            .sendBroadcastDefaultAction(
                                    context,
                                    (ActionReceived) events.get(key),
                                    false
                            );
                    break;
                case "dismissed":
                    BroadcastSender
                            .getInstance()
                            .sendBroadcastNotificationDismissed(
                                    context,
                                    (ActionReceived) events.get(key)
                            );
                    break;
            }
        }
    }

    // *****************************  RECOVER FUNCTIONS  **********************************


    public void saveCreated(
            @NonNull Context context,
            @NonNull NotificationReceived createdReceived
    ) throws AwesomeNotificationsException {
        CreatedManager.getInstance().saveCreated(context, createdReceived);
        CreatedManager.getInstance().commitChanges(context);
    }

    public void saveDisplayed(
            @NonNull Context context,
            @NonNull NotificationReceived displayedReceived
    ) throws AwesomeNotificationsException {
        DisplayedManager.getInstance().saveDisplayed(context, displayedReceived);
        DisplayedManager.getInstance().commitChanges(context);
    }

    public void saveAction(
            @NonNull Context context,
            @NonNull ActionReceived actionReceived
    ) throws AwesomeNotificationsException {
        ActionManager.getInstance().saveAction(context, actionReceived);
        ActionManager.getInstance().commitChanges(context);
    }

    public void saveDismissed(
            @NonNull Context context,
            @NonNull ActionReceived dismissedReceived
    ) throws AwesomeNotificationsException {
        DismissedManager.getInstance().saveDismissed(context, dismissedReceived);
        DismissedManager.getInstance().commitChanges(context);
    }

    // *****************************  RECOVER FUNCTIONS  **********************************

    private String generateKeyDateToEvent(
            @NonNull Calendar time,
            @NonNull Integer notificationId,
            @NonNull String eventReference
    ){
        return String.valueOf(time.getTimeInMillis() / 1000)
                +"::"+
                notificationId.toString()
                +"::"+
                eventReference;
    }

    private Map<String, AbstractModel> recoverNotificationCreated(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        Map<String, AbstractModel> recoveredEvents = new HashMap<>();
        List<NotificationReceived> lostCreated = CreatedManager
                .getInstance()
                .listCreated(context);
        if (lostCreated.isEmpty()) return recoveredEvents;

        for (NotificationReceived created : lostCreated)
            try {
                created.validate(context);

                recoveredEvents.put(
                        generateKeyDateToEvent(
                                created.createdDate,
                                created.id,
                                "created"
                        ),
                        created
                );

                CreatedManager
                        .getInstance()
                        .removeCreated(
                                context,
                                created.id,
                                created.createdDate);

            } catch (AwesomeNotificationsException e) {
                if (AwesomeNotifications.debug)
                    Logger.d(TAG, String.format("%s", e.getMessage()));
                e.printStackTrace();
            }

        CreatedManager
                .getInstance()
                .commitChanges(context);

        return recoveredEvents;
    }

    private Map<String, AbstractModel> recoverNotificationDisplayed(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        Map<String, AbstractModel> recoveredEvents = new HashMap<>();
        List<NotificationReceived> lostDisplayed = DisplayedManager
                .getInstance()
                .listDisplayed(context);

        if (lostDisplayed == null) return recoveredEvents;
        for (NotificationReceived displayed : lostDisplayed)
            try {
                recoveredEvents.put(
                        generateKeyDateToEvent(
                                displayed.displayedDate,
                                displayed.id,
                                "displayed"
                        ),
                        displayed
                );

                DisplayedManager
                        .getInstance()
                        .removeDisplayed(
                                context,
                                displayed.id,
                                displayed.displayedDate);

            } catch (AwesomeNotificationsException e) {
                if (AwesomeNotifications.debug)
                    Logger.d(TAG, String.format("%s", e.getMessage()));
                e.printStackTrace();
            }

        DisplayedManager
                .getInstance()
                .commitChanges(context);

        return recoveredEvents;
    }

    private Map<String, AbstractModel> recoverNotificationActions(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        Map<String, AbstractModel> recoveredEvents = new HashMap<>();
        List<ActionReceived> lostActions = ActionManager
                .getInstance()
                .listActions(context);

        if (lostActions == null) return recoveredEvents;
        for (ActionReceived received : lostActions)
            try {
                recoveredEvents.put(
                        generateKeyDateToEvent(
                                received.actionDate,
                                received.id,
                                "action"
                        ),
                        received
                );

                ActionManager
                        .getInstance()
                        .removeAction(
                                context,
                                received.id);

            } catch (AwesomeNotificationsException e) {
                if (AwesomeNotifications.debug)
                    Logger.d(TAG, String.format("%s", e.getMessage()));
                e.printStackTrace();
            }

        ActionManager
                .getInstance()
                .commitChanges(context);

        return recoveredEvents;
    }

    private Map<String, AbstractModel> recoverNotificationsDismissed(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        Map<String, AbstractModel> recoveredEvents = new HashMap<>();
        List<ActionReceived> lostDismissed = DismissedManager
                .getInstance()
                .listDismisses(context);

        if (lostDismissed == null) return recoveredEvents;
        for (ActionReceived received : lostDismissed)
            try {
                received.validate(context);

                recoveredEvents.put(
                        generateKeyDateToEvent(
                                received.dismissedDate,
                                received.id,
                                "dismissed"
                        ),
                        received
                );

                DismissedManager
                        .getInstance()
                        .removeDismissed(
                                context,
                                received.id,
                                received.dismissedDate);

            } catch (AwesomeNotificationsException e) {
                if (AwesomeNotifications.debug)
                    Logger.d(TAG, String.format("%s", e.getMessage()));
                e.printStackTrace();
            }

        DismissedManager
                .getInstance()
                .commitChanges(context);

        return recoveredEvents;
    }
}
