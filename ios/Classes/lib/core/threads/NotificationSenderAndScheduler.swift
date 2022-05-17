//
//  NotificationSender.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

@available(iOS 10.0, *)
public class NotificationSenderAndScheduler {

    public static let TAG: String = "NotificationSender"

    private var createdSource:      NotificationSource
    private var appLifeCycle:       NotificationLifeCycle
    private var notificationModel:  NotificationModel?
    private var content:            UNMutableNotificationContent?
    
    private var refreshNotification:Bool = false
    private var created:   Bool = false
    private var scheduled: RealDateTime?
    private var startTime: DispatchTime
    
    private var originalUserInfo:[AnyHashable:Any]?
    
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
                appLifeCycle: appLifeCycle
            ).send(completion: completion)
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
                appLifeCycle: appLifeCycle
            ).send(completion: completion)
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
                appLifeCycle: notificationModel.content!.createdLifeCycle!
            ).send(completion: { _, __, ___ in
            })
    }
    
    private init(
        createdSource: NotificationSource,
        notificationModel: NotificationModel,
        content: UNMutableNotificationContent?,
        isRefreshNotification: Bool,
        appLifeCycle: NotificationLifeCycle
    ){
        self.createdSource =
            createdSource == .Local  && notificationModel.schedule != nil ?
            .Schedule : createdSource
        
        self.refreshNotification = isRefreshNotification
        self.content = content
        self.notificationModel = notificationModel
        self.appLifeCycle = appLifeCycle
        self.startTime = DispatchTime.now()
    }
    
    private func send(completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()) throws {

        PermissionManager
            .shared
            .areNotificationsGloballyAllowed(whenGotResults: { (allowed) in
            
            do{
                if (allowed){
                    try self.execute(completion: completion)
                }
                else {
                    throw ExceptionFactory
                            .shared
                            .createNewAwesomeException(
                                className: NotificationIntervalModel.TAG,
                                code: ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                                message: "Notifications are disabled",
                                detailedCode: ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".global")
                }
            } catch {
                completion(false, nil, error)
            }
        })
    }

    private func execute(
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ) throws {
        try self.doInBackground(completion: { notificationReceived in
            self.onPostExecute(
                receivedNotification: notificationReceived,
                completion: completion
            )
        })
    }
    
    /// AsyncTask METHODS BEGIN *********************************

    private func doInBackground(
        completion: @escaping (NotificationReceived?) -> ()
    ) throws {
        guard let notificationModel = self.notificationModel else {
            completion(nil)
            return
        }
            
        if (notificationModel.content!.id ?? -1) < 0 {
            notificationModel.content!.id = IntUtils.generateNextRandomId();
        }
        
        try notificationModel.validate()
        
        self.created =
            notificationModel
                .content!
                .registerCreateEvent(
                    inLifeCycle: self.appLifeCycle,
                    fromSource: self.createdSource)
        
        if notificationModel.schedule != nil {
            let timeZone:TimeZone = self.notificationModel!.schedule!.timeZone ?? TimeZone.current
            notificationModel.schedule!.timeZone = timeZone
            notificationModel.schedule!.createdDate = RealDateTime.init(fromTimeZone: timeZone)
        }

        var receivedNotification: NotificationReceived? = nil
        if (
            !StringUtils.shared.isNullOrEmpty(notificationModel.content!.title) ||
            !StringUtils.shared.isNullOrEmpty(notificationModel.content!.body)
        ){
            try showNotification(
                notificationModel,
                completion:  { [self] notificationModel in
                    
                    // Only save DisplayedMethods if notificationModel was created and displayed successfully
                    guard let notificationModel:NotificationModel = notificationModel
                    else {
                        completion(nil)
                        return
                    }
                        
                    let now = RealDateTime.init(fromTimeZone: RealDateTime.utcTimeZone)
                    
                    if notificationModel.nextValidDate == nil {
                        notificationModel.content!.displayedDate = notificationModel.content!.createdDate
                        notificationModel.content!.displayedLifeCycle = notificationModel.content!.createdLifeCycle
                    }
                    else {
                        scheduled = notificationModel.nextValidDate
                        notificationModel.content!.displayedDate =
                            scheduled?.shiftTimeZone(toTimeZone: RealDateTime.utcTimeZone) ??
                            notificationModel.content!.displayedDate
                        
                        if notificationModel.nextValidDate! <= now {
                            notificationModel.content!.displayedLifeCycle = self.appLifeCycle
                        }
                        else {
                            notificationModel.content!.displayedLifeCycle = NotificationLifeCycle.AppKilled
                        }
                    }
                    
                    receivedNotification = NotificationReceived(notificationModel.content)
                    receivedNotification?.registerDisplayedEvent(inLifeCycle: self.appLifeCycle)

                    receivedNotification!.displayedLifeCycle =
                        receivedNotification!.displayedLifeCycle ?? self.appLifeCycle
                    
                    completion(receivedNotification)
                })
            return
        } else {
            receivedNotification = NotificationReceived(notificationModel.content)
        }
        completion(receivedNotification)
    }

    private func onPostExecute(
        receivedNotification:NotificationReceived?,
        completion: @escaping (Bool, UNMutableNotificationContent?, Error?) -> ()
    ){
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
                            
                            if created && scheduled == nil && receivedNotification?.id != nil {
                                removePastSchedule(withId:receivedNotification!.id!)
                            }
                            
                            if scheduled == nil {
                                printElapsedTime(scheduled: false)
                                BroadcastSender
                                    .shared
                                    .sendBroadcast(
                                        notificationDisplayed: receivedNotification!,
                                        whenFinished: { [self] (created:Bool) in
                                            completion(true, content, nil)
                                        })
                            }
                            else {
                                printElapsedTime(scheduled: true)
                                DisplayedManager
                                    .saveScheduledToDisplay(
                                        received: receivedNotification!)
                                completion(true, content, nil)
                            }
                        })
            }
            else {
                
                if created && scheduled == nil && receivedNotification?.id != nil {
                    removePastSchedule(withId:receivedNotification!.id!)
                }
                
                if scheduled == nil {
                    printElapsedTime(scheduled: false)
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            notificationDisplayed: receivedNotification!,
                            whenFinished: { [self] (created:Bool) in
                                completion(true, content, nil)
                            })
                }
                else {
                    printElapsedTime(scheduled: true)
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
    
    private func removePastSchedule(withId id:Int){
        _ = ScheduleManager
            .shared
            .remove(referenceKey: String(id))
    }
    
    private func printElapsedTime(scheduled:Bool){
        if !AwesomeNotifications.debug {
            return
        }
        
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval:Double = Double(nanoTime) / 1_000_000
        Logger.d(
            BackgroundService.TAG,
            "Notification \(scheduled ? "scheduled" : "displayed") in \(timeInterval.rounded())ms")
    }

    /// AsyncTask METHODS END *********************************

    public func showNotification(
        _ notificationModel:NotificationModel,
        completion: @escaping (NotificationModel?) -> ()
    ) throws {
        try NotificationBuilder
                .newInstance()
                .createNotification(
                        notificationModel,
                        content: content,
                        completion: completion)
    }

}
