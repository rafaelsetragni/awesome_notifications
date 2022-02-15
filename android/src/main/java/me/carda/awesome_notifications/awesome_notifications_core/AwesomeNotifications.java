package me.carda.awesome_notifications.awesome_notifications_core;

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

import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers.AwesomeEventsReceiver;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers.ScheduledNotificationReceiver;
import me.carda.awesome_notifications.awesome_notifications_core.decoders.BitmapResourceDecoder;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.ForegroundStartMode;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.MediaSource;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ActionManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.DismissedManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.AbstractModel;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationSender;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeActionEventListener;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeLifeCycleEventListener;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeNotificationEventListener;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.listeners.AwesomeEventListener;
import me.carda.awesome_notifications.awesome_notifications_core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_core.completion_handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.awesome_notifications_core.managers.BadgeManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.CancellationManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ChannelGroupManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ChannelManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.CreatedManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.DefaultsManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.DisplayedManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.LifeCycleManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.PermissionManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ScheduleManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.DefaultsModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationChannelGroupModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationChannelModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationScheduleModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_core.services.ForegroundService;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BitmapUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BooleanUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.CalendarUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.JsonUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.ListUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class AwesomeNotifications
        implements AwesomeNotificationEventListener, AwesomeActionEventListener, AwesomeLifeCycleEventListener {

    private static final String TAG = "AwesomeNotifications";

    public static Boolean debug = false;

    private WeakReference<Context> wContext;
    private Activity applicationActivity;
    private StringUtils stringUtils;

    // ************************** CONSTRUCTOR ***********************************

    public AwesomeNotifications(
        @NonNull Context applicationContext,
        @NonNull AwesomeNotificationsExtension extensionClass
    ) throws AwesomeNotificationsException {

        wContext = new WeakReference<>(applicationContext);

        stringUtils = StringUtils.getInstance();

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

        loadAwesomeExtensions(
                applicationContext,
                stringUtils);
    }

    // ******************** LOAD EXTERNAL EXTENSIONS ***************************

    public static boolean isExtensionsLoaded = false;
    @SuppressWarnings("unchecked")
    public static void loadAwesomeExtensions(
        @NonNull Context context,
        StringUtils stringUtils
    ) throws AwesomeNotificationsException {

        if(isExtensionsLoaded) return;

        String extensionClassReference = DefaultsManager.getAwesomeExtensionClassName(context);
        if(!stringUtils.isNullOrEmpty(extensionClassReference))
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

        throw new AwesomeNotificationsException("Awesome plugin reference is invalid or not found");
    }

    public static void loadAwesomeExtensions(
            @NonNull Context context,
            @NonNull Class<? extends AwesomeNotificationsExtension> extensionClass
    ) throws AwesomeNotificationsException {

        if(isExtensionsLoaded) return;

        try {
            AwesomeNotificationsExtension awesomePlugin = extensionClass.newInstance();
            awesomePlugin.loadExternalExtensions(context);
            isExtensionsLoaded = true;

        } catch (IllegalAccessException | InstantiationException e) {
            e.printStackTrace();
            throw new AwesomeNotificationsException(
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
                if(activityHasStarted) {
                    AwesomeEventsReceiver
                            .getInstance()
                            .unsubscribeOnNotificationEvents(this)
                            .unsubscribeOnActionEvents(this);

                    NotificationScheduler
                            .refreshScheduledNotifications(wContext.get());
                }
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

    boolean waitingForRecover = true;
    public void setActionHandle(Long actionCallbackHandle) {
        DefaultsManager.setActionCallbackDispatcher(wContext.get(), actionCallbackHandle);
        DefaultsManager.commitChanges(wContext.get());

        if(waitingForRecover && actionCallbackHandle != 0L){
            waitingForRecover = false;

            recoverNotificationCreated(wContext.get());
            recoverNotificationDisplayed(wContext.get());
            recoverNotificationsDismissed(wContext.get());
            recoverNotificationActions(wContext.get());
        }
    }

    public Long getActionHandle() {
        DefaultsModel defaults = DefaultsManager.getDefaults(wContext.get());
        return defaults.silentDataCallback == null ?
                0L : Long.parseLong(defaults.silentDataCallback);
    }

    public List<NotificationModel> listAllPendingSchedules(){
        NotificationScheduler.refreshScheduledNotifications(wContext.get());
        return ScheduleManager.listSchedules(wContext.get());
    }

    // *****************************  INITIALIZATION FUNCTIONS  **********************************

    public void initialize(
            @Nullable String defaultIconPath,
            @Nullable List<Object> channelsData,
            @Nullable List<Object> channelGroupsData,
            Long dartCallback,
            boolean debug
    ) throws AwesomeNotificationsException {

        setDefaults(
                wContext.get(),
                defaultIconPath,
                dartCallback);

        if (ListUtils.isNullOrEmpty(channelGroupsData))
            setChannelGroups(wContext.get(), channelGroupsData);

        if (ListUtils.isNullOrEmpty(channelsData))
            throw new AwesomeNotificationsException("At least one channel is required");

        setChannels(wContext.get(), channelsData);

        captureNotificationActionOnLaunch(wContext.get());

        AwesomeNotifications.debug = debug;

        NotificationScheduler
                .refreshScheduledNotifications(wContext.get());

        if (AwesomeNotifications.debug)
            Log.d(TAG, "Awesome Notifications initialized");
    }

    private void setChannelGroups(
            @NonNull Context context,
            @NonNull List<Object> channelGroupsData)
                throws AwesomeNotificationsException {

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
                    throw new AwesomeNotificationsException(
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
                throws AwesomeNotificationsException {

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
                    throw new AwesomeNotificationsException("Invalid channel: " + JsonUtils.toJson(channelData));
                }
            }

        ChannelManager channelManager = ChannelManager.getInstance();
        for (NotificationChannelModel channelModel : channels)
            channelManager.saveChannel(context, channelModel, true, forceUpdate);

        channelManager.commitChanges(context);
    }

    private void setDefaults(@NonNull Context context, @Nullable String defaultIcon, Long dartCallbackHandle) {

        if (BitmapUtils.getInstance().getMediaSourceType(defaultIcon) != MediaSource.Resource)
            defaultIcon = null;

        DefaultsManager.setDefaultIcon(context, defaultIcon);
        DefaultsManager.setDartCallbackDispatcher(context, dartCallbackHandle);
        DefaultsManager.commitChanges(context);
    }

    // *****************************  RECOVER FUNCTIONS  **********************************

    private void recoverNotificationCreated(@NonNull Context context) {
        List<NotificationReceived> lostCreated = CreatedManager.listCreated(context);

        if (lostCreated != null)
            for (NotificationReceived created : lostCreated)
                try {

                    created.validate(context);

                    notifyAwesomeEvent(Definitions.EVENT_NOTIFICATION_CREATED, created);

                    CreatedManager.removeCreated(context, created.id);
                    CreatedManager.commitChanges(context);

                } catch (AwesomeNotificationsException e) {
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

                    notifyAwesomeEvent(Definitions.EVENT_NOTIFICATION_DISPLAYED, displayed);

                    DisplayedManager.removeDisplayed(context, displayed.id);
                    DisplayedManager.commitChanges(context);

                } catch (AwesomeNotificationsException e) {
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

                    notifyAwesomeEvent(Definitions.EVENT_DEFAULT_ACTION, received);

                    ActionManager.removeAction(context, received.id);
                    ActionManager.commitChanges(context);

                } catch (AwesomeNotificationsException e) {
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

                    notifyAwesomeEvent(Definitions.EVENT_NOTIFICATION_DISMISSED, received);

                    DismissedManager.removeDismissed(context, received.id);
                    DismissedManager.commitChanges(context);

                } catch (AwesomeNotificationsException e) {
                    if (AwesomeNotifications.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    // *****************************  ACTIONS AT LAUNCH  **********************************

    private void captureNotificationActionOnLaunch(@NonNull Context applicationContext) throws AwesomeNotificationsException {

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

    // *****************************  NOTIFICATION METHODS  **********************************

    public boolean createNotification(@NonNull NotificationModel notificationModel) throws AwesomeNotificationsException {

        if (!PermissionManager
                .getInstance()
                .areNotificationsGloballyAllowed(wContext.get()))
            throw new AwesomeNotificationsException("Notifications are disabled");

        if (notificationModel.schedule == null)
            NotificationSender
                    .send(
                        wContext.get(),
                        NotificationBuilder.getNewBuilder(),
                        NotificationSource.Local,
                        AwesomeNotifications.getApplicationLifeCycle(),
                        notificationModel,
                        null);
        else
            NotificationScheduler
                    .schedule(
                        wContext.get(),
                        NotificationSource.Schedule,
                        notificationModel);

        return true;
    }

    // *****************************  CHANNEL METHODS  **********************************

    public boolean setChannel(@NonNull NotificationChannelModel channelModel, boolean forceUpdate)
            throws AwesomeNotificationsException {

        ChannelManager
                .getInstance()
                .saveChannel(wContext.get(), channelModel, false, forceUpdate)
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

    public List<NotificationChannelModel> getAllChannels(@NonNull Context context){
        return ChannelManager
                    .getInstance()
                    .listChannels(context);
    }

    // **************************  FOREGROUND SERVICE METHODS  *******************************

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
    ) throws AwesomeNotificationsException {

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

    private Boolean receiveNotificationAction(@NonNull ActionReceived actionModel) throws AwesomeNotificationsException {

        actionModel.validate(wContext.get());

        notifyAwesomeEvent(Definitions.EVENT_DEFAULT_ACTION, actionModel);

        if (AwesomeNotifications.debug)
            Log.d(TAG, "Notification action received");

        return true;
    }

    public Calendar getNextValidDate(@NonNull NotificationScheduleModel scheduleModel, @Nullable Calendar fixedDate) throws AwesomeNotificationsException {
        return scheduleModel.getNextValidDate(fixedDate);
    }

    public String getLocalTimeZone() {
        return CalendarUtils.getInstance().getLocalTimeZone().getID();
    }

    public Object getUtcTimeZone() {
        return CalendarUtils.getInstance().getUtcTimeZone().getID();
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

    public boolean dismissNotification(
            @NonNull Integer notificationId
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .dismissNotification(wContext.get(), notificationId);
    }

    public boolean cancelSchedule(
            @NonNull Integer notificationId
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .cancelSchedule(wContext.get(), notificationId);
    }

    public boolean cancelNotification(
            @NonNull Integer notificationId
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .cancelNotification(wContext.get(), notificationId);
    }

    public boolean dismissNotificationsByChannelKey(
            @NonNull String channelKey
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .dismissNotificationsByChannelKey(wContext.get(), channelKey);
    }

    public boolean cancelSchedulesByChannelKey(
            @NonNull String channelKey
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .cancelSchedulesByChannelKey(wContext.get(), channelKey);
    }

    public boolean cancelNotificationsByChannelKey(
            @NonNull String channelKey
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .cancelNotificationsByChannelKey(wContext.get(), channelKey);
    }

    public boolean dismissNotificationsByGroupKey(
            @NonNull String groupKey
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .dismissNotificationsByGroupKey(wContext.get(), groupKey);
    }

    public boolean cancelSchedulesByGroupKey(
            @NonNull String groupKey
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .cancelSchedulesByGroupKey(wContext.get(), groupKey);
    }

    public boolean cancelNotificationsByGroupKey(
            @NonNull String groupKey
    ) throws AwesomeNotificationsException {
        return CancellationManager
                .getInstance()
                .cancelNotificationsByGroupKey(wContext.get(), groupKey);
    }

    public void dismissAllNotifications() {
        CancellationManager
                .getInstance()
                .dismissAllNotifications(wContext.get());
    }

    public void cancelAllSchedules() {

        CancellationManager
                .getInstance()
                .cancelAllSchedules(wContext.get());
    }

    public void cancelAllNotifications() {
        CancellationManager
                .getInstance()
                .cancelAllNotifications(wContext.get());
    }

    public Object areNotificationsGloballyAllowed() {
        return PermissionManager
                    .getInstance()
                    .areNotificationsGloballyAllowed(wContext.get());
    }

    public void showNotificationPage(
            @Nullable String channelKey,
            @NonNull PermissionCompletionHandler permissionCompletionHandler
    ){
        if(stringUtils.isNullOrEmpty(channelKey))
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

    public void showPreciseAlarmPage(
            @NonNull PermissionCompletionHandler permissionCompletionHandler
    ){
        PermissionManager
            .getInstance()
            .showPreciseAlarmPage(
                    wContext.get(),
                    permissionCompletionHandler);
    }

    public void showDnDGlobalOverridingPage(
            @NonNull PermissionCompletionHandler permissionCompletionHandler
    ){
        PermissionManager
            .getInstance()
            .showDnDGlobalOverridingPage(
                    wContext.get(),
                    permissionCompletionHandler);
    }

    public List<String> arePermissionsAllowed(
            @Nullable String channelKey,
            @NonNull List<String> permissions
    ) throws AwesomeNotificationsException {
        return PermissionManager
                    .getInstance()
                    .arePermissionsAllowed(
                            wContext.get(),
                            channelKey,
                            permissions);
    }

    public List<String> shouldShowRationale(
            @Nullable String channelKey,
            @NonNull List<String> permissions
    ) throws AwesomeNotificationsException {
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
            throws AwesomeNotificationsException {

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
