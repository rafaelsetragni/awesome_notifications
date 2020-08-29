
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
            throw PushNotificationError.invalidRequiredFields(msg: "PushNotification not valid")
        }

        if(SwiftAwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            self.appLifeCycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
        }
        else {
            self.appLifeCycle = NotificationLifeCycle.AppKilled
        }

        try pushNotification!.validate()

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

    private func doInBackground() -> NotificationReceived? {
        
        do {

            if (pushNotification != nil){

                var receivedNotification: NotificationReceived? = nil

                if(pushNotification!.content!.createdSource == nil){
                    pushNotification!.content!.createdSource = self.createdSource
                    created = true
                }

                if(pushNotification!.content!.createdLifeCycle == nil){
                    pushNotification!.content!.createdLifeCycle = self.appLifeCycle
                }

                if (
                    !StringUtils.isNullOrEmpty(pushNotification!.content!.title) ||
                    !StringUtils.isNullOrEmpty(pushNotification!.content!.body)
                ){

                    if(pushNotification!.content!.displayedLifeCycle == nil){
                        pushNotification!.content!.displayedLifeCycle = appLifeCycle
                    }

                    pushNotification!.content!.displayedDate = DateUtils.getUTCDate()

                    pushNotification = showNotification(pushNotification!)

                    // Only save DisplayedMethods if pushNotification was created and displayed successfully
                    if(pushNotification != nil){
                        displayed = true

                        receivedNotification = NotificationReceived(pushNotification!.content)

                        receivedNotification!.displayedLifeCycle = receivedNotification!.displayedLifeCycle == nil ?
                            appLifeCycle : receivedNotification!.displayedLifeCycle
                    }

                } else {
                    receivedNotification = NotificationReceived(pushNotification!.content);
                }

                return receivedNotification;
            }

        } catch {
        }

        pushNotification = nil
        return nil
    }

    private func onPostExecute(receivedNotification:NotificationReceived?) {

        // Only broadcast if pushNotification is valid
        if(pushNotification != nil){

            if(created){
                // TODO MISSING IMPLEMENTATION
            }

            if(displayed){
                // TODO MISSING IMPLEMENTATION
            }
        }
    }

    /// AsyncTask METHODS END *********************************

    public func showNotification(_ pushNotification:PushNotification) -> PushNotification? {

        do {


            return pushNotification

        } catch {
            return nil
        }
        return nil
    }

    public static func cancelNotification(id:Int) {
        // TODO MISSING IMPLEMENTATION
    }

    public static func cancelAllNotifications() -> Bool {
        // TODO MISSING IMPLEMENTATION
        return true;
    }

}
