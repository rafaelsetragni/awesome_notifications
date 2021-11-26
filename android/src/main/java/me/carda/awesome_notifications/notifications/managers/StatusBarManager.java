package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import me.carda.awesome_notifications.notifications.NotificationScheduler;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.utils.StringUtils;

public class StatusBarManager {

    private static final String TAG = "CancellationManager";

    private final SharedPreferences preferences;
    public final Map<String, List<String>> activeNotificationsGroup;
    public final Map<String, List<String>> activeNotificationsChannel;

    private static StatusBarManager instance = null;
    private StatusBarManager(@NonNull final Context context) {

        preferences = context.getSharedPreferences(
                context.getPackageName() + "." + StringUtils.digestString(TAG),
                Context.MODE_PRIVATE
        );

        activeNotificationsGroup = loadNotificationIdFromPreferences("group");
        activeNotificationsChannel = loadNotificationIdFromPreferences("channel");
    }

    public static StatusBarManager getInstance(@NonNull final Context context) {
        if(instance == null)
            instance = new StatusBarManager(context);
        return instance;
    }

    public void registerActiveNotification(@NonNull NotificationModel notificationModel){

        SharedPreferences.Editor editor = preferences.edit();

        String idKey = notificationModel.content.id.toString();
        String groupKey = !StringUtils.isNullOrEmpty(notificationModel.content.groupKey) ? notificationModel.content.groupKey : "";
        String channelKey = !StringUtils.isNullOrEmpty(notificationModel.content.channelKey) ? notificationModel.content.channelKey : "";

        if(!channelKey.equals("")){
            registerNotificationIdOnPreferences(editor, "channel", activeNotificationsChannel, channelKey, idKey);
            editor.putString("ic:"+idKey, channelKey);
        }

        if(!groupKey.equals("")){
            registerNotificationIdOnPreferences(editor, "group", activeNotificationsGroup, groupKey, idKey);
            editor.putString("ig:"+idKey, groupKey);
        }

        editor.putBoolean("cl:"+groupKey, (
                notificationModel.content.notificationLayout != NotificationLayout.Default
            ));

        editor.apply();
    }

    public void unregisterActiveNotification(int notificationId){

        SharedPreferences.Editor editor = preferences.edit();

        String idKey = String.valueOf(notificationId);

        String groupKey = preferences.getString("ig:"+idKey, "");
        String channelKey = preferences.getString("ic:"+idKey, "");

        if(!groupKey.equals("")){
            boolean isCollapsedLayout = preferences.getBoolean("cl:"+groupKey, false);
            if(isCollapsedLayout){
                // For collapsed layouts, where the group turns 1 notification, the entire group should be removed
                unregisterActiveGroupKey(groupKey);
            }
            else {
                List<String> listToRemove = activeNotificationsGroup.get(groupKey);
                if(listToRemove != null){
                    listToRemove.remove(idKey);
                    if(listToRemove.isEmpty())
                        activeNotificationsGroup.remove(groupKey);
                    else
                        activeNotificationsGroup.put(groupKey, listToRemove);
                    saveActiveMapIntoPreferences(editor, "group", activeNotificationsGroup);
                }
            }
            editor.remove("ig:"+idKey);
        }

        if(!channelKey.equals("")){
            List<String> listToRemove = activeNotificationsChannel.get(channelKey);
            if(listToRemove != null){
                listToRemove.remove(idKey);
                if(listToRemove.isEmpty())
                    activeNotificationsChannel.remove(channelKey);
                else
                    activeNotificationsChannel.put(channelKey, listToRemove);
                saveActiveMapIntoPreferences(editor, "channel", activeNotificationsChannel);
            }
            editor.remove("ic:"+idKey);
        }

        editor.remove("cl:"+idKey);
        editor.apply();
    }

    public List<String> unregisterActiveChannelKey(String channelKey){

        if(!StringUtils.isNullOrEmpty(channelKey)){
            List<String> removed = activeNotificationsChannel.remove(channelKey);
            if(removed != null){
                SharedPreferences.Editor editor = preferences.edit();

                boolean hasGroup = false;
                for(String idKey : removed){
                    String groupKey = preferences.getString("ig:"+idKey, "");
                    if(!groupKey.equals("")){
                        editor.remove("cl:"+groupKey);
                        List<String> listToRemove = activeNotificationsGroup.get(groupKey);
                        if(listToRemove != null){
                            hasGroup = true;
                            listToRemove.remove(idKey);
                            if(listToRemove.isEmpty())
                                activeNotificationsGroup.remove(groupKey);
                            else
                                activeNotificationsGroup.put(channelKey, listToRemove);
                        }
                    }
                    editor.remove("ig:"+idKey);
                    editor.remove("ic:"+idKey);
                }

                saveActiveMapIntoPreferences(editor, "channel", activeNotificationsChannel);

                if(hasGroup)
                    saveActiveMapIntoPreferences(editor, "group", activeNotificationsGroup);

                editor.apply();
                return removed;
            }
        }

        return null;
    }

    public List<String> unregisterActiveGroupKey(String groupKey){

        if(!StringUtils.isNullOrEmpty(groupKey)){
            List<String> removed = activeNotificationsGroup.remove(groupKey);
            if(removed != null){
                SharedPreferences.Editor editor = preferences.edit();
                editor.remove("cl:"+groupKey);

                boolean hasGroup = false;
                for(String idKey : removed){
                    String channelKey = preferences.getString("ic:"+idKey, "");
                    if(!channelKey.equals("")){
                        List<String> listToRemove = activeNotificationsChannel.get(channelKey);
                        if(listToRemove != null){
                            hasGroup = true;
                            listToRemove.remove(idKey);
                            if(listToRemove.isEmpty())
                                activeNotificationsChannel.remove(channelKey);
                            else
                                activeNotificationsChannel.put(channelKey, listToRemove);
                        }
                    }
                    editor.remove("ig:"+idKey);
                    editor.remove("ic:"+idKey);
                    editor.remove("cl:"+idKey);
                }

                saveActiveMapIntoPreferences(editor, "group", activeNotificationsGroup);

                if(hasGroup)
                    saveActiveMapIntoPreferences(editor, "channel", activeNotificationsChannel);

                editor.apply();
                return removed;
            }
        }

        return null;
    }

    private void registerNotificationIdOnPreferences(SharedPreferences.Editor editor, String type, Map<String, List<String>> map, String reference, String notificationId){
        List<String> list = map.get(reference);

        if(list == null)
            list = new ArrayList<String>();

        if(!list.contains(notificationId))
            list.add(notificationId);

        map.put(reference, list);
        saveActiveMapIntoPreferences(editor, type, map);
    }

    private void saveActiveMapIntoPreferences(SharedPreferences.Editor editor, String type, Map<String, List<String>> map) {
        Gson gson = new Gson();
        String mapString = gson.toJson(map);
        editor.putString(type, mapString);
    }

    private Map<String, List<String>> loadNotificationIdFromPreferences(String type){
        String mapString = preferences.getString(type, null);

        if (mapString == null){
            return new HashMap<String, List<String>>();
        }

        Gson gson = new Gson();
        Type mapType = new TypeToken<HashMap<String, List<String>>>(){}.getType();

        return gson.fromJson(mapString, mapType);
    }

    public void resetRegisters(){
        preferences
                .edit()
                .clear()
                .apply();

        activeNotificationsGroup.clear();
        activeNotificationsChannel.clear();
    }
}
