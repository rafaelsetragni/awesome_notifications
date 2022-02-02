package me.carda.awesome_notifications.awesome_notifications_core.managers;

import android.content.Context;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.models.DefaultsModel;

public class DefaultsManager {

    private static DefaultsModel instance;
    private static final SharedManager<DefaultsModel> shared
            = new SharedManager<>(
                    "DefaultsManager",
                    DefaultsModel.class,
                    "DefaultsModel");

    private static void saveDefault(Context context, DefaultsModel defaults) {
        shared.set(context, Definitions.SHARED_DEFAULTS, "Defaults", defaults);
    }

    public static DefaultsModel getDefaults(Context context){
        if (instance == null)
            instance = shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");

        return instance == null ? new DefaultsModel() : instance;
    }

    public static String getDefaultIcon(Context context){
        DefaultsModel defaults = getDefaults(context);
        return (defaults != null) ? defaults.appIcon : null;
    }

    public static void setDefaultIcon(Context context, String appIcon){
        DefaultsModel defaults = getDefaults(context);
        defaults.appIcon = appIcon;
        saveDefault(context, defaults);
    }

    public static Long getSilentCallbackDispatcher(Context context) {
        DefaultsModel defaults = getDefaults(context);
        return Long.parseLong(defaults.silentDataCallback);
    }

    public static void setActionCallbackDispatcher(Context context, Long silentDataCallback) {
        DefaultsModel defaults = getDefaults(context);
        defaults.silentDataCallback = silentDataCallback.toString();
        saveDefault(context, defaults);
    }

    public static Long getDartCallbackDispatcher(Context context) {
        DefaultsModel defaults = getDefaults(context);
        return Long.parseLong(defaults.reverseDartCallback);
    }

    public static void setDartCallbackDispatcher(Context context, Long reverseDartCallback) {
        DefaultsModel defaults = getDefaults(context);
        defaults.reverseDartCallback = reverseDartCallback.toString();
        saveDefault(context, defaults);
    }

    public static String getAwesomeExtensionClassName(Context context) {
        DefaultsModel defaults = getDefaults(context);
        return defaults.backgroundHandleClass;
    }

    public static void setAwesomeExtensionClassName(Context context, Class<? extends AwesomeNotificationsPlugin> backgroundHandleClass) {
        DefaultsModel defaults = getDefaults(context);
        defaults.backgroundHandleClass = backgroundHandleClass.getName();
        saveDefault(context, defaults);
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }
}
