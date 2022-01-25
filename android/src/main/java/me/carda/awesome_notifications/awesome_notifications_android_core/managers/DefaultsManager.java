package me.carda.awesome_notifications.awesome_notifications_android_core.managers;

import android.content.Context;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.DefaultsModel;

public class DefaultsManager {

    private static final SharedManager<DefaultsModel> shared
            = new SharedManager<>(
                    "DefaultsManager",
                    DefaultsModel.class,
                    "DefaultsModel");

    public static Boolean removeDefault(Context context) {
        return shared.remove(context, Definitions.SHARED_DEFAULTS, "Defaults");
    }

    public static void saveDefault(Context context, DefaultsModel defaults) {
        shared.set(context, Definitions.SHARED_DEFAULTS, "Defaults", defaults);
    }

    public static DefaultsModel getDefaultByKey(Context context){
        return shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");
    }

    public static String getDefaultIconByKey(Context context){
        DefaultsModel defaults = shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");
        return (defaults != null) ? defaults.appIcon : null;
    }

    public static Long getSilentCallbackDispatcher(Context context) {
        DefaultsModel defaults = shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");
        return (defaults != null) ? Long.parseLong(defaults.silentDataCallback) : 0L;
    }

    public static Long getDartCallbackDispatcher(Context context) {
        DefaultsModel defaults = shared.get(context, Definitions.SHARED_DEFAULTS, "Defaults");
        return (defaults != null) ? Long.parseLong(defaults.reverseDartCallback) : 0L;
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }
}
