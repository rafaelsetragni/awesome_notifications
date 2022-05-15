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
        self.startTime = DispatchTime.now()
    }
    
    private func send() throws {

        PermissionManager
            .shared
            .areNotificationsGloballyAllowed(whenGotResults: { (allowed) in
            
            do{
                if (allowed){
                    try self.execute()
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
                self.completion(false, nil, error)
            }
        })
    }

    private func execute() throws {
        //DispatchQueue.global(qos: .background).async {
            
            let notificationReceived:NotificationReceived? = try self.doInBackground()

            //DispatchQueue.main.async {
                self.onPostExecute(receivedNotification: notificationReceived)
            //}
        //}
    }
    
    /// AsyncTask METHODS BEGIN *********************************

    private func doInBackground() throws -> NotificationReceived?{
        
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
                    !StringUtils.shared.isNullOrEmpty(notificationModel!.content!.title) ||
                    !StringUtils.shared.isNullOrEmpty(notificationModel!.content!.body)
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

    public func showNotification(_ notificationModel:NotificationModel) throws -> NotificationModel? {
        
        return try NotificationBuilder
                        .newInstance()
                        .createNotification(notificationModel, content: content)
    }

}
