//
//  NotificationService.swift
//  AwesomeServiceExtension
//
//  Created by Rafael Setragni on 16/10/20.
//

@available(iOS 10.0, *)
open class AwesomeServiceExtension: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var content: UNMutableNotificationContent?
    //var fcmService: FCMService?
    var pushNotification: PushNotification?
    
    
    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ){
        self.contentHandler = contentHandler
        self.content = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let content = content {
            
            if(!StringUtils.isNullOrEmpty(content.userInfo["gcm.message_id"] as? String)){
                print("FCM received")
                
                let title:String? = content.title
                let body:String?  = content.body
                var image:String?
                
                if let options = content.userInfo["fcm_options"] as? NSDictionary {
                    image = options["image"] as? String
                }
                
                if content.userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] == nil {
                    
                    pushNotification = PushNotification()
                    pushNotification!.content = NotificationContentModel()
                    
                    pushNotification!.content!.id = Int.random(in: 1..<2147483647)
                    pushNotification!.content!.channelKey = "basic_channel"
                    pushNotification!.content!.title = title
                    pushNotification!.content!.body = body
                    pushNotification!.content!.playSound = true
                    
                    if !StringUtils.isNullOrEmpty(image) {
                        pushNotification!.content!.notificationLayout = NotificationLayout.BigPicture
                        pushNotification!.content!.bigPicture = image
                    }
                    else {
                        pushNotification!.content!.notificationLayout = NotificationLayout.Default
                    }
                }
                else {
                    
                    var mapData:[String:Any?] = [:]
                    
                    mapData[Definitions.PUSH_NOTIFICATION_CONTENT]  = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_CONTENT] as? String)
                    mapData[Definitions.PUSH_NOTIFICATION_SCHEDULE] = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_SCHEDULE] as? String)
                    mapData[Definitions.PUSH_NOTIFICATION_BUTTONS]  = JsonUtils.fromJson(content.userInfo[Definitions.PUSH_NOTIFICATION_BUTTONS] as? String)
                    
                    pushNotification = PushNotification().fromMap(arguments: mapData) as? PushNotification
                    
                }
                
                NotificationBuilder.setUserInfoContent(pushNotification: pushNotification!, content: content)
                
                if StringUtils.isNullOrEmpty(title) {
                    content.title = pushNotification?.content?.title ?? ""
                }
                
                if StringUtils.isNullOrEmpty(body) {
                    content.body = pushNotification?.content?.body ?? ""
                }
                
                content.categoryIdentifier = Definitions.DEFAULT_CATEGORY_IDENTIFIER
                //contentHandler(content)
                //return
                
                if let pushNotification = pushNotification {
                    do {
                        try NotificationSenderAndScheduler().send(
                            createdSource: NotificationSource.Firebase,
                            pushNotification: pushNotification,
                            content: content,
                            completion: { sent, newContent ,error  in
                                
                                if sent {
                                    contentHandler(newContent ?? content)
                                    return
                                }
                                
                            }
                        )
                    } catch {
                    }
                }
            }
            contentHandler(content)
        }
    }
    
    public override func serviceExtensionTimeWillExpire() {
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
