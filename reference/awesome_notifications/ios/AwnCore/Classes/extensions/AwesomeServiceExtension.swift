//
//  NotificationService.swift
//  AwesomeServiceExtension
//
//  Created by Rafael Setragni on 16/10/20.
//

@available(iOS 10.0, *)
open class AwesomeServiceExtension: UNNotificationServiceExtension {
    let TAG = "AwesomeServiceExtension"
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var content: UNMutableNotificationContent?
    //var fcmService: FCMService?
    var notificationModel: NotificationModel?
    

    open override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ){
        self.contentHandler = contentHandler
        self.content = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let content = content {
            
            AwesomeNotifications.initialize()
            
            if(!StringUtils.shared.isNullOrEmpty(content.userInfo["gcm.message_id"] as? String)){
                Logger.d(TAG, "New push notification received")
                
                let title:String? = content.title
                let body:String?  = content.body
                var image:String?
                
                if let options = content.userInfo["fcm_options"] as? NSDictionary {
                    image = options["image"] as? String
                }
                
                if content.userInfo[Definitions.NOTIFICATION_MODEL_CONTENT] == nil {
                    Logger.d(TAG, "Notification translated to awesome content")
                    
                    notificationModel = NotificationModel()
                    notificationModel!.content = NotificationContentModel()
                    
                    notificationModel!.content!.id = IntUtils.generateNextRandomId();
                    notificationModel!.content!.channelKey = ChannelManager
                        .shared
                        .listChannels()
                        .first?
                        .channelKey ?? "basic_channel"
                    
                    notificationModel!.content!.title = title
                    notificationModel!.content!.body = body
                    notificationModel!.content!.playSound = true
                    
                    if !StringUtils.shared.isNullOrEmpty(image) {
                        notificationModel!.content!.notificationLayout = NotificationLayout.BigPicture
                        notificationModel!.content!.bigPicture = image
                    }
                    else {
                        notificationModel!.content!.notificationLayout = NotificationLayout.Default
                    }
                }
                else {
                    
                    var mapData:[String:Any?] = [:]
                    
                    mapData[Definitions.NOTIFICATION_MODEL_CONTENT]  = JsonUtils.fromJson(content.userInfo[Definitions.NOTIFICATION_MODEL_CONTENT] as? String)
                    mapData[Definitions.NOTIFICATION_MODEL_SCHEDULE] = JsonUtils.fromJson(content.userInfo[Definitions.NOTIFICATION_MODEL_SCHEDULE] as? String)
                    mapData[Definitions.NOTIFICATION_MODEL_BUTTONS]  = JsonUtils.fromJsonArr(content.userInfo[Definitions.NOTIFICATION_MODEL_BUTTONS] as? String)
                    
                    notificationModel = NotificationModel().fromMap(arguments: mapData) as? NotificationModel
                    
                    if StringUtils.shared.isNullOrEmpty(notificationModel?.content?.title, considerWhiteSpaceAsEmpty: true) {
                        notificationModel!.content!.title = title
                    }
                    
                    if StringUtils.shared.isNullOrEmpty(notificationModel?.content?.body, considerWhiteSpaceAsEmpty: true) {
                        notificationModel!.content!.body = body
                    }
                    
                    if !StringUtils.shared.isNullOrEmpty(image) {
                        notificationModel!.content!.notificationLayout = NotificationLayout.BigPicture
                        notificationModel!.content!.bigPicture = image
                    }
                }
                
                NotificationBuilder
                    .newInstance()
                    .setUserInfoContent(
                        notificationModel: notificationModel!,
                        content: content)
                
                if StringUtils.shared.isNullOrEmpty(title) {
                    content.title = notificationModel?.content?.title ?? ""
                }
                
                if StringUtils.shared.isNullOrEmpty(body) {
                    content.body = notificationModel?.content?.body ?? ""
                }
                
                content.categoryIdentifier = Definitions.DEFAULT_CATEGORY_IDENTIFIER
                //contentHandler(content)
                //return
                
                if let notificationModel = notificationModel {
                    do {
                        try NotificationSenderAndScheduler.send(
                            createdSource: NotificationSource.Firebase,
                            notificationModel: notificationModel,
                            content: content,
                            completion: { sent, newContent ,error  in
                                
                                if sent {
                                    contentHandler(newContent ?? content)
                                    return
                                }
                                else {
                                    contentHandler(UNNotificationContent())
                                    return
                                }
                                
                            },
                            appLifeCycle: LifeCycleManager
                                                .shared
                                                .currentLifeCycle
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
