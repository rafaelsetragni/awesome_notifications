//
//  NotificationBuilder.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

class NotificationBuilder {
    
    private static var badgeAmount:NSNumber = 0
    
    public static func requestPermissions(){
        requestPermissions(UIApplication.shared)
    }
    
    public static func incrementBadge(){
        NotificationBuilder.badgeAmount = NSNumber(value: NotificationBuilder.badgeAmount.intValue + 1)
    }
    
    public static func resetBadge(){
        NotificationBuilder.badgeAmount = 0
    }
    
    public static func getBadge() -> NSNumber {
        return NotificationBuilder.badgeAmount
    }
    
    public static func requestPermissions(_ application:UIApplication){
        
        if #available(iOS 10, *)
        {
            // iOS 10 support
            let notificationCenter = UNUserNotificationCenter.current()
            
            notificationCenter.requestAuthorization(options: [.sound,.alert,.badge]) { (granted, error) in
                if granted {
                    DispatchQueue.main.async {
                      application.registerForRemoteNotifications()
                    }
                    print("Notification Enable Successfully")
                }
            }
        }
        else if #available(iOS 9, *)
        {
            // iOS 9 support
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            application.registerForRemoteNotifications()
            
            print("Notification Enable Successfully")
        }
        else if #available(iOS 8, *)
        {
            // iOS 8 support
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            application.registerForRemoteNotifications()
            
            print("Notification Enable Successfully")
        }
        else
        { // iOS 7 support
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
            
            print("Notification Enable Successfully")
        }        
    }
    
    public static func isNotificationAuthorized() -> Bool {
        
        let application = UIApplication.shared
        
        if #available(iOS 10, *)
        {
            // iOS 10 support
            // TODO
        }
        else if #available(iOS 9, *)
        {
            // iOS 9 support
            // TODO
        }
        else if #available(iOS 8, *)
        {
            // iOS 8 support
            // TODO
        }
        else
        { // iOS 7 support
            // TODO
        }
        
        return true
    }
    
    public static func buildNotificationActionFromJson(jsonData:String?) -> ActionReceived? {
        if(StringUtils.isNullOrEmpty(jsonData)){ return nil }
        
        let data:[String:Any?]? = JsonUtils.fromJson(jsonData)
        if(data == nil){ return nil }
        
        let pushNotification:PushNotification? = PushNotification().fromMap(arguments: data!) as? PushNotification
        if(pushNotification == nil){ return nil }
        let actionReceived:ActionReceived = ActionReceived(pushNotification!.content)
        
        actionReceived.actionLifeCycle = SwiftAwesomeNotificationsPlugin.getApplicationLifeCycle()
        actionReceived.actionDate = DateUtils.getUTCDate()
        
        if(StringUtils.isNullOrEmpty(actionReceived.displayedDate)){
            actionReceived.displayedDate = DateUtils.getUTCDate()
        }
        
        return actionReceived
    }
    
    public static func createNotification(_ pushNotification:PushNotification) throws -> PushNotification? {
        
        if #available(iOS 10, *)
        {
            // 1
            let content = UNMutableNotificationContent()
            guard let channel = ChannelManager.getChannelByKey(channelKey: pushNotification.content!.channelKey!) else {
                return nil
            }
            
            content.title = pushNotification.content!.title ?? ""
            content.subtitle = pushNotification.content!.summary ?? ""
            content.body = pushNotification.content!.body ?? ""
            
            if(channel.channelShowBadge!){ NotificationBuilder.incrementBadge() }
            content.badge = NotificationBuilder.getBadge()
            
            let pushData = pushNotification.toMap()
            let jsonData = JsonUtils.toJson(pushData)
            content.userInfo[Definitions.NOTIFICATION_JSON] = jsonData
            
            /*
            // 2
            let imageName = "applelogo"
            guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") else { return }
                
            let attachment = try! UNNotificationAttachment(identifier: imageName, url: imageURL, options: .none)
                
            content.attachments = [attachment]
            */
            // 3
            
            
            let request = UNNotificationRequest(identifier: pushNotification.content!.id!.description, content: content, trigger: nil)
            
            // 4
            UNUserNotificationCenter.current().add(request)
            {
                error in // called when message has been sent

                if error != nil {
                    debugPrint("Error: \(error.debugDescription)")
                }
            }
        }
        
        return pushNotification
    }
    
    public static func cancelNotification(id:Int){
        let referenceKey:String = String(id)
        
        if #available(iOS 10.0, *) {
            
            let center = UNUserNotificationCenter.current()
            center.removeDeliveredNotifications(withIdentifiers: [referenceKey])
            center.removePendingNotificationRequests(withIdentifiers: [referenceKey])
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    public static func cancellAllNotifications(){
        
        if #available(iOS 10.0, *) {
            
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
            
        } else {
            // Fallback on earlier versions
        }
    }
    
}
