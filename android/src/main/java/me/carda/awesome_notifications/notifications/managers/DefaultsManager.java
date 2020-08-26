package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;

import com.google.common.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.List;

import me.carda.awesome_notifications.Definitions;

public class DefaultsManager {

    private static SharedManager<String> shared = new SharedManager<>();
    private static Type typeToken = new TypeToken<String>(){}.getType();

    public static Boolean removeDefault(Context context, String key) {
        return shared.remove(context, Definitions.SHARED_DEFAULTS, key);
    }

    public static List<String> listDefaults(Context context) {
        return shared.getAllObjects(context, typeToken, Definitions.SHARED_DEFAULTS);
    }

    public static void saveDefault(Context context, String key, String data) {
        shared.set(context, Definitions.SHARED_DEFAULTS, key, data);
    }

    public static String getDefaultByKey(Context context, String key){
        return shared.get(context, typeToken, Definitions.SHARED_DEFAULTS, key);
    }
}
