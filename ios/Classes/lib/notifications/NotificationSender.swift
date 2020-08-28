
class NotificationSender {

    public static let TAG: String = "NotificationSender"

    private var createdSource:      NotificationSource?
    private var appLifeCycle:       NotificationLifeCycle?
    private var pushNotification:   PushNotification?

    private var created:    Bool = false
    private var displayed:  Bool = false

    private let notificationBuilder:NotificationBuilder = NotificationBuilder()

    public func send(
        createdSource: NotificationSource,
        pushNotification: PushNotification?
    ) throws {

        if (pushNotification == nil){
            throw PushNotificationError.notificationIsRequired
        }

        if(SwiftAwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            self.appLifeCycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
        }
        else {
            self.appLifeCycle = NotificationLifeCycle.AppKilled
        }

        pushNotification.validate()

        // Keep this way to future thread running
        self.createdSource = createdSource
        self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
        self.pushNotification = pushNotification

        self.execute()
    }

    private func execute(){
        /*
        let qualityServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(Int(qualityServiceClass.rawValue), 0)

        dispatch_async(backgroundQueue, {
           print("This is run on the background queue")
           // With the help of NSTimer it will hit method after every 5 minutes (300 seconds).
           _ = NSTimer.scheduledTimerWithTimeInterval(300.0, target: self, selector: #selector(AppDelegate.callAppSettingWebservice), userInfo: nil, repeats: true)

        })
        */
    }
    
    /// AsyncTask METHODS BEGIN *********************************

    private func doInBackground() -> NotificationReceived {

        do {

            if (pushNotification != nil){

                let receivedNotification: NotificationReceived = nil

                if(pushNotification.content.createdSource == nil){
                    pushNotification.content.createdSource = self.createdSource
                    created = true
                }

                if(pushNotification.content.createdLifeCycle == nil)
                    pushNotification.content.createdLifeCycle = self.appLifeCycle

                if (
                    !StringUtils.isnilOrEmpty(pushNotification.content.title) ||
                    !StringUtils.isnilOrEmpty(pushNotification.content.body)
                ){

                    if(pushNotification.content.displayedLifeCycle == nil)
                        pushNotification.content.displayedLifeCycle = appLifeCycle

                    pushNotification.content.displayedDate = DateUtils.getUTCDate()

                    pushNotification = showNotification(context, pushNotification)

                    // Only save DisplayedMethods if pushNotification was created and displayed successfully
                    if(pushNotification != nil){
                        displayed = true

                        receivedNotification = new NotificationReceived(pushNotification.content)

                        receivedNotification.displayedLifeCycle = receivedNotification.displayedLifeCycle == nil ?
                            appLifeCycle : receivedNotification.displayedLifeCycle
                    }

                } else {
                    receivedNotification = NotificationReceived(pushNotification.content);
                }

                return receivedNotification;
            }

        } catch {
        }

        pushNotification = nil;
        return nil;
    }

    protected void onPostExecute(NotificationReceived receivedNotification) {
        Log.d(TAG, "Notification created");

        // Only broadcast if pushNotification is valid
        if(pushNotification != nil){

            if(created){
                CreatedManager.saveCreated(context, receivedNotification);
                BroadcastSender.SendBroadcastNotificationCreated(
                    context,
                    receivedNotification
                );
            }

            if(displayed){
                DisplayedManager.saveDisplayed(context, receivedNotification);
                BroadcastSender.SendBroadcastNotificationDisplayed(
                    context,
                    receivedNotification
                );
            }
        }
    }

    /// AsyncTask METHODS END *********************************

    public PushNotification showNotification(PushNotification pushNotification) {

        do {

            Notification notification = notificationBuilder.createNotification(pushNotification);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                notificationManager.notify(pushNotification.content.id, notification);
            }
            else {
                NotificationManagerCompat notificationManagerCompat = getNotificationManager(context);
                notificationManagerCompat.notify(pushNotification.content.id.toString(), pushNotification.content.id, notification);
            }

            return pushNotification;

        } catch {
            
        }
        return nil;
    }

    private static NotificationManagerCompat getNotificationManager(Context context) {
        return NotificationManagerCompat.from(context);
    }

    public static void cancelNotification(Context context, Integer id) {
        if(context != nil){
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationManagerCompat notificationManager = getNotificationManager(context);
                notificationManager.cancel(id.toString(), id);
                notificationManager.cancel(id);
            }

            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancel(id.toString(), id);
            notificationManager.cancel(id);


            CreatedManager.cancelCreated(context, id);
            DisplayedManager.cancelDisplayed(context, id);
        }
    }

    public static boolean cancelAllNotifications(Context context) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManagerCompat notificationManager = getNotificationManager(context);
            notificationManager.cancelAll();
        }
        else {
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancelAll();
        }

        CreatedManager.cancelAllCreated(context);
        DisplayedManager.cancelAllDisplayed(context);

        return true;
    }

}
