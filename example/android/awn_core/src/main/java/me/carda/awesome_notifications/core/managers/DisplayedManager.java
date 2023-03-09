package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import org.checkerframework.checker.nullness.qual.NonNull;

import java.util.Calendar;
import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DisplayedManager extends EventManager {

    private static final RepositoryManager<NotificationReceived> shared
            = new RepositoryManager<>(
                    StringUtils.getInstance(),
                    "DisplayedManager",
                    NotificationReceived.class,
                    "NotificationReceived");

    // ************** SINGLETON PATTERN ***********************

    private static DisplayedManager instance;

    private DisplayedManager(){}
    public static DisplayedManager getInstance() {
        if (instance == null)
            instance = new DisplayedManager();
        return instance;
    }

    // ************** SINGLETON PATTERN ***********************

    public boolean saveDisplayed(
            @NonNull Context context,
            @NonNull NotificationReceived received
    ) throws AwesomeNotificationsException {
        return shared.set(
                context,
                Definitions.SHARED_DISPLAYED,
                _getKeyByIdAndDate(received.id, received.displayedDate),
                received);
    }

    public List<NotificationReceived> listDisplayed(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_DISPLAYED);
    }

    public List<NotificationReceived> getDisplayedByKey(
            @NonNull Context context,
            @NonNull Integer id
    ) throws AwesomeNotificationsException {
        return shared.getAllObjectsStartingWith(
                context,
                Definitions.SHARED_DISPLAYED,
                _getKeyById(id));
    }

    public NotificationReceived getDisplayedByIdAndDate(
            @NonNull Context context,
            @NonNull Integer id,
            @NonNull Calendar displayedDate
    ) throws AwesomeNotificationsException {
        return shared.get(
                context,
                Definitions.SHARED_DISPLAYED,
                _getKeyByIdAndDate(id, displayedDate));
    }

    public Boolean clearDisplayed(
            @NonNull Context context,
            @NonNull Integer id,
            @NonNull Calendar displayedDate
    ) throws AwesomeNotificationsException {
        return shared.remove(
                context,
                Definitions.SHARED_DISPLAYED,
                _getKeyByIdAndDate(id, displayedDate));
    }

    public boolean clearAllDisplayed(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.removeAll(
                context,
                Definitions.SHARED_DISPLAYED);
    }

    public boolean commitChanges(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.commit(context);
    }
}
