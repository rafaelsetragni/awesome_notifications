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
    private var notificationModel:   NotificationModel?
    private var content:            UNMutableNotificationContent?

    private var created:    Bool = false
    private var scheduled:  Date?
    
    private var completion: ((Bool, UNMutableNotificationContent?, Error?) -> ())?
    
    public func send(
        createdSource: NotificationSource,
        notificationModel: NotificationModel?,
        content: UNMutableNotificationContent?,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ) throws {
        self.content = content
        try send(
            createdSource: createdSource,
            notificationModel: notificationModel,
            completion: completion
        )
    }
    
    public func send(
        createdSource: NotificationSource,
        notificationModel: NotificationModel?,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ) throws {
        
        self.completion = completion

        if (notificationModel == nil){
            throw AwesomeNotificationsException.invalidRequiredFields(msg: "Notification is not valid")
        }

        NotificationBuilder.isNotificationAllowed(completion: { (allowed) in
            
            do{
                if (allowed){
                    self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle

                    try notificationModel!.validate()
                    
                    if notificationModel!.schedule != nil &&
                        StringUtils.isNullOrEmpty(notificationModel!.schedule!.createdDate
                    ){
                        let timeZone:String = notificationModel!.schedule!.timeZone ?? DateUtils.localTimeZone.identifier
                        notificationModel!.schedule!.timeZone = timeZone
                        notificationModel!.schedule!.createdDate = DateUtils.getLocalTextDate(fromTimeZone: timeZone)
                    }

                    // Keep this way to future thread running
                    self.createdSource = createdSource
                    self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                    self.notificationModel = notificationModel

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

            if (notificationModel != nil){
                
                if ((notificationModel!.content!.id ?? -1) < 0){
                    notificationModel!.content!.id = IntUtils.generateNextRandomId();
                }

                var receivedNotification: NotificationReceived? = nil

                if(notificationModel!.content!.createdDate == nil){
                    notificationModel!.content!.createdSource = self.createdSource
                    notificationModel!.content!.createdDate = now
                    notificationModel!.content!.createdLifeCycle = self.appLifeCycle
                    created = true
                }

                if (
                    !StringUtils.isNullOrEmpty(notificationModel!.content!.title) ||
                    !StringUtils.isNullOrEmpty(notificationModel!.content!.body)
                ){
                    notificationModel = try showNotification(notificationModel!)

                    // Only save DisplayedMethods if notificationModel was created and displayed successfully
                    if(notificationModel != nil){
                        
                        let now = DateUtils.getUTCDateTime()
                        let displayedDate = notificationModel!.content!.displayedDate?.toDate(fromTimeZone: "UTC") ?? now
                        
                        if displayedDate.toString(toTimeZone: "UTC") == notificationModel!.content!.createdDate! {
                            notificationModel!.content!.displayedLifeCycle = notificationModel!.content!.createdLifeCycle
                        }
                        else if displayedDate <= now {
                            notificationModel!.content!.displayedLifeCycle = self.appLifeCycle
                        }
                        else {
                            scheduled = displayedDate
                            notificationModel!.content!.displayedLifeCycle = NotificationLifeCycle.AppKilled
                        }
                        
                        receivedNotification = NotificationReceived(notificationModel!.content)

                        receivedNotification!.displayedLifeCycle = receivedNotification!.displayedLifeCycle == nil ?
                            self.appLifeCycle : receivedNotification!.displayedLifeCycle
                    }

                } else {
                    receivedNotification = NotificationReceived(notificationModel!.content);
                }

                return receivedNotification;
            }

        } catch {
            completion?(false, nil, error)
        }

        notificationModel = nil
        return nil
    }

    private func onPostExecute(receivedNotification:NotificationReceived?) {

        // Only broadcast if notificationModel is valid
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

    public func showNotification(_ notificationModel:NotificationModel) throws -> NotificationModel? {
        
        return try NotificationBuilder.createNotification(notificationModel, content: content)
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
