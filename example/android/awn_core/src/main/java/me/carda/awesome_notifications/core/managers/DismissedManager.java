package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import org.checkerframework.checker.nullness.qual.NonNull;

import java.util.Calendar;
import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DismissedManager extends EventManager {

    private static final RepositoryManager<ActionReceived> shared
            = new RepositoryManager<>(
                    StringUtils.getInstance(),
                    "DismissedManager",
                    ActionReceived.class,
                    "ActionReceived");

    // ************** SINGLETON PATTERN ***********************

    private static DismissedManager instance;

    private DismissedManager(){}
    public static DismissedManager getInstance() {
        if (instance == null)
            instance = new DismissedManager();
        return instance;
    }

    // ************** SINGLETON PATTERN ***********************



    public boolean saveDismissed(
            @NonNull Context context,
            @NonNull ActionReceived received
    ) throws AwesomeNotificationsException {
        return shared.set(
                context,
                Definitions.SHARED_DISMISSED,
                _getKeyByIdAndDate(received.id, received.dismissedDate),
                received);
    }

    public List<ActionReceived> listDismisses(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_DISMISSED);
    }

    public List<ActionReceived> getDismissedByKey(
            @NonNull Context context,
            @NonNull Integer id
    ) throws AwesomeNotificationsException {
        return shared.getAllObjectsStartingWith(
                context,
                Definitions.SHARED_DISMISSED,
                _getKeyById(id));
    }

    public NotificationReceived getDismissedByIdAndDate(
            @NonNull Context context,
            @NonNull Integer id,
            @NonNull Calendar dismissedDate
    ) throws AwesomeNotificationsException {
        return shared.get(
                context,
                Definitions.SHARED_DISMISSED,
                _getKeyByIdAndDate(id, dismissedDate));
    }

    public boolean removeDismissed(
            @NonNull Context context,
            @NonNull Integer id,
            @NonNull Calendar dismissedDate
    ) throws AwesomeNotificationsException {
        return shared.remove(
                context,
                Definitions.SHARED_DISMISSED,
                _getKeyByIdAndDate(id, dismissedDate));
    }

    public boolean removeAllDismissed(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.removeAll(
                context,
                Definitions.SHARED_DISMISSED);
    }

    public boolean commitChanges(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.commit(context);
    }
}
