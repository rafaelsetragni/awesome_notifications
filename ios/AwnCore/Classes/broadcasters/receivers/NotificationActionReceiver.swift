//
//  NotificationActionReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class NotificationActionReceiver {
    
    let TAG = "NotificationActionReceiver"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:NotificationActionReceiver?
    public static var shared:NotificationActionReceiver {
        get {
            NotificationActionReceiver.instance =
                NotificationActionReceiver.instance ?? NotificationActionReceiver()
            return NotificationActionReceiver.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    public func addNewActionEvent(
        fromResponse response: UNNotificationResponse,
        whenFinished completionHandler: @escaping (Bool, Error?) -> Void
    ) throws {
     
        var userText:String?
        if let textResponse = response as? UNTextInputNotificationResponse {
            userText =  textResponse.userText
        }
        
        var notificationModel:NotificationModel? = nil
        
        if let jsonData:String =
            response
                .notification
                .request
                .content
                .userInfo[Definitions.NOTIFICATION_JSON] as? String
        {
            notificationModel =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationFromJson(
                        jsonData: jsonData)
        }
        else {
            if response
                .notification
                .request
                .content
                .userInfo["gcm.message_id"] == nil
            {
                throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "The action content doesn't contain any awesome information",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".addNewActionEvent.jsonData")
            }
            
            let title:String? = response.notification.request.content.title
            let body:String? = response.notification.request.content.body
            
            if StringUtils.shared.isNullOrEmpty(title) && StringUtils.shared.isNullOrEmpty(body) {
                throw ExceptionFactory
                    .shared
                    .createNewAwesomeException(
                        className: TAG,
                        code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                        message: "The action content doesn't contain any awesome information",
                        detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".addNewActionEvent.jsonData")
            }
            
            let date:Date = response.notification.date
            let image:String? = (response
                .notification
                .request
                .content
                .userInfo["fcm_options"] as? [String : Any?])?["image"] as? String
            
            notificationModel = NotificationModel()
            notificationModel!.content = NotificationContentModel()
            notificationModel!.content!.id = -1
            notificationModel!.content!.title = title
            notificationModel!.content!.body = body
            notificationModel!.content!.createdDate = RealDateTime
                .init(fromDate: date, inTimeZone: DateUtils.shared.utcTimeZone)
            notificationModel!.content!.displayedDate =
                notificationModel!.content!.createdDate
            
            if image != nil {
                notificationModel!.content!.notificationLayout = .BigPicture
                notificationModel!.content!.bigPicture = image
            }
        }
            
        guard let actionReceived:ActionReceived =
                NotificationBuilder
                    .newInstance()
                    .buildNotificationActionFromModel(
                        notificationModel: notificationModel,
                        buttonKeyPressed:
                            response.actionIdentifier == UNNotificationDefaultActionIdentifier.description ?
                            "" : response.actionIdentifier,
                        userText: userText)
        else {
            throw ExceptionFactory
                .shared
                .createNewAwesomeException(
                    className: TAG,
                    code: ExceptionCode.CODE_INVALID_ARGUMENTS,
                    message: "The action content doesn't contain any valid awesome content",
                    detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".addNewActionEvent.actionReceived")
        }
        
        let currentLifeCycle:NotificationLifeCycle =
            LifeCycleManager
                .shared
                .currentLifeCycle
        
        actionReceived.registerLastDisplayedEvent(
            inLifeCycle: currentLifeCycle,
            fromNotificationResponse: response,
            fromNotificationSchedule: notificationModel!.schedule
        )
        
        if actionReceived.actionType == .DismissAction {
            actionReceived.registerDismissedEvent(
                withLifeCycle: currentLifeCycle)
        }
        else {
            actionReceived.registerActionEvent(
                withLifeCycle: currentLifeCycle)
        }
        
// Feature deactivated, because this is not the expected iOS notification behavior
//        if #available(iOS 15.0, *), !actionReceived.autoDismissible! {
//            if let notificationModel:NotificationModel =
//                    NotificationBuilder
//                        .newInstance()
//                        .buildNotificationFromJson(
//                            jsonData: jsonData)
//            {
//                let isOutOfFocus =
//                        LifeCycleManager
//                            .shared
//                            .isOutOfFocus
//
//                DispatchQueue
//                    .global(qos: .background)
//                    .asyncAfter(deadline: .now() +
//                                (isOutOfFocus ? 1.5 : 0)) {
//                        do {
//                            try NotificationSenderAndScheduler
//                                    .mimicPersistentNotification(
//                                        notificationModel: notificationModel)
//                        } catch {
//                            Logger.e(self.TAG, "\(error)")
//                        }
//                    }
//            }
//        }
        
        switch actionReceived.actionType! {
            
            case .Default:
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        actionReceived: actionReceived,
                        whenFinished: completionHandler)
                break
                
            case .KeepOnTop:
                if LifeCycleManager.shared.currentLifeCycle != .AppKilled {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            actionReceived: actionReceived,
                            whenFinished: completionHandler)
                }
                else {
                    BroadcastSender
                        .shared
                        .enqueue(
                            silentAction: actionReceived,
                            whenFinished: completionHandler)
                }
                break
                
            case .SilentAction:
                if LifeCycleManager.shared.currentLifeCycle != .AppKilled {
                    BroadcastSender
                        .shared
                        .sendBroadcast(
                            silentAction: actionReceived,
                            whenFinished: completionHandler)
                }
                else {
                    BroadcastSender
                        .shared
                        .enqueue(
                            silentBackgroundAction: actionReceived,
                            whenFinished: completionHandler)
                }
                break
                
            case .SilentBackgroundAction:
                BroadcastSender
                    .shared
                    .enqueue(
                        silentBackgroundAction: actionReceived,
                        whenFinished: completionHandler)
                break
            
            case .DismissAction:
                BroadcastSender
                    .shared
                    .sendBroadcast(
                        notificationDismissed: actionReceived,
                        whenFinished: completionHandler)
                break
                
            case .DisabledAction:
                completionHandler(true, nil)
                break
            
            default:
                completionHandler(true, nil)
                break
        }
    }
    
}
