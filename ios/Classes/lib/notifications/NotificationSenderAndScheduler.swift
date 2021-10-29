//
//  NotificationSender.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

@available(iOS 10.0, *)
class NotificationSenderAndScheduler {

    public static let TAG: String = "NotificationSender"

    private var createdSource:      NotificationSource?
    private var appLifeCycle:       NotificationLifeCycle?
    private var pushNotification:   PushNotification?
    private var content:            UNMutableNotificationContent?

    private var created:    Bool = false
    private var scheduled:  Date?
    
    private var completion: ((Bool, UNMutableNotificationContent?, Error?) -> ())?
    
    public func send(
        createdSource: NotificationSource,
        pushNotification: PushNotification?,
        content: UNMutableNotificationContent?,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ) throws {
        self.content = content
        try send(
            createdSource: createdSource,
            pushNotification: pushNotification,
            completion: completion
        )
    }
    
    public func send(
        createdSource: NotificationSource,
        pushNotification: PushNotification?,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ) throws {
        
        self.completion = completion

        if (pushNotification == nil){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Notification is not valid")
        }

        NotificationBuilder.isNotificationAllowed(completion: { (allowed) in
            
            do{
                if (allowed){
                    self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle

                    try pushNotification!.validate()
                    
                    if pushNotification!.schedule != nil &&
                        StringUtils.isNullOrEmpty(pushNotification!.schedule!.createdDate
                    ){
                        let timeZone:String = pushNotification!.schedule!.timeZone ?? DateUtils.localTimeZone.identifier
                        pushNotification!.schedule!.timeZone = timeZone
                        pushNotification!.schedule!.createdDate = DateUtils.getLocalTextDate(fromTimeZone: timeZone)
                    }

                    // Keep this way to future thread running
                    self.createdSource = createdSource
                    self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                    self.pushNotification = pushNotification

                    self.execute()
                }
                else {
                    throw AwesomeNotificationsException.notificationNotAuthorized
                }
            } catch {
                completion(false, nil, error)
            }
        })
    }

    private func execute(){
        //DispatchQueue.global(qos: .background).async {
            
            let notificationReceived:NotificationReceived? = self.doInBackground()

            //DispatchQueue.main.async {
                self.onPostExecute(receivedNotification: notificationReceived)
            //}
        //}
    }
    
    /// AsyncTask METHODS BEGIN *********************************

    private func doInBackground() -> NotificationReceived? {
        
        let now = DateUtils.getUTCTextDate()
        
        do {

            if (pushNotification != nil){

                var receivedNotification: NotificationReceived? = nil

                if(pushNotification!.content!.createdDate == nil){
                    pushNotification!.content!.createdSource = self.createdSource
                    pushNotification!.content!.createdDate = now
                    pushNotification!.content!.createdLifeCycle = self.appLifeCycle
                    created = true
                }

                if (
                    !StringUtils.isNullOrEmpty(pushNotification!.content!.title) ||
                    !StringUtils.isNullOrEmpty(pushNotification!.content!.body)
                ){
                    pushNotification = try showNotification(pushNotification!)

                    // Only save DisplayedMethods if pushNotification was created and displayed successfully
                    if(pushNotification != nil){
                        
                        let now = DateUtils.getUTCDateTime()
                        let displayedDate = pushNotification!.content!.displayedDate?.toDate(fromTimeZone: "UTC") ?? now
                        
                        if displayedDate.toString(toTimeZone: "UTC") == pushNotification!.content!.createdDate! {
                            pushNotification!.content!.displayedLifeCycle = pushNotification!.content!.createdLifeCycle
                        }
                        else if displayedDate <= now {
                            pushNotification!.content!.displayedLifeCycle = self.appLifeCycle
                        }
                        else {
                            scheduled = displayedDate
                            pushNotification!.content!.displayedLifeCycle = NotificationLifeCycle.AppKilled
                        }
                        
                        receivedNotification = NotificationReceived(pushNotification!.content)

                        receivedNotification!.displayedLifeCycle = receivedNotification!.displayedLifeCycle == nil ?
                            self.appLifeCycle : receivedNotification!.displayedLifeCycle
                    }

                } else {
                    receivedNotification = NotificationReceived(pushNotification!.content);
                }

                return receivedNotification;
            }

        } catch {
            completion?(false, nil, error)
        }

        pushNotification = nil
        return nil
    }

