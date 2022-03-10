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
    private var scheduled:  RealDateTime?
    
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
        self.createdSource =
            createdSource == .Local  && notificationModel.schedule != nil ?
            .Schedule : createdSource
        
        self.refreshNotification = isRefreshNotification
        self.content = content
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
                
                try self.notificationModel!.validate()
                
                self.created =
                    self.notificationModel!
                        .content!
                        .registerCreateEvent(
                            inLifeCycle: self.appLifeCycle,
                            fromSource: self.createdSource)
                
                if self.notificationModel!.schedule != nil {
                    let timeZone:TimeZone = self.notificationModel!.schedule!.timeZone ?? TimeZone.current
                    self.notificationModel!.schedule!.timeZone = timeZone
                    self.notificationModel!.schedule!.createdDate = RealDateTime.init(fromTimeZone: timeZone)
                }

                var receivedNotification: NotificationReceived? = nil

                if (
                    !StringUtils.isNullOrEmpty(notificationModel!.content!.title) ||
                    !StringUtils.isNullOrEmpty(notificationModel!.content!.body)
                ){
                    notificationModel = try showNotification(notificationModel!)

                    // Only save DisplayedMethods if notificationModel was created and displayed successfully
                    if(notificationModel != nil){
                        
                        let now = RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
                        
                        if notificationModel!.nextValidDate == nil {
                            notificationModel!.content!.displayedDate = notificationModel!.content!.createdDate
                            notificationModel!.content!.displayedLifeCycle = notificationModel!.content!.createdLifeCycle
                        }
                        else {
                            scheduled = notificationModel!.nextValidDate
                            notificationModel!.content!.displayedDate =
                                scheduled?.shiftTimeZone(toTimeZone: RealDateTime.utcTimeZone) ??
                                notificationModel!.content!.displayedDate
                            
                            if notificationModel!.nextValidDate! <= now {
                                notificationModel!.content!.displayedLifeCycle = self.appLifeCycle
                            }
                            else {
                                notificationModel!.content!.displayedLifeCycle = NotificationLifeCycle.AppKilled
                            }
                        }
                        
                        receivedNotification = NotificationReceived(notificationModel!.content)

                        receivedNotification!.displayedLifeCycle =
                            receivedNotification!.displayedLifeCycle ?? self.appLifeCycle
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
