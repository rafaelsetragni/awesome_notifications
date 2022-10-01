package me.carda.awesome_notifications.core.managers;

import android.app.AlarmManager;
import android.content.Context;
import android.content.SharedPreferences;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class ScheduleManager {

    private static final SharedManager<NotificationModel> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "ScheduleManager",
                    NotificationModel.class,
                    "NotificationModel");

    public static List<NotificationModel> listSchedules(Context context) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
    }

    public static NotificationModel getScheduleById(Context context, String Id) throws AwesomeNotificationsException {
        return shared.get(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, Id);
    }

    public static List<String> listScheduledIds(Context context) {
        return _getHelper(context, Definitions.SCHEDULER_HELPER_ALL, "");
    }

    public static List<String> listScheduledIdsFromChannel(Context context, String channelKey) {
        return _getHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey);
    }

    public static List<String> listScheduledIdsFromGroup(Context context, String groupKey) {
        return _getHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey);
    }

    public static Boolean removeSchedule(Context context, NotificationModel notificationModel) throws AwesomeNotificationsException {
        String targetId = notificationModel.content.id.toString();

        boolean successHelper =
                _removeHelperId(
                        context,
                        targetId,
                        notificationModel.content.channelKey,
                        notificationModel.content.groupKey);

        boolean successShared =
                _removeNotificationFromShared(
                        context,
                        targetId);

        return successHelper && successShared;
    }

    public static Boolean saveSchedule(Context context, NotificationModel notificationModel) throws AwesomeNotificationsException {
        String targetId = notificationModel.content.id.toString();

        boolean successHelper =
                _setHelperId(
                        context,
                        targetId,
                        notificationModel.content.channelKey,
                        notificationModel.content.groupKey);

        boolean successShared =
                _setNotificationOnShared(
                        context,
                        targetId,
                        notificationModel);

        return successHelper && successShared;
    }

    public static void cancelScheduleById(Context context, String id) throws AwesomeNotificationsException {
        NotificationModel schedule = getScheduleById(context, id);
        if(schedule != null)
            removeSchedule(context, schedule);
        else {
            _removeNotificationFromShared(
                context,
                id);
        }
    }

    public static void cancelSchedulesByChannelKey(Context context, String channelKey) throws AwesomeNotificationsException {
        List<String> allIds = _getHelper(context, Definitions.SCHEDULER_HELPER_ALL, "");
        List<String> channelIds = _getHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey);

        for (String targetId : channelIds) {
            allIds.remove(targetId);
            _removeNotificationFromShared(
                    context,
                    targetId);
        }

        _updateHelper(context, Definitions.SCHEDULER_HELPER_ALL, "", allIds);
        _removeHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey);
    }

    public static void cancelSchedulesByGroupKey(Context context, String groupKey) throws AwesomeNotificationsException {
        List<String> allIds = _getHelper(context, Definitions.SCHEDULER_HELPER_ALL, "");
        List<String> groupIds = _getHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey);

        for (String targetId : groupIds) {
            allIds.remove(targetId);
            _removeNotificationFromShared(
                    context,
                    targetId);
        }

        _updateHelper(context, Definitions.SCHEDULER_HELPER_ALL, "", allIds);
        _removeHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey);
    }

    public static void cancelAllSchedules(Context context) throws AwesomeNotificationsException {
        shared.removeAll(context);
        _removeAllHelpers(context, Definitions.SCHEDULER_HELPER_ALL);
        _removeAllHelpers(context, Definitions.SCHEDULER_HELPER_CHANNEL);
        _removeAllHelpers(context, Definitions.SCHEDULER_HELPER_GROUP);
    }

    public static AlarmManager getAlarmManager(Context context) {
        return (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
    }

    public static boolean isPreciseAlarmGloballyAllowed(Context context){
        AlarmManager alarmManager = getAlarmManager(context);
        return isPreciseAlarmGloballyAllowed(alarmManager);
    }

    public static boolean isPreciseAlarmGloballyAllowed(AlarmManager alarmManager){
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S /*Android 12*/)
            return alarmManager.canScheduleExactAlarms();
        return true;
    }

    public static void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }

    private static boolean _setNotificationOnShared(Context context, String id, NotificationModel notificationModel) throws AwesomeNotificationsException {
        return shared.set(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, id, notificationModel);
    }

    private static boolean _removeNotificationFromShared(Context context, String targetId) throws AwesomeNotificationsException {
        return shared.remove(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, targetId);
    }

    private static boolean _setHelperId(Context context, String targetId, String channelKey, String groupKey){
        StringUtils stringUtils = StringUtils.getInstance();

        List<String> ids = _getHelper(context, Definitions.SCHEDULER_HELPER_ALL, "");
        ids.add(targetId);
        _updateHelper(context, Definitions.SCHEDULER_HELPER_ALL, "", ids);

        if(!stringUtils.isNullOrEmpty(channelKey)){
            List<String> channelIds = _getHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey);
            channelIds.add(targetId);
            _updateHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey, channelIds);
        }

        if(!stringUtils.isNullOrEmpty(groupKey)){
            List<String> groupIds = _getHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey);
            groupIds.add(targetId);
            _updateHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey, groupIds);
        }

        return true;
    }

    private static boolean _removeHelperId(Context context, String targetId, String channelKey, String groupKey){
        StringUtils stringUtils = StringUtils.getInstance();

        List<String> ids = _getHelper(context, Definitions.SCHEDULER_HELPER_ALL, "");
        ids.remove(targetId);
        _updateHelper(context, Definitions.SCHEDULER_HELPER_ALL, "", ids);

        if(!stringUtils.isNullOrEmpty(channelKey)){
            List<String> channelIds = _getHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey);
            channelIds.remove(targetId);
            _updateHelper(context, Definitions.SCHEDULER_HELPER_CHANNEL, channelKey, channelIds);
        }

        if(!stringUtils.isNullOrEmpty(groupKey)){
            List<String> groupIds = _getHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey);
            groupIds.remove(targetId);
            _updateHelper(context, Definitions.SCHEDULER_HELPER_GROUP, groupKey, groupIds);
        }

        return true;
    }

    private static List<String> _getHelper(Context context, String type, String referenceKey){

        SharedPreferences preferences = context.getSharedPreferences(
                AwesomeNotifications.getPackageName(context) + Definitions.SCHEDULER_HELPER_SHARED + type,
                Context.MODE_PRIVATE);

        ArrayList<String> ids = new ArrayList<String>();
        ids.addAll(preferences.getStringSet(referenceKey, new HashSet<String>()));

        return ids;
    }

    private static void _updateHelper(Context context, String type, String referenceKey, List<String> ids){

        SharedPreferences preferences = context.getSharedPreferences(
                AwesomeNotifications.getPackageName(context) + Definitions.SCHEDULER_HELPER_SHARED + type,
                Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = preferences.edit();
        editor.putStringSet(referenceKey, new HashSet<String>(ids));
        editor.apply();
    }

    private static void _removeHelper(Context context, String type, String referenceKey){

        SharedPreferences preferences = context.getSharedPreferences(
                AwesomeNotifications.getPackageName(context) + Definitions.SCHEDULER_HELPER_SHARED + type,
                Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = preferences.edit();
        editor.remove(referenceKey);
        editor.apply();
    }

    private static void _removeAllHelpers(Context context, String type){
        SharedPreferences preferences = context.getSharedPreferences(
                AwesomeNotifications.getPackageName(context) + Definitions.SCHEDULER_HELPER_SHARED + type,
                Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = preferences.edit();
        editor.clear();
        editor.apply();
    }
}
