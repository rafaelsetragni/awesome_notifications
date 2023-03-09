package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import org.checkerframework.checker.nullness.qual.NonNull;

import java.util.Calendar;
import java.util.List;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class CreatedManager extends EventManager {

    private static final RepositoryManager<NotificationReceived> shared
            = new RepositoryManager<>(
                    StringUtils.getInstance(),
                    "CreatedManager",
                    NotificationReceived.class,
                    "NotificationReceived");

    // ************** SINGLETON PATTERN ***********************

    private static CreatedManager instance;

    private CreatedManager(){}
    public static CreatedManager getInstance() {
        if (instance == null)
            instance = new CreatedManager();
        return instance;
    }

    // ************** SINGLETON PATTERN ***********************


    public boolean saveCreated(
            @NonNull Context context,
            @NonNull NotificationReceived received
    ) throws AwesomeNotificationsException {
        return shared.set(
                context,
                Definitions.SHARED_CREATED,
                _getKeyByIdAndDate(received.id, received.createdDate),
                received);
    }

    public List<NotificationReceived> listCreated(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_CREATED);
    }

    public List<NotificationReceived> getCreatedByKey(
            @NonNull Context context,
            @NonNull Integer id
    ) throws AwesomeNotificationsException {
        return shared.getAllObjectsStartingWith(
                context,
                Definitions.SHARED_CREATED,
                _getKeyById(id));
    }

    public NotificationReceived getCreatedByIdAndDate(
            @NonNull Context context,
            @NonNull Integer id,
            @NonNull Calendar createdDate
    ) throws AwesomeNotificationsException {
        return shared.get(
                context,
                Definitions.SHARED_CREATED,
                _getKeyByIdAndDate(id, createdDate));
    }

    public boolean clearCreated(
            @NonNull Context context,
            @NonNull Integer id,
            @NonNull Calendar createdDate
    ) throws AwesomeNotificationsException {
        return shared.remove(
                context,
                Definitions.SHARED_CREATED,
                _getKeyByIdAndDate(id, createdDate));
    }

    public boolean clearAllCreated(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.removeAll(
                context,
                Definitions.SHARED_CREATED);
    }

    public boolean commitChanges(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return shared.commit(context);
    }
}
