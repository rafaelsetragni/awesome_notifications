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
            throw PushNotificationError.invalidRequiredFields(msg: "PushNotification not valid")
        }

        NotificationBuilder.isNotificationAllowed(completion: { (allowed) in
            
            do{
                if (allowed){
                    self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle

                    try pushNotification!.validate()

                    // Keep this way to future thread running
                    self.createdSource = createdSource
                    self.appLifeCycle = SwiftAwesomeNotificationsPlugin.appLifeCycle
                    self.pushNotification = pushNotification

                    self.execute()
                }
                else {
                    throw PushNotificationError.notificationNotAuthorized
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
        
        let now = DateUtils.getUTCDate()
        
        do {

            //if (pushNotification != nil){

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
                    pushNotification = showNotification(pushNotification!, now: now)

                    // Only save DisplayedMethods if pushNotification was created and displayed successfully
                    if(pushNotification != nil){
                        
                        let displayedDate = pushNotification!.content!.displayedDate!.toDate()!
                        
                        if displayedDate.toString() == pushNotification!.content!.createdDate! {
                            pushNotification!.content!.displayedLifeCycle = pushNotification!.content!.createdLifeCycle
                        }
                        else if displayedDate <= Date() {
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
/*
        } catch {
            completion?(false, nil, error)
        }

        pushNotification = nil
        return nil*/
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
            
            completion!(true, content, nil)
        }
        else {
            completion?(false, nil, nil)
        }
    }

    /// AsyncTask METHODS END *********************************

    public func showNotification(_ pushNotification:PushNotification, now:String) -> PushNotification? {

        do {
            
            return try NotificationBuilder.createNotification(pushNotification, content: content, now: now)

        } catch {
            
        }
        
        return nil
    }

    public static func cancelNotification(id:Int) -> Bool {
        NotificationBuilder.cancelNotification(id: id)
        debugPrint("Notification cancelled")
        return true
    }
    
    public static func cancelSchedule(id:Int) -> Bool {
        NotificationBuilder.cancelScheduledNotification(id: id)
        ScheduleManager.cancelScheduled(id: id)
        debugPrint("Schedule cancelled")
        return true
    }
    
    public static func cancelAllSchedules() -> Bool {
        NotificationBuilder.cancellAllScheduledNotifications()
        ScheduleManager.cancelAllSchedules()
        debugPrint("All notifications scheduled was cancelled")
        return true
    }

    public static func cancelAllNotifications() -> Bool {
        NotificationBuilder.cancellAllScheduledNotifications()
        NotificationBuilder.cancellAllNotifications()
        ScheduleManager.cancelAllSchedules()
        debugPrint("All notifications was cancelled")
        return true
    }

}
