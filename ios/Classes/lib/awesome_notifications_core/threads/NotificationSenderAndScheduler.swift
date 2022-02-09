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

    private var createdSource:      NotificationSource
    private var appLifeCycle:       NotificationLifeCycle
    private var notificationModel:  NotificationModel?
    private var content:            UNMutableNotificationContent?
    
    private var refreshNotification:Bool = false
    private var created:    Bool = false
    private var scheduled:  Date?
    
    private var completion: ((Bool, UNMutableNotificationContent?, Error?) -> ())
    
    public static func send(
        createdSource: NotificationSource,
        notificationModel: NotificationModel,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> (),
        appLifeCycle: NotificationLifeCycle
    ) throws {
        
        try NotificationSenderAndScheduler(
                createdSource: createdSource,
                notificationModel: notificationModel,
                content: nil,
                isRefreshNotification: false,
                appLifeCycle: appLifeCycle,
                completion: completion
            ).send()
    }
    
    public static func send(
        createdSource: NotificationSource,
        notificationModel: NotificationModel,
        content: UNMutableNotificationContent?,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> (),
        appLifeCycle: NotificationLifeCycle
    ) throws {
        try NotificationSenderAndScheduler(
                createdSource: createdSource,
                notificationModel: notificationModel,
                content: content,
                isRefreshNotification: false,
                appLifeCycle: appLifeCycle,
                completion: completion
            ).send()
    }
    
    // Its only possible to mimic the persistent notification on iOS > 15
    @available(iOS 15.0, *)
    public static func mimicPersistentNotification(
        notificationModel: NotificationModel
    ) throws {
        notificationModel.importance = .Low
        
        try NotificationSenderAndScheduler(
                createdSource: notificationModel.content!.createdSource!,
                notificationModel: notificationModel,
                content: nil,
                isRefreshNotification: true,
                appLifeCycle: notificationModel.content!.createdLifeCycle!,
                completion: { _, __, ___ in
                }
            ).send()
    }
    
    private init(
        createdSource: NotificationSource,
        notificationModel: NotificationModel,
        content: UNMutableNotificationContent?,
        isRefreshNotification: Bool,
        appLifeCycle: NotificationLifeCycle,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ){
        self.refreshNotification = isRefreshNotification
        self.content = content
        self.createdSource = createdSource
        self.notificationModel = notificationModel
        self.appLifeCycle = appLifeCycle
        self.completion = completion
    }
    
    private func send() throws {
        
        created = notificationModel!
                            .content!
                            .registerCreateEvent(
                                inLifeCycle: appLifeCycle,
                                fromSource: createdSource)

        PermissionManager
            .shared
            .areNotificationsGloballyAllowed(whenGotResults: { (allowed) in
            
            do{
                if (allowed){

                    try self.notificationModel!.validate()
                    
                    if self.notificationModel!.schedule != nil &&
                        StringUtils.isNullOrEmpty(self.notificationModel!.schedule!.createdDate
                    ){
                        let timeZone:String = self.notificationModel!.schedule!.timeZone ?? DateUtils.shared.localTimeZone.identifier
                        self.notificationModel!.schedule!.timeZone = timeZone
                        self.notificationModel!.schedule!.createdDate = DateUtils.shared.getLocalTextDate(fromTimeZone: timeZone)
                    }
                    else {
                        self.notificationModel?
                            .content?
                            .registerDisplayedEvent(
                                inLifeCycle: self.appLifeCycle)
                    }

                    self.execute()
                }
                else {
                    throw AwesomeNotificationsException.notificationNotAuthorized
                }
            } catch {
                self.completion(false, nil, error)
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
        
        do {

            if (notificationModel != nil){
                
                if ((notificationModel!.content!.id ?? -1) < 0){
                    notificationModel!.content!.id = IntUtils.generateNextRandomId();
                }

                var receivedNotification: NotificationReceived? = nil

                if (
                    !StringUtils.isNullOrEmpty(notificationModel!.content!.title) ||
                    !StringUtils.isNullOrEmpty(notificationModel!.content!.body)
                ){
                    notificationModel = try showNotification(notificationModel!)

                    // Only save DisplayedMethods if notificationModel was created and displayed successfully
                    if(notificationModel != nil){
                        
                        let now = DateUtils.shared.getUTCDateTime()
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
            completion(false, nil, error)
        }

        notificationModel = nil
        return nil
    }

    private func onPostExecute(receivedNotification:NotificationReceived?) {

        if refreshNotification {
            completion(true, content, nil)
            return
        }
        
        // Only broadcast if notificationModel is valid
        if(receivedNotification != nil){

            if(created){
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        notificationCreated: receivedNotification!,
                        whenFinished: { [self] (created:Bool) in
                            if scheduled == nil {
                                BroadcastSender
                                    .shared
                                    .sendBroadcast(
                                        notificationDisplayed: receivedNotification!,
                                        whenFinished: { [self] (created:Bool) in
                                            completion(true, content, nil)
                                        })
                            }
                            else {
                                DisplayedManager
                                    .saveScheduledToDisplay(
                                        received: receivedNotification!)
                                completion(true, content, nil)
                            }
                        })
            }
            else {
                
                if scheduled == nil {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            notificationDisplayed: receivedNotification!,
                            whenFinished: { [self] (created:Bool) in
                                completion(true, content, nil)
                            })
                }
                else {
                    DisplayedManager
                        .saveScheduledToDisplay(
                            received: receivedNotification!)
                    completion(true, content, nil)
                }
            }
        }
        else {
            completion(false, nil, nil)
        }
    }

    /// AsyncTask METHODS END *********************************

    public func showNotification(_ notificationModel:NotificationModel) throws -> NotificationModel? {
        
        return try NotificationBuilder
                        .newInstance()
                        .createNotification(notificationModel, content: content)
    }

}
