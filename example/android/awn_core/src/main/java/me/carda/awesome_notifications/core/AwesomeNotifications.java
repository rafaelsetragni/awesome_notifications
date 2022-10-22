package me.carda.awesome_notifications.core;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.media.session.MediaSession;
import android.support.v4.media.session.MediaSessionCompat;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.broadcasters.receivers.AwesomeEventsReceiver;
import me.carda.awesome_notifications.core.broadcasters.receivers.DismissedNotificationReceiver;
import me.carda.awesome_notifications.core.broadcasters.receivers.NotificationActionReceiver;
import me.carda.awesome_notifications.core.broadcasters.receivers.ScheduledNotificationReceiver;
import me.carda.awesome_notifications.core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.completion_handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.core.decoders.BitmapResourceDecoder;
import me.carda.awesome_notifications.core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.core.enumerators.ForegroundStartMode;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.listeners.AwesomeActionEventListener;
import me.carda.awesome_notifications.core.listeners.AwesomeEventListener;
import me.carda.awesome_notifications.core.listeners.AwesomeLifeCycleEventListener;
import me.carda.awesome_notifications.core.listeners.AwesomeNotificationEventListener;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.ActionManager;
import me.carda.awesome_notifications.core.managers.BadgeManager;
import me.carda.awesome_notifications.core.managers.CancellationManager;
import me.carda.awesome_notifications.core.managers.ChannelGroupManager;
import me.carda.awesome_notifications.core.managers.ChannelManager;
import me.carda.awesome_notifications.core.managers.CreatedManager;
import me.carda.awesome_notifications.core.managers.DefaultsManager;
import me.carda.awesome_notifications.core.managers.DismissedManager;
import me.carda.awesome_notifications.core.managers.DisplayedManager;
import me.carda.awesome_notifications.core.managers.LifeCycleManager;
import me.carda.awesome_notifications.core.managers.PermissionManager;
import me.carda.awesome_notifications.core.managers.ScheduleManager;
import me.carda.awesome_notifications.core.models.AbstractModel;
import me.carda.awesome_notifications.core.models.DefaultsModel;
import me.carda.awesome_notifications.core.models.NotificationChannelGroupModel;
import me.carda.awesome_notifications.core.models.NotificationChannelModel;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.models.NotificationScheduleModel;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.services.ForegroundService;
import me.carda.awesome_notifications.core.threads.NotificationScheduler;
import me.carda.awesome_notifications.core.threads.NotificationSender;
import me.carda.awesome_notifications.core.utils.CalendarUtils;
import me.carda.awesome_notifications.core.utils.JsonUtils;
import me.carda.awesome_notifications.core.utils.ListUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class AwesomeNotifications
    implements
        AwesomeNotificationEventListener,
        AwesomeActionEventListener,
        AwesomeLifeCycleEventListener
{
    private static final String TAG = "AwesomeNotifications";

    public static Boolean debug = false;

    private final WeakReference<Context> wContext;
    private final StringUtils stringUtils;

    public static Class actionReceiverClass = NotificationActionReceiver.class;
    public static Class dismissReceiverClass = DismissedNotificationReceiver.class;
    public static Class scheduleReceiverClass = ScheduledNotificationReceiver.class;
    public static Class backgroundServiceClass;

    private static String packageName;
    public static String getPackageName(@NonNull Context context){
        if(packageName == null)
            packageName = context.getPackageName();
        return packageName;
    }

    // ************************** CONSTRUCTOR ***********************************

    public AwesomeNotifications(@NonNull Context applicationContext)
            throws AwesomeNotificationsException {

        AwesomeNotifications.getPackageName(applicationContext);
        debug = isApplicationInDebug(applicationContext);
        wContext = new WeakReference<>(applicationContext);
        stringUtils = StringUtils.getInstance();

        LifeCycleManager
                .getInstance()
                .subscribe(this)
                .startListeners();

        initialize(applicationContext);

        NotificationBuilder
            .getNewBuilder()
            .updateMainTargetClassName(applicationContext)
            .setMediaSession(
                    new MediaSessionCompat(
                            applicationContext,
                            "PUSH_MEDIA"));
    }

    private boolean isTheMainInstance = false;
    public void attachAsMainInstance(AwesomeEventListener awesomeEventlistener){
        if (isTheMainInstance)
            return;

        isTheMainInstance = true;

        subscribeOnAwesomeNotificationEvents(awesomeEventlistener);

        AwesomeEventsReceiver
                .getInstance()
                .subscribeOnActionEvents(this)
                .subscribeOnNotificationEvents(this);

        Logger.d(TAG, "Awesome notifications ("+this.hashCode()+") attached to activity");
    }

    public void detachAsMainInstance(AwesomeEventListener awesomeEventlistener){
        if (!isTheMainInstance)
            return;

        isTheMainInstance = false;

        unsubscribeOnAwesomeNotificationEvents(awesomeEventlistener);

        AwesomeEventsReceiver
                .getInstance()
                .unsubscribeOnNotificationEvents(this)
                .unsubscribeOnActionEvents(this);


        Logger.d(TAG, "Awesome notifications ("+this.hashCode()+") detached from activity");
    }

    public void dispose(){
        LifeCycleManager
                .getInstance()
                .unsubscribe(this);
    }

    // ******************** INITIALIZATION METHOD ***************************

    public static AwesomeNotificationsExtension awesomeExtensions;
    public static boolean areExtensionsLoaded = false;

    public static void initialize(
        @NonNull Context context
    ) throws AwesomeNotificationsException {
        if(areExtensionsLoaded) return;

        if (AbstractModel.defaultValues.isEmpty())
            AbstractModel
                    .defaultValues
                    .putAll(Definitions.initialValues);

        if(awesomeExtensions == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_CLASS_NOT_FOUND,
                            "Awesome's plugin extension reference was not found.",
                            ExceptionCode.DETAILED_INITIALIZATION_FAILED+".awesomeNotifications.extensions");

        awesomeExtensions.loadExternalExtensions(context);
        areExtensionsLoaded = true;
    }

    // ********************************************************

    /// **************  EVENT INTERFACES  *********************

    @Override
    public void onNewActionReceived(String eventName, ActionReceived actionReceived) {
        notifyActionEvent(eventName, actionReceived);
    }

    @Override
    public boolean onNewActionReceivedWithInterruption(String eventName, ActionReceived actionReceived) {
        return false;
    }

    @Override
    public void onNewNotificationReceived(String eventName, NotificationReceived notificationReceived) {
        notifyNotificationEvent(eventName, notificationReceived);
    }

    @Override
    public void onNewLifeCycleEvent(NotificationLifeCycle lifeCycle) {

        if(!isTheMainInstance)
            return;

        switch (lifeCycle){

            case Foreground:
                PermissionManager
                        .getInstance()
                        .handlePermissionResult(
                                PermissionManager.REQUEST_CODE,
                                null,
                                null);
                break;

            case Background:
                break;

            case AppKilled:

//                NotificationScheduler
//                        .refreshScheduledNotifications(
//                                wContext.get());
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
        new BitmapResourceDecoder(
                wContext.get(),
                bitmapReference,
                completionHandler
            ).execute();
    }

    public void setActionHandle(Long actionCallbackHandle) throws AwesomeNotificationsException {
        DefaultsManager.setActionCallbackDispatcher(wContext.get(), actionCallbackHandle);
        DefaultsManager.commitChanges(wContext.get());

        if(actionCallbackHandle != 0L)
        {
            recoverNotificationCreated(wContext.get());
            recoverNotificationDisplayed(wContext.get());
            recoverNotificationsDismissed(wContext.get());
            recoverNotificationActions(wContext.get());
        }
    }

    public Long getActionHandle() throws AwesomeNotificationsException {
        DefaultsModel defaults = DefaultsManager.getDefaults(wContext.get());
        return defaults.silentDataCallback == null ?
                0L : Long.parseLong(defaults.silentDataCallback);
    }

    public List<NotificationModel> listAllPendingSchedules() throws AwesomeNotificationsException {
        NotificationScheduler.refreshScheduledNotifications(wContext.get());
        return ScheduleManager.listSchedules(wContext.get());
    }

    public boolean isApplicationInDebug(@NonNull Context context){
        return 0 != (
            context.getApplicationInfo().flags &
            ApplicationInfo.FLAG_DEBUGGABLE);
    }

    // *****************************  INITIALIZATION FUNCTIONS  **********************************

    public void initialize(
        @Nullable String defaultIconPath,
        @Nullable List<Object> channelsData,
        @Nullable List<Object> channelGroupsData,
        @NonNull Long dartCallback,
        boolean debug
    ) throws AwesomeNotificationsException {

        Context currentContext = wContext.get();

        DefaultsManager
                .saveDefault(
                        currentContext,
                        defaultIconPath,
                        dartCallback);

        DefaultsManager
                .commitChanges(currentContext);

        if (!ListUtils.isNullOrEmpty(channelGroupsData))
            setChannelGroups(wContext.get(), channelGroupsData);

        if (ListUtils.isNullOrEmpty(channelsData))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INITIALIZATION_EXCEPTION,
                            "At least one channel is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".channelList");

        setChannels(currentContext, channelsData);

        AwesomeNotifications.debug = debug && isApplicationInDebug(currentContext);

        NotificationScheduler
                .refreshScheduledNotifications(currentContext);

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "Awesome Notifications initialized");
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
                    throw ExceptionFactory
                            .getInstance()
                            .createNewAwesomeException(
                                    TAG,
                                    ExceptionCode.CODE_INITIALIZATION_EXCEPTION,
                                    "Invalid channel group: " + JsonUtils.toJson(channelData),
                                    ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelGroup.data");
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

        for (Object channelDataObject : channelsData) {
            if (channelDataObject instanceof Map<?, ?>) {
                @SuppressWarnings("unchecked")
                Map<String, Object> channelData = (Map<String, Object>) channelDataObject;
                NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);

                Object forceUpdateObject = channelData.get(Definitions.CHANNEL_FORCE_UPDATE);
                forceUpdate = forceUpdateObject != null && Boolean.parseBoolean(forceUpdateObject.toString());

                if (channelModel != null) {
                    channels.add(channelModel);
                } else {
                    throw ExceptionFactory
                            .getInstance()
                            .createNewAwesomeException(
                                    TAG,
                                    ExceptionCode.CODE_INVALID_ARGUMENTS,
                                    "Invalid channel: " + JsonUtils.toJson(channelData),
                                    ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".channel.data");
                }
            }
            if (channelDataObject instanceof NotificationChannelModel) {
                @SuppressWarnings("unchecked")
                NotificationChannelModel channelModel = (NotificationChannelModel) channelDataObject;
                channels.add(channelModel);
            }
        }

        ChannelManager channelManager = ChannelManager.getInstance();
        for (NotificationChannelModel channelModel : channels)
            channelManager.saveChannel(context, channelModel, true, forceUpdate);

        channelManager.commitChanges(context);
    }

    // *****************************  RECOVER FUNCTIONS  **********************************

    private void recoverNotificationCreated(@NonNull Context context) throws AwesomeNotificationsException {
        List<NotificationReceived> lostCreated = CreatedManager.listCreated(context);

        if (lostCreated != null)
            for (NotificationReceived created : lostCreated)
                try {

                    created.validate(context);

                    CreatedManager.removeCreated(context, created.id);
                    CreatedManager.commitChanges(context);

                    BroadcastSender.sendBroadcastNotificationCreated(context, created);

                } catch (AwesomeNotificationsException e) {
                    if (AwesomeNotifications.debug)
                        Logger.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void recoverNotificationDisplayed(@NonNull Context context) throws AwesomeNotificationsException {
        List<NotificationReceived> lostDisplayed = DisplayedManager.listDisplayed(context);

        if (lostDisplayed != null)
            for (NotificationReceived displayed : lostDisplayed)
                try {
                    displayed.validate(context);

                    DisplayedManager.removeDisplayed(context, displayed.id);
                    DisplayedManager.commitChanges(context);

                    BroadcastSender.sendBroadcastNotificationDisplayed(context, displayed);

                } catch (AwesomeNotificationsException e) {
                    if (AwesomeNotifications.debug)
                        Logger.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void recoverNotificationActions(@NonNull Context context) throws AwesomeNotificationsException {
        List<ActionReceived> lostActions = ActionManager.listActions(context);

        if (lostActions != null)
            for (ActionReceived received : lostActions)
                try {
                    received.validate(context);

                    ActionManager.removeAction(context, received.id);
                    ActionManager.commitChanges(context);

                    BroadcastSender.sendBroadcastDefaultAction(context, received, false);

                } catch (AwesomeNotificationsException e) {
                    if (AwesomeNotifications.debug)
                        Logger.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    private void recoverNotificationsDismissed(@NonNull Context context) throws AwesomeNotificationsException {
        List<ActionReceived> lostDismissed = DismissedManager.listDismisses(context);

        if (lostDismissed != null)
            for (ActionReceived received : lostDismissed)
                try {
                    received.validate(context);

                    DismissedManager.removeDismissed(context, received.id);
                    DismissedManager.commitChanges(context);

                    BroadcastSender.sendBroadcastNotificationDismissed(context, received);

                } catch (AwesomeNotificationsException e) {
                    if (AwesomeNotifications.debug)
                        Logger.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
    }

    // *****************************  NOTIFICATION METHODS  **********************************

    public void createNotification(@NonNull NotificationModel notificationModel, NotificationThreadCompletionHandler threadCompletionHandler) throws AwesomeNotificationsException {

        if (!PermissionManager
                .getInstance()
                .areNotificationsGloballyAllowed(wContext.get()))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                            "Notifications are disabled",
                            ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".global");

        if (notificationModel.schedule == null)
            NotificationSender
                    .send(
                        wContext.get(),
                        NotificationBuilder.getNewBuilder(),
                        NotificationSource.Local,
                        AwesomeNotifications.getApplicationLifeCycle(),
                        notificationModel,
                        null,
                        threadCompletionHandler);
        else
            NotificationScheduler
                    .schedule(
                        wContext.get(),
                        NotificationSource.Schedule,
                        notificationModel,
                        threadCompletionHandler);
    }

    public void clearStoredActions() throws AwesomeNotificationsException {
        ActionManager.clearAllActions(wContext.get());
    }

    public boolean captureNotificationActionFromActivity(Activity startActivity) throws Exception {
        if (startActivity == null)
            return false;
        return captureNotificationActionFromIntent(startActivity.getIntent(), true);
    }

    public boolean captureNotificationActionFromIntent(Intent intent) throws Exception {
        return captureNotificationActionFromIntent(intent, false);
    }

    public boolean captureNotificationActionFromIntent(Intent intent, boolean onInitialization) throws Exception {
        if (intent == null)
            return false;

        String actionName = intent.getAction();
        if (actionName == null)
            return false;

        Boolean isStandardAction = Definitions.SELECT_NOTIFICATION.equals(actionName);
        Boolean isButtonAction = actionName.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        boolean isNotificationAction = isStandardAction || isButtonAction;
        if (isNotificationAction)
            NotificationActionReceiver.receiveActionIntent(wContext.get(), intent, onInitialization);

        return isNotificationAction;
    }

    public ActionReceived getInitialNotificationAction(
            @NonNull boolean removeActionEvent
    ) throws AwesomeNotificationsException {
        ActionReceived initialActionReceived = ActionManager.getInitialActionReceived();
        if (!removeActionEvent) return initialActionReceived;
        if(initialActionReceived == null) return null;

        Context context = wContext.get();
        ActionManager.removeAction(context, initialActionReceived.id);
        ActionManager.commitChanges(context);

        return initialActionReceived;
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

    public boolean removeChannel(@NonNull String channelKey) throws AwesomeNotificationsException {
        boolean removed = ChannelManager
                .getInstance()
                .removeChannel(wContext.get(), channelKey);

        ChannelManager
                .getInstance()
                .commitChanges(wContext.get());

        return removed;
    }

    public List<NotificationChannelModel> getAllChannels(@NonNull Context context) throws AwesomeNotificationsException {
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

    public void dismissAllNotifications() throws AwesomeNotificationsException {
        CancellationManager
                .getInstance()
                .dismissAllNotifications(wContext.get());
    }

    public void cancelAllSchedules() throws AwesomeNotificationsException {

        CancellationManager
                .getInstance()
                .cancelAllSchedules(wContext.get());
    }

    public void cancelAllNotifications() throws AwesomeNotificationsException {
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
            @NonNull Activity activity,
            @Nullable String channelKey,
            @NonNull List<String> permissions,
            @NonNull PermissionCompletionHandler permissionCompletionHandler)
            throws AwesomeNotificationsException
    {
        PermissionManager
                .getInstance()
                .requestUserPermissions(
                        activity,
                        wContext.get(),
                        channelKey,
                        permissions,
                        permissionCompletionHandler);
    }
}
