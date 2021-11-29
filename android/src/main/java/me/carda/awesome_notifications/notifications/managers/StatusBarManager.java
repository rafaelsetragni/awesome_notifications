package me.carda.awesome_notifications.notifications.managers;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.service.notification.StatusBarNotification;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationManagerCompat;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.enumerators.ActionButtonType;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.utils.StringUtils;

import static android.content.Context.NOTIFICATION_SERVICE;

public class StatusBarManager {

    private static final String TAG = "CancellationManager";

    private final SharedPreferences preferences;
    public final Map<String, List<String>> activeNotificationsGroup;
    public final Map<String, List<String>> activeNotificationsChannel;

    @SuppressLint("StaticFieldLeak")
    private static StatusBarManager instance = null;

    private Context currentContext;

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
        instance.currentContext = context;
        return instance;
    }

    public void showNotificationOnStatusBar(NotificationModel notificationModel, Notification notification){

        registerActiveNotification(notificationModel, notificationModel.content.id);

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            NotificationManager notificationManager = getNotificationManager();
            notificationManager.notify(notificationModel.content.id, notification);
        }
        else {
            NotificationManagerCompat notificationManagerCompat = getAdaptedOldNotificationManager();
            notificationManagerCompat.notify(String.valueOf(notificationModel.content.id), notificationModel.content.id, notification);
        }
    }

    public void dismissNotification(Integer id) {

        String idKey = id.toString();
        int idKeyValue = Integer.parseInt(idKey);

        if (Build.VERSION.SDK_INT >=  Build.VERSION_CODES.O /*Android 8*/) {
            NotificationManager notificationManager = getNotificationManager();

            notificationManager.cancel(idKey, idKeyValue);
            notificationManager.cancel(idKeyValue);

            // Dismiss the last notification group summary notification
            String groupKey = getIndexActiveNotificationGroup(idKey);
            if (!groupKey.equals("")) {
                try {
                    dismissNotificationsByGroupKey(groupKey);
                } catch (AwesomeNotificationException ignored) {
                }
            }
        }
        else {
            NotificationManagerCompat notificationManager = getAdaptedOldNotificationManager();

            notificationManager.cancel(idKey, idKeyValue);
            notificationManager.cancel(idKeyValue);
        }

        unregisterActiveNotification(id);
    }

    public boolean dismissNotificationsByChannelKey(@NonNull final String channelKey) throws AwesomeNotificationException {

        List<String> notificationIds = unregisterActiveChannelKey(channelKey);

        if (notificationIds != null)
            for (String idKey : notificationIds)
                dismissNotification(Integer.parseInt(idKey));

        return notificationIds != null;
    }

    public boolean dismissNotificationsByGroupKey(@NonNull final String groupKey) throws AwesomeNotificationException {

        List<String> notificationIds = unregisterActiveGroupKey(groupKey);

        if (notificationIds != null)
            for (String idKey : notificationIds)
                dismissNotification(Integer.parseInt(idKey));

        return notificationIds != null;
    }

    public void dismissAllNotifications() {

        if (Build.VERSION.SDK_INT >=  Build.VERSION_CODES.O /*Android 8*/) {
            NotificationManagerCompat notificationManager = getAdaptedOldNotificationManager();
            notificationManager.cancelAll();
        }
        else {
            NotificationManager notificationManager = (NotificationManager) currentContext.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancelAll();
        }

        resetRegisters();
    }

    public boolean isFirstActiveOnGroupKey(String groupKey){
        if(StringUtils.isNullOrEmpty(groupKey))
            return false;

        List<String> activeGroupedNotifications =
                activeNotificationsGroup.get(groupKey);

        return activeGroupedNotifications == null || activeGroupedNotifications.size() == 0;
    }

    public boolean isFirstActiveOnChannelKey(String channelKey){
        if(StringUtils.isNullOrEmpty(channelKey))
            return false;

        List<String> activeGroupedNotifications =
                activeNotificationsChannel.get(channelKey);

        return activeGroupedNotifications == null || activeGroupedNotifications.size() == 0;
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private NotificationManager getNotificationManager() {
        return (NotificationManager) currentContext.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    private NotificationManagerCompat getAdaptedOldNotificationManager() {
        return NotificationManagerCompat.from(currentContext);
    }

    private void setIndexActiveNotificationChannel(SharedPreferences.Editor editor, String idKey, String channelKey){
        editor.putString("ic:"+idKey, channelKey);
    }

    private String getIndexActiveNotificationChannel(String idKey){
        return preferences.getString("ic:"+idKey, "");
    }

    private void removeIndexActiveNotificationChannel(SharedPreferences.Editor editor, String idKey){
        editor.remove("ic:"+idKey);
    }

    private void setIndexActiveNotificationGroup(SharedPreferences.Editor editor, String idKey, String groupKey){
        editor.putString("ig:"+idKey, groupKey);
    }

    private String getIndexActiveNotificationGroup(String idKey){
        return preferences.getString("ig:"+idKey, "");
    }

    private void removeIndexActiveNotificationGroup(SharedPreferences.Editor editor, String idKey){
        editor.remove("ig:"+idKey);
    }

    private void setIndexCollapsedLayout(SharedPreferences.Editor editor, String idKey, boolean isCollapsed){
        editor.putBoolean("cl:"+idKey, isCollapsed);
    }

    private boolean isIndexCollapsedLayout(String groupKey) {
        return preferences.getBoolean("cl:" + groupKey, false);
    }

    private void removeIndexCollapsedLayout(SharedPreferences.Editor editor, String idKey){
        editor.remove("cl:"+idKey);
    }

    private void registerActiveNotification(@NonNull NotificationModel notificationModel, int id){

        String idKey = String.valueOf(id);
        String groupKey = !StringUtils.isNullOrEmpty(notificationModel.content.groupKey) ? notificationModel.content.groupKey : "";
        String channelKey = !StringUtils.isNullOrEmpty(notificationModel.content.channelKey) ? notificationModel.content.channelKey : "";

        SharedPreferences.Editor editor = preferences.edit();

        if(!channelKey.equals("")){
            registerNotificationIdOnPreferences(editor, "channel", activeNotificationsChannel, channelKey, idKey);
            setIndexActiveNotificationChannel(editor, idKey, channelKey);
        }

        if(!groupKey.equals("")){
            registerNotificationIdOnPreferences(editor, "group", activeNotificationsGroup, groupKey, idKey);
            setIndexActiveNotificationGroup(editor, idKey, groupKey);
        }

        setIndexCollapsedLayout(editor, idKey, notificationModel.content.notificationLayout != NotificationLayout.Default);

        editor.apply();
    }

    private void registerNotificationIdOnPreferences(SharedPreferences.Editor editor, String type, Map<String, List<String>> map, String reference, String notificationId){
        List<String> list = map.get(reference);

        if(list == null)
            list = new ArrayList<String>();

        if(!list.contains(notificationId))
            list.add(notificationId);

        map.put(reference, list);
        updateActiveMapIntoPreferences(editor, type, map);
    }

    public void unregisterActiveNotification(int notificationId){

        SharedPreferences.Editor editor = preferences.edit();

        String idKey = String.valueOf(notificationId);
        String groupKey = getIndexActiveNotificationGroup(idKey);
        if(!groupKey.equals("")){

            List<String> listToRemove = activeNotificationsGroup.get(groupKey);
            if(listToRemove != null){
                if(listToRemove.remove(idKey)){
                    if(listToRemove.isEmpty())
                        activeNotificationsGroup.remove(groupKey);
                    else
                        activeNotificationsGroup.put(groupKey, listToRemove);
                    updateActiveMapIntoPreferences(editor, "group", activeNotificationsGroup);

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        boolean isCollapsedLayout = isIndexCollapsedLayout(groupKey);

                        // For collapsed layouts, where the group has 1 left notification,
                        // the missing summary orphan group should be removed
                        if(!isCollapsedLayout && listToRemove.size() == 1)
                            dismissNotification(Integer.parseInt(listToRemove.get(0)));
                    }
                }
            }
        }

        String channelKey = getIndexActiveNotificationChannel(idKey);
        if(!channelKey.equals("")){
            List<String> listToRemove = activeNotificationsChannel.get(channelKey);
            if(listToRemove != null){
                listToRemove.remove(idKey);
                if(listToRemove.isEmpty())
                    activeNotificationsChannel.remove(channelKey);
                else
                    activeNotificationsChannel.put(channelKey, listToRemove);
                updateActiveMapIntoPreferences(editor, "channel", activeNotificationsChannel);
            }
        }

        removeAllIndexes(editor, idKey);
        editor.apply();
    }

    private void removeAllIndexes(SharedPreferences.Editor editor, String idKey){
        removeIndexActiveNotificationChannel(editor, idKey);
        removeIndexActiveNotificationGroup(editor, idKey);
        removeIndexCollapsedLayout(editor, idKey);
    }

    private List<String> unregisterActiveChannelKey(String channelKey){

        if(!StringUtils.isNullOrEmpty(channelKey)){
            List<String> removed = activeNotificationsChannel.remove(channelKey);
            if(removed != null){

                SharedPreferences.Editor editor = preferences.edit();

                boolean hasGroup = false;
                for(String idKey : removed){
                    String groupKey = getIndexActiveNotificationGroup(idKey);
                    if(!groupKey.equals("")){
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
                    removeAllIndexes(editor, idKey);
                }

                updateActiveMapIntoPreferences(editor, "channel", activeNotificationsChannel);
                if(hasGroup)
                    updateActiveMapIntoPreferences(editor, "group", activeNotificationsGroup);

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

                boolean hasGroup = false;
                for(String idKey : removed){
                    String channelKey = getIndexActiveNotificationChannel(idKey);
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
                    removeAllIndexes(editor, idKey);
                }

                updateActiveMapIntoPreferences(editor, "group", activeNotificationsGroup);
                if(hasGroup)
                    updateActiveMapIntoPreferences(editor, "channel", activeNotificationsChannel);

                editor.apply();
                return removed;
            }
        }

        return null;
    }

    private void updateActiveMapIntoPreferences(SharedPreferences.Editor editor, String type, Map<String, List<String>> map) {
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

    private void resetRegisters(){
        preferences
                .edit()
                .clear()
                .apply();

        activeNotificationsGroup.clear();
        activeNotificationsChannel.clear();
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    public static Notification getAndroidNotificationById(Context context, int id){
        if(context != null){

            NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {
                    if(activeNotification.getId() == id){
                        return activeNotification.getNotification();
                    }
                }
            }
        }
        return null;
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    public static List<Notification> getAllAndroidActiveNotificationsByChannelKey(Context context, String channelKey){
        List<Notification> notifications = new ArrayList<>();
        if(context != null && !StringUtils.isNullOrEmpty(channelKey)){

            NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            String hashedKey = StringUtils.digestString(channelKey);

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {

                    Notification notification = activeNotification.getNotification();

                    String notificationChannelKey = notification.extras
                            .getString(Definitions.NOTIFICATION_CHANNEL_KEY);

                    if(notificationChannelKey != null && notificationChannelKey.equals(hashedKey)){
                        notifications.add(notification);
                    }
                }
            }
        }
        return notifications;
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    public static List<Notification> getAllAndroidActiveNotificationsByGroupKey(Context context, String groupKey){
        List<Notification> notifications = new ArrayList<>();
        if(context != null && !StringUtils.isNullOrEmpty(groupKey)){

            NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            String hashedKey = StringUtils.digestString(groupKey);

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {

                    Notification notification = activeNotification.getNotification();

                    String notificationGroupKey = notification.extras
                            .getString(Definitions.NOTIFICATION_GROUP_KEY);

                    if(notificationGroupKey != null && notificationGroupKey.equals(hashedKey)){
                        notifications.add(notification);
                    }
                }
            }
        }
        return notifications;
    }
}
