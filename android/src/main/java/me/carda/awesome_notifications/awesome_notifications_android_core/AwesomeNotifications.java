package me.carda.awesome_notifications.awesome_notifications_android_core;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.support.v4.media.session.MediaSessionCompat;
import android.util.Log;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import androidx.lifecycle.Lifecycle;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers.AwesomeEventsReceiver;
import me.carda.awesome_notifications.awesome_notifications_android_core.decoders.BitmapResourceDecoder;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.ForegroundStartMode;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.MediaSource;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.ActionManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DismissedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.AbstractModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_android_core.threads.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_android_core.threads.NotificationSender;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeActionEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeLifeCycleEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeNotificationEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.listeners.AwesomeEventListener;
import me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_android_core.completion_handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.BadgeManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.CancellationManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.ChannelGroupManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.ChannelManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.CreatedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DefaultsManager;
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

    private WeakReference<Context> wContext;
    private Activity applicationActivity;

    // ************************** CONSTRUCTOR ***********************************

    public AwesomeNotifications(
        @NonNull Context applicationContext,
        @NonNull AwesomeNotificationsPlugin extensionClass
    ) throws AwesomeNotificationException {

        wContext = new WeakReference<>(applicationContext);

        LifeCycleManager
                .getInstance()
                .subscribe(this)
                .startListeners(applicationContext);

        AbstractModel
                .defaultValues
                .putAll(Definitions.initialValues);

        DefaultsManager.setAwesomeExtensionClassName(
                applicationContext,
                extensionClass.getClass());

        loadAwesomeExtensions(applicationContext);
    }

    // ******************** LOAD EXTERNAL EXTENSIONS ***************************

    public static boolean isExtensionsLoaded = false;
    public static void loadAwesomeExtensions(
        @NonNull Context context
    ) throws AwesomeNotificationException {

        if(isExtensionsLoaded) return;

        try {
            Class.forName("dalvik.system.CloseGuard")
                    .getMethod("setEnabled", boolean.class)
                    .invoke(null, true);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }

        String extensionClassReference = DefaultsManager.getAwesomeExtensionClassName(context);
        if(!StringUtils.isNullOrEmpty(extensionClassReference))
            try {
                Class extensionClass =
                        Class.forName(extensionClassReference);

                loadAwesomeExtensions(
                        context,
                        extensionClass);

                isExtensionsLoaded = true;
                return;

            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }

        throw new AwesomeNotificationException("Awesome plugin reference is invalid or not found");
    }

    public static void loadAwesomeExtensions(
            @NonNull Context context,
            @NonNull Class<? extends AwesomeNotificationsPlugin> extensionClass
    ) throws AwesomeNotificationException {

        if(isExtensionsLoaded) return;

        try {

            AwesomeNotificationsPlugin awesomePlugin = extensionClass.newInstance();
            awesomePlugin.loadExternalExtensions(context);
            isExtensionsLoaded = true;

        } catch (IllegalAccessException | InstantiationException e) {
            e.printStackTrace();
            throw new AwesomeNotificationException(
                    "Awesome plugin extensions could not be loaded.");
        }
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
            wContext = new WeakReference<>(activity.getApplicationContext());
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
                applicationActivity = activity;
                wContext = new WeakReference<>(activity.getApplicationContext());

                if(!activityHasStarted)
                    AwesomeEventsReceiver
                            .getInstance()
                            .subscribeOnNotificationEvents(this)
                            .subscribeOnActionEvents(this);

                activityHasStarted = true;
                break;

            case CREATED:
                NotificationBuilder
                        .setMediaSession(
                                new MediaSessionCompat(
                                        activity.getApplicationContext(),
                                        "PUSH_MEDIA"));
                NotificationBuilder
                        .getNewBuilder()
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
            listener.onNewAwesomeEvent(eventName, actionReceived.toMap());
    }

    private void notifyAwesomeEvent(String eventName, NotificationReceived notificationReceived) {
        for (AwesomeEventListener listener : awesomeEventListeners)
            listener.onNewAwesomeEvent(eventName, notificationReceived.toMap());
    }

    private void notifyAwesomeEvent(String eventName, Map<String, Object> content) {
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
                        wContext.get(),
                        bitmapReference,
                        completionHandler);

        bitmapResourceDecoder.execute();
    }

    public void setActionHandle(Long silentCallback) {
        setActionHandleDefaults(
                wContext.get(),
                silentCallback);

        recoverNotificationActions(wContext.get());
    }

    public Long getActionHandle() {
        return getActionHandleDefaults(
                wContext.get());
    }

    public List<NotificationModel> listAllPendingSchedules(){
        return ScheduleManager.listSchedules(wContext.get());
    }

    public void initialize(
            @Nullable String defaultIconPath,
            @Nullable List<Object> channelsData,
            @Nullable List<Object> channelGroupsData,
            Long dartCallback,
            boolean debug
    ) throws AwesomeNotificationException {

        setDefaults(
                wContext.get(),
                defaultIconPath,
                dartCallback);

        if (ListUtils.isNullOrEmpty(channelGroupsData))
            setChannelGroups(wContext.get(), channelGroupsData);

        if (ListUtils.isNullOrEmpty(channelsData))
            throw new AwesomeNotificationException("At least one channel is required");

        setChannels(wContext.get(), channelsData);
        recoverNotificationCreated(wContext.get());
        recoverNotificationDisplayed(wContext.get());
        recoverNotificationsDismissed(wContext.get());

        captureNotificationActionOnLaunch(wContext.get());

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
                forceUpdate = BooleanUtils.getInstance().getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

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

    private void setDefaults(@NonNull Context context, @Nullable String defaultIcon, Long dartCallbackHandle) {

        if (BitmapUtils.getInstance().getMediaSourceType(defaultIcon) != MediaSource.Resource)
            defaultIcon = null;

        DefaultsManager.setDefaultIcon(context, defaultIcon);
        DefaultsManager.setDartCallbackDispatcher(context, dartCallbackHandle);
        DefaultsManager.commitChanges(context);
    }

    private void setActionHandleDefaults(@NonNull Context context, Long silentCallbackHandle) {
        DefaultsManager.setSilentCallbackDispatcher(context, silentCallbackHandle);
        DefaultsManager.commitChanges(context);
    }

    private Long getActionHandleDefaults(@NonNull Context context) {
        DefaultsModel defaults = DefaultsManager.getDefaults(context);
        return defaults.silentDataCallback == null ?
                0L : Long.parseLong(defaults.silentDataCallback);
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

    private void recoverNotificationActions(@NonNull Context context) {
        List<ActionReceived> lostActions = ActionManager.listActions(context);

        if (lostActions != null)
            for (ActionReceived received : lostActions)
                try {
                    received.validate(context);

                    notifyAwesomeEvent(Definitions.CHANNEL_METHOD_DEFAULT_ACTION, received);

                    ActionManager.removeAction(context, received.id);
                    ActionManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void recoverNotificationsDismissed(@NonNull Context context) {
        List<ActionReceived> lostDismissed = DismissedManager.listDismisses(context);

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
                .areNotificationsGloballyAllowed(wContext.get()))
            throw new AwesomeNotificationException("Notifications are disabled");

        if (notificationModel.schedule == null)
            NotificationSender
                    .send(
                            wContext.get(),
                        NotificationBuilder.getNewBuilder(),
                        NotificationSource.Local,
                        AwesomeNotifications.getApplicationLifeCycle(),
                        notificationModel);
        else
            NotificationScheduler
                    .schedule(
                            wContext.get(),
                        NotificationSource.Schedule,
                        notificationModel);

        return true;
    }

    public boolean setChannel(@NonNull NotificationChannelModel channelModel, boolean forceUpdate)
            throws AwesomeNotificationException {

        ChannelManager
                .getInstance()
                .saveChannel(wContext.get(), channelModel, forceUpdate)
                .commitChanges(wContext.get());

        return true;
    }

    public boolean removeChannel(@NonNull String channelKey) {
        boolean removed = ChannelManager
                .getInstance()
                .removeChannel(wContext.get(), channelKey);

        ChannelManager
                .getInstance()
                .commitChanges(wContext.get());

        return removed;
    }

    public void startForegroundService(
            @NonNull NotificationModel notificationModel,
            @NonNull ForegroundStartMode startMode,
            @NonNull ForegroundServiceType foregroundServiceType
    ){
        ForegroundService.startNewForegroundService(
                wContext.get(),
                notificationModel,
                startMode,
                foregroundServiceType);
    }

    public void stopForegroundService(Integer notificationId) {
        ForegroundService.stop(notificationId);
    }

    private Boolean receiveNotificationAction(
            @NonNull Intent intent,
            @NonNull NotificationLifeCycle appLifeCycle
    ) throws AwesomeNotificationException {

        ActionReceived actionModel =
                NotificationBuilder
                        .getNewBuilder()
                        .receiveNotificationActionFromIntent(
                                wContext.get(),
                                intent,
                                appLifeCycle);

        if (actionModel == null)
            return false;

        return receiveNotificationAction(actionModel);
    }

    private Boolean receiveNotificationAction(@NonNull ActionReceived actionModel) throws AwesomeNotificationException {

        actionModel.validate(wContext.get());

        notifyAwesomeEvent(Definitions.CHANNEL_METHOD_DEFAULT_ACTION, actionModel);

        if (AwesomeNotifications.debug)
            Log.d(TAG, "Notification action received");

        return true;
    }

    public Calendar getNextValidDate(@NonNull NotificationScheduleModel scheduleModel, @Nullable Date fixedDate) throws AwesomeNotificationException {
        return scheduleModel.getNextValidDate(fixedDate);
    }

    public String getLocalTimeZone() {
        return DateUtils.getLocalTimeZone().getID();
    }

    public Object getUtcTimeZone() {
        return DateUtils.getUtcTimeZone().getID();
    }

    public int getGlobalBadgeCounter() {
        return BadgeManager.getInstance().getGlobalBadgeCounter(wContext.get());
    }

    public void setGlobalBadgeCounter(@NonNull Integer count) {
        // Android resets badges automatically when all notifications are cleared
        BadgeManager.getInstance().setGlobalBadgeCounter(wContext.get(), count);
    }

    public void resetGlobalBadgeCounter() {
        BadgeManager.getInstance().resetGlobalBadgeCounter(wContext.get());
    }

    public int incrementGlobalBadgeCounter() {
        return BadgeManager.getInstance().incrementGlobalBadgeCounter(wContext.get());
    }

    public int decrementGlobalBadgeCounter() {
        return BadgeManager.getInstance().decrementGlobalBadgeCounter(wContext.get());
    }

    public boolean dismissNotification(@NonNull Integer notificationId) throws AwesomeNotificationException {
        return CancellationManager.dismissNotification(wContext.get(), notificationId);
    }

    public boolean cancelSchedule(@NonNull Integer notificationId) throws AwesomeNotificationException {
        return CancellationManager.cancelSchedule(wContext.get(), notificationId);
    }

    public boolean cancelNotification(@NonNull Integer notificationId) throws AwesomeNotificationException {
        return CancellationManager.cancelNotification(wContext.get(), notificationId);
    }

    public boolean dismissNotificationsByChannelKey(@NonNull String channelKey) throws AwesomeNotificationException {
        return CancellationManager.dismissNotificationsByChannelKey(wContext.get(), channelKey);
    }

    public boolean cancelSchedulesByChannelKey(@NonNull String channelKey) throws AwesomeNotificationException {
        return CancellationManager.cancelSchedulesByChannelKey(wContext.get(), channelKey);
    }

    public boolean cancelNotificationsByChannelKey(@NonNull String channelKey) throws AwesomeNotificationException {
        return CancellationManager.cancelNotificationsByChannelKey(wContext.get(), channelKey);
    }

    public boolean dismissNotificationsByGroupKey(@NonNull String groupKey) throws AwesomeNotificationException {
        return CancellationManager.dismissNotificationsByGroupKey(wContext.get(), groupKey);
    }

    public boolean cancelSchedulesByGroupKey(@NonNull String groupKey) throws AwesomeNotificationException {
        return CancellationManager.cancelSchedulesByGroupKey(wContext.get(), groupKey);
    }

    public boolean cancelNotificationsByGroupKey(@NonNull String groupKey) throws AwesomeNotificationException {
        return CancellationManager.cancelNotificationsByGroupKey(wContext.get(), groupKey);
    }

    public void dismissAllNotifications() {
        CancellationManager.dismissAllNotifications(wContext.get());
    }

    public void cancelAllSchedules() {
        CancellationManager.cancelAllSchedules(wContext.get());
    }

    public void cancelAllNotifications() {
        CancellationManager.cancelAllNotifications(wContext.get());
    }

    public Object areNotificationsGloballyAllowed() {
        return PermissionManager
                    .getInstance()
                    .areNotificationsGloballyAllowed(wContext.get());
    }

    public void showNotificationPage(@Nullable String channelKey, @NonNull PermissionCompletionHandler permissionCompletionHandler) {
        if(StringUtils.isNullOrEmpty(channelKey))
            PermissionManager
                .getInstance()
                .showNotificationConfigPage(
                        wContext.get(),
                        permissionCompletionHandler);
        else
            PermissionManager
                .getInstance()
                .showChannelConfigPage(
                        wContext.get(),
                        channelKey,
                        permissionCompletionHandler);
    }

    public void showPreciseAlarmPage(@NonNull PermissionCompletionHandler permissionCompletionHandler) {
        PermissionManager
            .getInstance()
            .showPreciseAlarmPage(
                    wContext.get(),
                    permissionCompletionHandler);
    }

    public void showDnDGlobalOverridingPage(@NonNull PermissionCompletionHandler permissionCompletionHandler) {
        PermissionManager
            .getInstance()
            .showDnDGlobalOverridingPage(
                    wContext.get(),
                    permissionCompletionHandler);
    }

    public List<String> arePermissionsAllowed(@Nullable String channelKey, @NonNull List<String> permissions) throws AwesomeNotificationException {
        return PermissionManager
                    .getInstance()
                    .arePermissionsAllowed(
                            wContext.get(),
                            channelKey,
                            permissions);
    }

    public List<String> shouldShowRationale(@Nullable String channelKey, @NonNull List<String> permissions) throws AwesomeNotificationException {
        return PermissionManager
                    .getInstance()
                    .shouldShowRationale(
                            wContext.get(),
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
                        wContext.get(),
                        channelKey,
                        permissions,
                        permissionCompletionHandler);
    }
}
