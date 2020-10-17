//
//  NotificationService.swift
//  AwesomeServiceExtension
//
//  Created by Rafael Setragni on 15/10/20.
//

import UserNotifications


@available(iOS 10.0, *)
public class AwesomeServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var content: UNMutableNotificationContent?
    //var fcmService: FCMService?
    var pushNotification: PushNotification?
    
    public init() {
    }
    
    public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.content = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let content = content {
            if(!StringUtils.isNullOrEmpty(content.userInfo["gcm.message_id"] as? String)){
                print("FCM received")
                
                var mapData:[String:Any?] = [:]
                
                if content.userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] != nil {
                    
                    mapData[Definitions.PUSH_NOTIFICATION_CONTENT]  = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] as? String)
                    mapData[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String)
                    mapData[Definitions.PUSH_NOTIFICATION_BUTTONS]  = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String)
                    
                    pushNotification = PushNotification().fromMap(arguments: mapData) as? PushNotification
                    
                    if let pushNotification = pushNotification {
                        do {
                            try NotificationSenderAndScheduler().send(
                                createdSource: NotificationSource.Firebase,
                                pushNotification: pushNotification,
                                content: content,
                                completion: { sent, content ,error  in
                                    
                                    if sent {
                                        contentHandler(content!)
                                    }
                                    
                                }
                            )
                        } catch {
                            contentHandler(content)
                        }
                    }
                }
            }
        }
    }
    
    public func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let content =  content {
            
            /*if let fcmService = self.fcmService {
                if let content = fcmService.serviceExtensionTimeWillExpire(content) {
                    contentHandler(content)
                }
            }
            else {
                contentHandler(content)
            }*/
            contentHandler(content)
        }
    }

}
