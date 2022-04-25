package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import me.carda.awesome_notifications.core.AwesomeNotificationsExtension;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.MediaSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.DefaultsModel;
import me.carda.awesome_notifications.core.utils.BitmapUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DefaultsManager {

    private static DefaultsModel instance;
    private static final SharedManager<DefaultsModel> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "DefaultsManager",
                    DefaultsModel.class,
                    "DefaultsModel");

    public static void saveDefault(
        @NonNull Context context,
        @Nullable String defaultIconPath,
        @Nullable Long dartCallback
    ) throws AwesomeNotificationsException {
        if (BitmapUtils.getInstance().getMediaSourceType(defaultIconPath) != MediaSource.Resource)
            defaultIconPath = null;

        DefaultsModel defaults = getDefaults(context);

        if (defaults == null) {
            defaults = new DefaultsModel(
                    defaultIconPath,
                    dartCallback,
                    null,
                    null);
        }
        else {
            defaults.appIcon = defaultIconPath;
            defaults.reverseDartCallback = dartCallback == null ? null : dartCallback.toString();
        }

        saveDefault(context, defaults);

    }

    private static void saveDefault(Context context, DefaultsModel defaults) throws AwesomeNotificationsException {
        shared.set(context, Definitions.SHARED_DEFAULTS, "Defaults", defaults);
    }

    public static DefaultsModel getDefaults(Context context) throws AwesomeNotificationsException {
        if (instance == null)
            instance = shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");

        return instance == null ? new DefaultsModel() : instance;
    }

    public static String getDefaultIcon(Context context) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        return (defaults != null) ? defaults.appIcon : null;
    }

    public static void setDefaultIcon(Context context, String appIcon) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        defaults.appIcon = appIcon;
        saveDefault(context, defaults);
    }

    public static Long getSilentCallbackDispatcher(Context context) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        return Long.parseLong(defaults.silentDataCallback);
    }

    public static void setActionCallbackDispatcher(Context context, Long silentDataCallback) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        defaults.silentDataCallback = silentDataCallback.toString();
        saveDefault(context, defaults);
    }

    public static Long getDartCallbackDispatcher(Context context) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        return Long.parseLong(defaults.reverseDartCallback);
    }

    public static void setDartCallbackDispatcher(Context context, Long reverseDartCallback) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        defaults.reverseDartCallback = reverseDartCallback.toString();
        saveDefault(context, defaults);
    }

    public static String getAwesomeExtensionClassName(Context context) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        return defaults.backgroundHandleClass;
    }

    public static void setAwesomeExtensionClassName(Context context, Class<? extends AwesomeNotificationsExtension> backgroundHandleClass) throws AwesomeNotificationsException {
        DefaultsModel defaults = getDefaults(context);
        defaults.backgroundHandleClass = backgroundHandleClass.getName();
        saveDefault(context, defaults);
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }
}
