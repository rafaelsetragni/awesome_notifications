package me.carda.awesome_notifications.awesome_notifications_android_core;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import androidx.lifecycle.Lifecycle;

import me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers.AwesomeEventsReceiver;
import me.carda.awesome_notifications.awesome_notifications_android_core.decoders.BitmapResourceDecoder;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.MediaSource;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_android_core.notifications.NotificationSender;
import me.carda.awesome_notifications.awesome_notifications_android_core.observers.AwesomeActionEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.observers.AwesomeLifeCycleEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.observers.AwesomeNotificationEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.observers.AwesomeEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.BadgeManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.CancellationManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.ChannelGroupManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.ChannelManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.CreatedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DefaultsManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DismissedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DisplayedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.LifeCycleManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.PermissionManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.ScheduleManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.DefaultsModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationChannelGroupModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationChannelModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationScheduleModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.services.ForegroundService;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.BitmapUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.BooleanUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.DateUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.JsonUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.ListUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public class AwesomeNotifications
        implements AwesomeNotificationEventListener, AwesomeActionEventListener, AwesomeLifeCycleEventListener {

    private static final String TAG = "AwesomeNotifications";

    public static Boolean debug = false;

    private Context applicationContext;
    private Activity applicationActivity;

    // ************** SINGLETON PATTERN ***********************

    public AwesomeNotifications(Context applicationContext) {
        LifeCycleManager
                .getInstance()
                .subscribe(this)
                .startListeners(applicationContext);
    }

    public void dispose(){
        LifeCycleManager
                .getInstance()
                .unsubscribe(this);
    }

    // ********************************************************

    /// **************  EVENT INTERFACES  *********************

    @Override
    public void onNewActionReceived(String eventName, ActionReceived actionReceived) {
        notifyActionEvent(eventName, actionReceived);
    }

    @Override
    public void onNewNotificationReceived(String eventName, NotificationReceived notificationReceived) {
        notifyNotificationEvent(eventName, notificationReceived);
    }

    private boolean activityHasStarted = false;
    @Override
    public void onNewLifeCycleEvent(Lifecycle.State androidLifeCycleState, Activity activity) {

        if(!activityHasStarted && androidLifeCycleState != Lifecycle.State.DESTROYED){
            applicationActivity = activity;
            applicationContext = activity.getApplicationContext();
        }

        switch (androidLifeCycleState){

            case RESUMED:
                PermissionManager
                        .getInstance()
                        .handlePermissionResult(
                                PermissionManager.REQUEST_CODE,
                                null,
                                null);
                break;

            case STARTED:
                activityHasStarted = true;

                applicationActivity = activity;
                applicationContext = activity.getApplicationContext();

                AwesomeEventsReceiver
                        .getInstance()
                        .subscribeOnNotificationEvents(this)
                        .subscribeOnActionEvents(this);
                break;

            case CREATED:
                NotificationBuilder
                        .getInstance()
                        .updateMainTargetClassName(activity);
                break;

            case DESTROYED:
                if(activityHasStarted)
                    AwesomeEventsReceiver
                            .getInstance()
                            .unsubscribeOnNotificationEvents(this)
                            .unsubscribeOnActionEvents(this);
                break;

            default:
                break;
        }
    }

    // ********************************************************

    /// **************  OBSERVER PATTERN  *********************

    static List<AwesomeNotificationEventListener> notificationEventListeners = new ArrayList<>();
    public AwesomeNotifications subscribeOnNotificationEvents(AwesomeNotificationEventListener listener) {
        notificationEventListeners.add(listener);
        return this;
    }
    public AwesomeNotifications unsubscribeOnNotificationEvents(AwesomeNotificationEventListener listener) {
        notificationEventListeners.remove(listener);
        return this;
    }
    private void notifyNotificationEvent(String eventName, NotificationReceived notificationReceived) {
        notifyAwesomeEvent(eventName, notificationReceived);
        for (AwesomeNotificationEventListener listener : notificationEventListeners)
            listener.onNewNotificationReceived(eventName, notificationReceived);
    }

    // ********************************************************

    static List<AwesomeActionEventListener> notificationActionListeners = new ArrayList<>();
    public AwesomeNotifications subscribeOnActionEvents(AwesomeActionEventListener listener) {
        notificationActionListeners.add(listener);
        return this;
    }
    public AwesomeNotifications unsubscribeOnActionEvents(AwesomeActionEventListener listener) {
        notificationActionListeners.remove(listener);
        return this;
    }
    private void notifyActionEvent(String eventName, ActionReceived actionReceived) {
        notifyAwesomeEvent(eventName, actionReceived);
        for (AwesomeActionEventListener listener : notificationActionListeners)
            listener.onNewActionReceived(eventName, actionReceived);
    }

    // ********************************************************

    static List<AwesomeEventListener> awesomeEventListeners = new ArrayList<>();
    public AwesomeNotifications subscribeOnAwesomeNotificationEvents(AwesomeEventListener listener) {
        awesomeEventListeners.add(listener);
        return this;
    }
    public AwesomeNotifications unsubscribeOnAwesomeNotificationEvents(AwesomeEventListener listener) {
        awesomeEventListeners.remove(listener);
        return this;
    }
    private void notifyAwesomeEvent(String eventName, ActionReceived actionReceived) {
        for (AwesomeEventListener listener : awesomeEventListeners)
            listener.onNewAwesomeEvent(eventName, (Serializable) actionReceived.toMap());
    }
    private void notifyAwesomeEvent(String eventName, NotificationReceived notificationReceived) {
        for (AwesomeEventListener listener : awesomeEventListeners)
            listener.onNewAwesomeEvent(eventName, (Serializable) notificationReceived.toMap());
    }
    private void notifyAwesomeEvent(String eventName, Serializable content) {
        for (AwesomeEventListener listener : awesomeEventListeners)
            listener.onNewAwesomeEvent(eventName, content);
    }

    /// ***********************************

    public static NotificationLifeCycle getApplicationLifeCycle(){
        return LifeCycleManager.getApplicationLifeCycle();
    }

    public void getDrawableData(String bitmapReference, BitmapCompletionHandler completionHandler){
        BitmapResourceDecoder bitmapResourceDecoder =
                new BitmapResourceDecoder(
                        applicationContext,
                        bitmapReference,
                        completionHandler);

        bitmapResourceDecoder.execute();
    }

    public void SetActionHandle(long silentCallback) {
        setActionHandleDefaults(
                applicationContext,
                silentCallback);
    }

    public List<NotificationModel> listAllPendingSchedules(){
        return ScheduleManager.listSchedules(applicationContext);
    }

    public void initialize(
            @Nullable String defaultIconPath,
            @Nullable List<Object> channelsData,
            @Nullable List<Object> channelGroupsData,
            long dartCallback,
            boolean debug) throws AwesomeNotificationException {

        setDefaults(applicationContext, defaultIconPath, dartCallback);

        if (ListUtils.isNullOrEmpty(channelGroupsData))
            setChannelGroups(applicationContext, channelGroupsData);

        if (ListUtils.isNullOrEmpty(channelsData))
            throw new AwesomeNotificationException("At least one channel is required");

        setChannels(applicationContext, channelsData);
        recoverNotificationCreated(applicationContext);
        recoverNotificationDisplayed(applicationContext);
        recoverNotificationDismissed(applicationContext);

        captureNotificationActionOnLaunch(applicationContext);

        AwesomeNotifications.debug = debug;

        if (AwesomeNotifications.debug)
            Log.d(TAG, "Awesome Notifications initialized");
    }

    private void setChannelGroups(
            @NonNull Context context,
            @NonNull List<Object> channelGroupsData)
                throws AwesomeNotificationException {

        List<NotificationChannelGroupModel> channelGroups = new ArrayList<>();

        for (Object channelDataObject : channelGroupsData)
            if (channelDataObject instanceof Map<?, ?>) {
                @SuppressWarnings("unchecked")
                Map<String, Object> channelData = (Map<String, Object>) channelDataObject;
                NotificationChannelGroupModel channelGroup =
                        new NotificationChannelGroupModel().fromMap(channelData);

                if (channelGroup != null) {
                    channelGroups.add(channelGroup);
                } else {
                    throw new AwesomeNotificationException(
                            "Invalid channel group: " + JsonUtils.toJson(channelData));
                }
            }

        for (NotificationChannelGroupModel channelGroupModel : channelGroups)
            ChannelGroupManager.saveChannelGroup(context, channelGroupModel);

        ChannelManager
                .getInstance()
                .commitChanges(context);
    }

    private void setChannels(
            @NonNull Context context,
            @NonNull List<Object> channelsData)
                throws AwesomeNotificationException {

        List<NotificationChannelModel> channels = new ArrayList<>();
        boolean forceUpdate = false;

        for (Object channelDataObject : channelsData)
            if (channelDataObject instanceof Map<?, ?>) {
                @SuppressWarnings("unchecked")
                Map<String, Object> channelData = (Map<String, Object>) channelDataObject;
                NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);
                forceUpdate = BooleanUtils.getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

                if (channelModel != null) {
                    channels.add(channelModel);
                } else {
                    throw new AwesomeNotificationException("Invalid channel: " + JsonUtils.toJson(channelData));
                }
            }

        ChannelManager channelManager = ChannelManager.getInstance();
        for (NotificationChannelModel channelModel : channels)
            channelManager.saveChannel(context, channelModel, false, forceUpdate);

        channelManager.commitChanges(context);
    }

    private void setDefaults(@NonNull Context context, @Nullable String defaultIcon, long dartCallbackHandle) {

        if (BitmapUtils.getInstance().getMediaSourceType(defaultIcon) != MediaSource.Resource)
            defaultIcon = null;

        DefaultsManager.saveDefault(context, new DefaultsModel(defaultIcon, dartCallbackHandle));
        DefaultsManager.commitChanges(context);
    }

    private void setActionHandleDefaults(@NonNull Context context, long silentCallbackHandle) {
        DefaultsModel defaults = DefaultsManager.getDefaultByKey(context);
        defaults.silentDataCallback = silentCallbackHandle;

        DefaultsManager.saveDefault(context, defaults);
        DefaultsManager.commitChanges(context);
    }

    private void recoverNotificationCreated(@NonNull Context context) {
        List<NotificationReceived> lostCreated = CreatedManager.listCreated(context);

        if (lostCreated != null)
            for (NotificationReceived created : lostCreated)
                try {

                    created.validate(context);

                    notifyAwesomeEvent(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, created);

                    CreatedManager.removeCreated(context, created.id);
                    CreatedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void recoverNotificationDisplayed(@NonNull Context context) {
        List<NotificationReceived> lostDisplayed = DisplayedManager.listDisplayed(context);

        if (lostDisplayed != null)
            for (NotificationReceived displayed : lostDisplayed)
                try {
                    displayed.validate(context);

                    notifyAwesomeEvent(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, displayed);

                    DisplayedManager.removeDisplayed(context, displayed.id);
                    DisplayedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void recoverNotificationDismissed(@NonNull Context context) {
        List<ActionReceived> lostDismissed = DismissedManager.listDismissed(context);

        if (lostDismissed != null)
            for (ActionReceived received : lostDismissed)
                try {
                    received.validate(context);
                    notifyAwesomeEvent(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, received);

                    DismissedManager.removeDismissed(context, received.id);
                    DismissedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void captureNotificationActionOnLaunch(@NonNull Context applicationContext) throws AwesomeNotificationException {

        String packageName = applicationContext.getPackageName();

        Intent launchIntent =
                applicationContext
                        .getPackageManager()
                        .getLaunchIntentForPackage(packageName);

        if (launchIntent == null)
            return;

        String actionName = launchIntent.getAction();
        if (actionName == null)
            return;

        Boolean isStandardAction = Definitions.SELECT_NOTIFICATION.equals(actionName);
        Boolean isButtonAction = actionName.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isStandardAction || isButtonAction)
            receiveNotificationAction(launchIntent, NotificationLifeCycle.AppKilled);
    }

    public boolean createNotification(@NonNull NotificationModel notificationModel) throws AwesomeNotificationException {

        if (!PermissionManager
                .getInstance()
                .areNotificationsGloballyAllowed(applicationContext))
            throw new AwesomeNotificationException("Notifications are disabled");

        if (notificationModel.schedule == null)
            NotificationSender
                    .send(
                        applicationContext,
                        NotificationBuilder.getInstance(),
                        NotificationSource.Local,
                        AwesomeNotifications.getApplicationLifeCycle(),
                        notificationModel);
        else
            NotificationScheduler
                    .schedule(
                        applicationContext,
                        NotificationSource.Schedule,
                        notificationModel);

        return true;
    }

    public boolean setChannel(@NonNull NotificationChannelModel channelModel, boolean forceUpdate)
            throws AwesomeNotificationException {

        ChannelManager
                .getInstance()
                .saveChannel(applicationContext, channelModel, forceUpdate)
                .commitChanges(applicationContext);

        return true;
    }

    public boolean removeChannel(@NonNull String channelKey) {
        boolean removed = ChannelManager
                .getInstance()
                .removeChannel(applicationContext, channelKey);

        ChannelManager
                .getInstance()
                .commitChanges(applicationContext);

        return removed;
    }

    public void startForegroundService(
            @NonNull NotificationModel notificationModel,
            int startType,
            boolean hasForegroundServiceType,
            int foregroundServiceType) {

        ForegroundService.ForegroundServiceIntent foregroundServiceIntent =
                new ForegroundService
                        .ForegroundServiceIntent(
                            notificationModel,
                            startType,
                            hasForegroundServiceType,
                            foregroundServiceType);

        Intent intent = new Intent(applicationContext, ForegroundService.class);
        intent.putExtra(Definitions.AWESOME_FOREGROUND_ID, foregroundServiceIntent);

        if (Build.VERSION.SDK_INT >=  Build.VERSION_CODES.O /*Android 8*/) {
            applicationContext.startForegroundService(intent);
        } else {
            applicationContext.startService(intent);
        }
    }

    public void stopForegroundService() {
        applicationContext
                .stopService(new Intent(applicationContext, ForegroundService.class));
    }

    private Boolean receiveNotificationAction(@NonNull Intent intent, @NonNull NotificationLifeCycle appLifeCycle) throws AwesomeNotificationException {

        ActionReceived actionModel =
                NotificationBuilder
                        .getInstance()
                        .receiveNotificationActionFromIntent(
                                applicationContext,
                                intent,
                                appLifeCycle);

        if (actionModel == null)
            return false;

        return receiveNotificationAction(actionModel);
    }

    private Boolean receiveNotificationAction(@NonNull ActionReceived actionModel) throws AwesomeNotificationException {

        actionModel.validate(applicationContext);

        notifyAwesomeEvent(Definitions.CHANNEL_METHOD_DEFAULT_ACTION, actionModel);

        if (AwesomeNotifications.debug)
            Log.d(TAG, "Notification action received");

        return true;
    }

    public Calendar getNextValidDate(@NonNull NotificationScheduleModel scheduleModel, @Nullable Date fixedDate) throws AwesomeNotificationException {
        return scheduleModel.getNextValidDate(fixedDate);
    }

    public String getLocalTimeZone() {
        return DateUtils.localTimeZone.getID();
    }

    public Object getUtcTimeZone() {
        return DateUtils.utcTimeZone.getID();
    }

    public int getGlobalBadgeCounter() {
        return BadgeManager.getGlobalBadgeCounter(applicationContext);
    }

    public void setGlobalBadgeCounter(@NonNull Integer count) {
        // Android resets badges automatically when all notifications are cleared
        BadgeManager.setGlobalBadgeCounter(applicationContext, count);
    }

    public void resetGlobalBadgeCounter() {
        BadgeManager.resetGlobalBadgeCounter(applicationContext);
    }

    public int incrementGlobalBadgeCounter() {
        return BadgeManager.incrementGlobalBadgeCounter(applicationContext);
    }

    public int decrementGlobalBadgeCounter() {
        return BadgeManager.decrementGlobalBadgeCounter(applicationContext);
    }

    public boolean dismissNotification(@NonNull Integer notificationId) throws AwesomeNotificationException {
        return CancellationManager.dismissNotification(applicationContext, notificationId);
    }

    public boolean cancelSchedule(@NonNull Integer notificationId) throws AwesomeNotificationException {
        return CancellationManager.cancelSchedule(applicationContext, notificationId);
    }

    public boolean cancelNotification(@NonNull Integer notificationId) throws AwesomeNotificationException {
        return CancellationManager.cancelNotification(applicationContext, notificationId);
    }

    public boolean dismissNotificationsByChannelKey(@NonNull String channelKey) throws AwesomeNotificationException {
        return CancellationManager.dismissNotificationsByChannelKey(applicationContext, channelKey);
    }

    public boolean cancelSchedulesByChannelKey(@NonNull String channelKey) throws AwesomeNotificationException {
        return CancellationManager.cancelSchedulesByChannelKey(applicationContext, channelKey);
    }

    public boolean cancelNotificationsByChannelKey(@NonNull String channelKey) throws AwesomeNotificationException {
        return CancellationManager.cancelNotificationsByChannelKey(applicationContext, channelKey);
    }

    public boolean dismissNotificationsByGroupKey(@NonNull String groupKey) throws AwesomeNotificationException {
        return CancellationManager.dismissNotificationsByGroupKey(applicationContext, groupKey);
    }

    public boolean cancelSchedulesByGroupKey(@NonNull String groupKey) throws AwesomeNotificationException {
        return CancellationManager.cancelSchedulesByGroupKey(applicationContext, groupKey);
    }

    public boolean cancelNotificationsByGroupKey(@NonNull String groupKey) throws AwesomeNotificationException {
        return CancellationManager.cancelNotificationsByGroupKey(applicationContext, groupKey);
    }

    public void dismissAllNotifications() {
        CancellationManager.dismissAllNotifications(applicationContext);
    }

    public void cancelAllSchedules() {
        CancellationManager.cancelAllSchedules(applicationContext);
    }

    public void cancelAllNotifications() {
        CancellationManager.cancelAllNotifications(applicationContext);
    }

    public Object areNotificationsGloballyAllowed() {
        return PermissionManager
                    .getInstance()
                    .areNotificationsGloballyAllowed(applicationContext);
    }

    public void showNotificationPage(@Nullable String channelKey, @NonNull PermissionCompletionHandler permissionCompletionHandler) {
        if(StringUtils.isNullOrEmpty(channelKey))
            PermissionManager
                .getInstance()
                .showNotificationConfigPage(
                        applicationContext,
                        permissionCompletionHandler);
        else
            PermissionManager
                .getInstance()
                .showChannelConfigPage(
                        applicationContext,
                        channelKey,
                        permissionCompletionHandler);
    }

    public void showPreciseAlarmPage(@NonNull PermissionCompletionHandler permissionCompletionHandler) {
        PermissionManager
            .getInstance()
            .showPreciseAlarmPage(
                    applicationContext,
                    permissionCompletionHandler);
    }

    public void showDnDGlobalOverridingPage(@NonNull PermissionCompletionHandler permissionCompletionHandler) {
        PermissionManager
            .getInstance()
            .showDnDGlobalOverridingPage(
                    applicationContext,
                    permissionCompletionHandler);
    }

    public List<String> arePermissionsAllowed(@Nullable String channelKey, @NonNull List<String> permissions) throws AwesomeNotificationException {
        return PermissionManager
                    .getInstance()
                    .arePermissionsAllowed(
                            applicationContext,
                            channelKey,
                            permissions);
    }

    public List<String> shouldShowRationale(@Nullable String channelKey, @NonNull List<String> permissions) throws AwesomeNotificationException {
        return PermissionManager
                    .getInstance()
                    .shouldShowRationale(
                            applicationContext,
                            channelKey,
                            permissions);
    }

    public void requestUserPermissions(
            @Nullable String channelKey,
            @NonNull List<String> permissions,
            @NonNull PermissionCompletionHandler permissionCompletionHandler)
            throws AwesomeNotificationException {

        PermissionManager
                .getInstance()
                .requestUserPermissions(
                        applicationActivity,
                        applicationContext,
                        channelKey,
                        permissions,
                        permissionCompletionHandler);
    }
}