    private func onPostExecute(receivedNotification:NotificationReceived?) {

        // Only broadcast if pushNotification is valid
        if(receivedNotification != nil){

            if(created){
                SwiftAwesomeNotificationsPlugin.createEvent(notificationReceived: receivedNotification!)
                //CreatedManager.saveCreated(received: receivedNotification!)
            }
            
            if scheduled == nil {
                DisplayedManager.saveDisplayed(received: receivedNotification!)
            }
            else {
                DisplayedManager.saveScheduledToDisplay(received: receivedNotification!)
            }
            
            completion?(true, content, nil)
        }
        else {
            completion?(false, nil, nil)
        }
    }

    /// AsyncTask METHODS END *********************************

    public func showNotification(_ pushNotification:PushNotification) throws -> PushNotification? {
        
        return try NotificationBuilder.createNotification(pushNotification, content: content)
    }
    
    public static func dismissNotification(id:Int) -> Bool {
        NotificationBuilder.dismissNotification(id: id)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Notification id "+String(id)+" dismissed")
        }
        return true
    }
    
    public static func cancelSchedule(id:Int) -> Bool {
        NotificationBuilder.cancelScheduledNotification(id: id)
        ScheduleManager.cancelScheduled(id: id)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Schedule id "+String(id)+" cancelled")
        }
        return true
    }
    
    public static func cancelNotification(id:Int) -> Bool {
        NotificationBuilder.cancelNotification(id: id)
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Notification id "+String(id)+" cancelled")
        }
        return true
    }
    
    public static func dismissNotificationsByChannelKey(channelKey: String) -> Bool {
        NotificationBuilder.dismissNotificationsByChannelKey(channelKey: channelKey)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Notifications from channel "+channelKey+" dismissed")
        }
        return true
    }
    
    public static func cancelSchedulesByChannelKey(channelKey: String) -> Bool {
        NotificationBuilder.cancelSchedulesByChannelKey(channelKey: channelKey)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Scheduled notifications from channel "+channelKey+" canceled")
        }
        return true
    }
    
    public static func cancelNotificationsByChannelKey(channelKey: String) -> Bool {
        NotificationBuilder.cancelNotificationsByChannelKey(channelKey: channelKey)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Notifications and schedules from channel "+channelKey+" canceled")
        }
        return true
    }
    
    public static func dismissNotificationsByGroupKey(groupKey: String) -> Bool {
        NotificationBuilder.dismissNotificationsByGroupKey(groupKey: groupKey)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Notifications from group "+groupKey+" dismissed")
        }
        return true
    }
    
    public static func cancelSchedulesByGroupKey(groupKey: String) -> Bool {
        NotificationBuilder.cancelSchedulesByGroupKey(groupKey: groupKey)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Scheduled notifications from group "+groupKey+" canceled")
        }
        return true
    }
    
    public static func cancelNotificationsByGroupKey(groupKey: String) -> Bool {
        NotificationBuilder.cancelNotificationsByGroupKey(groupKey: groupKey)
                
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "Notifications and schedules from group "+groupKey+" canceled")
        }
        return true
    }
    
    public static func dismissAllNotifications() -> Bool {
        NotificationBuilder.dismissAllNotifications()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "All notifications was dismissed")
        }
        return true
    }
    
    public static func cancelAllSchedules() -> Bool {
        NotificationBuilder.cancellAllScheduledNotifications()
        ScheduleManager.cancelAllSchedules()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "All schedules was cancelled")
        }
        return true
    }

    public static func cancelAllNotifications() -> Bool {
        NotificationBuilder.cancellAllScheduledNotifications()
        NotificationBuilder.cancellAllNotifications()
        ScheduleManager.cancelAllSchedules()
        
        if(SwiftAwesomeNotificationsPlugin.debug){
            Log.d(NotificationSenderAndScheduler.TAG, "All notifications was cancelled")
        }
        return true
    }

}
