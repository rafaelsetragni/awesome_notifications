package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import me.carda.awesome_notifications.core.AwesomeNotificationsExtension;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.databases.SQLitePrimitivesDB;
import me.carda.awesome_notifications.core.enumerators.MediaSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.DefaultsModel;
import me.carda.awesome_notifications.core.utils.BitmapUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DefaultsManager {

    private SQLitePrimitivesDB sqLitePrimitives;
    private static final RepositoryManager<DefaultsModel> shared
            = new RepositoryManager<>(
                    StringUtils.getInstance(),
                    "DefaultsManager",
                    DefaultsModel.class,
                    "DefaultsModel");

    // ************** SINGLETON PATTERN ***********************

    private static DefaultsManager instance;

    private DefaultsManager(Context context){
        sqLitePrimitives = SQLitePrimitivesDB.getInstance(context);

        try {
            DefaultsModel defaults = getDefaults(context);
            if (defaults != null) {
                setDefaultIcon(context, defaults.appIcon);
                setDartCallbackDispatcher(context, Long.parseLong(defaults.reverseDartCallback));
                setActionCallbackDispatcher(context, Long.parseLong(defaults.silentDataCallback));
                saveDefault(context, null);
            }
        } catch (AwesomeNotificationsException e) {
            throw new RuntimeException(e);
        }
    }

    public static DefaultsManager getInstance(Context context) {
        if (instance == null)
            instance = new DefaultsManager(context);
        return instance;
    }

    // ************** SINGLETON PATTERN ***********************

    public void saveDefault(
        @NonNull Context context,
        @Nullable String defaultIconPath,
        @Nullable Long dartCallback
    ) throws AwesomeNotificationsException {
        if (BitmapUtils.getInstance().getMediaSourceType(defaultIconPath) != MediaSource.Resource) {
            defaultIconPath = null;
        }
        setDefaultIcon(context, defaultIconPath);
        setDartCallbackDispatcher(context, dartCallback);
    }

    private static void saveDefault(
            @NonNull Context context,
            @Nullable DefaultsModel defaults
    ) throws AwesomeNotificationsException {
        if (defaults != null) {
            shared.set(context, Definitions.SHARED_DEFAULTS, "Defaults", defaults);
        } else {
            shared.remove(context, Definitions.SHARED_DEFAULTS, "Defaults");
        }
    }

    private static DefaultsModel getDefaults(
            Context context
    ) throws AwesomeNotificationsException {
        return shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");
    }

    public boolean setDefaultIcon(
            @NonNull Context context,
            @Nullable String appIcon
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setString(
                        context,
                        "defaults",
                        Definitions.NOTIFICATION_APP_ICON,
                        appIcon);
    }

    public String getDefaultIcon(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getString(
                        context,
                        "defaults",
                        Definitions.NOTIFICATION_APP_ICON,
                        null);
    }

    public boolean setCreatedCallbackDispatcher(
            @NonNull Context context,
            @NonNull Long createdCallback
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setLong(
                        context,
                        "defaults",
                        Definitions.CREATED_HANDLE,
                        createdCallback);
    }

    public Long getCreatedCallbackDispatcher(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getLong(
                        context,
                        "defaults",
                        Definitions.CREATED_HANDLE,
                        0L);
    }

    public boolean setDisplayedCallbackDispatcher(
            @NonNull Context context,
            @NonNull Long displayedCallback
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setLong(
                        context,
                        "defaults",
                        Definitions.DISPLAYED_HANDLE,
                        displayedCallback);
    }

    public Long getDisplayedCallbackDispatcher(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getLong(
                        context,
                        "defaults",
                        Definitions.DISPLAYED_HANDLE,
                        0L);
    }

    public boolean setActionCallbackDispatcher(
            @NonNull Context context,
            @NonNull Long actionCallback
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setLong(
                        context,
                        "defaults",
                        Definitions.ACTION_HANDLE,
                        actionCallback);
    }

    public Long getActionCallbackDispatcher(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getLong(
                        context,
                        "defaults",
                        Definitions.ACTION_HANDLE,
                        0L);
    }

    public boolean setDismissedCallbackDispatcher(
            @NonNull Context context,
            @NonNull Long dismissedCallback
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setLong(
                        context,
                        "defaults",
                        Definitions.DISMISSED_HANDLE,
                        dismissedCallback);
    }

    public Long getDismissedCallbackDispatcher(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getLong(
                        context,
                        "defaults",
                        Definitions.DISMISSED_HANDLE,
                        0L);
    }

    public boolean setDartCallbackDispatcher(
            @NonNull Context context,
            @NonNull Long reverseDartCallback
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setLong(
                        context,
                        "defaults",
                        Definitions.BACKGROUND_HANDLE,
                        reverseDartCallback);
    }

    public Long getDartCallbackDispatcher(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getLong(
                    context,
                    "defaults",
                    Definitions.BACKGROUND_HANDLE,
                    0L);
    }

    public boolean setSilentCallbackDispatcher(
            @NonNull Context context,
            @NonNull Long silentDartCallback
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .setLong(
                        context,
                        "defaults",
                        Definitions.SILENT_HANDLE,
                        silentDartCallback);
    }

    public Long getSilentCallbackDispatcher(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        return sqLitePrimitives
                .getLong(
                        context,
                        "defaults",
                        Definitions.SILENT_HANDLE,
                        0L);
    }

    public String getAwesomeExtensionClassName(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        return defaults.backgroundHandleClass;
    }

    public void setAwesomeExtensionClassName(
            @NonNull Context context,
            @NonNull Class<? extends AwesomeNotificationsExtension> backgroundHandleClass
    ) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        defaults.backgroundHandleClass = backgroundHandleClass.getName();
        saveDefault(context, defaults);
    }

    public void commitChanges(
            @NonNull Context context
    ) throws AwesomeNotificationsException {
        shared.commit(context);
    }
}
