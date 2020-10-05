//
//  ScheduleManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 23/09/20.
//

import Foundation

public class ScheduleManager {
    
    public static func removeScheduled(id:Int) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(id)])
        } else {
            // Fallback on earlier versions
        }
    }

    public static func listScheduled(completion: @escaping ([PushNotification]) -> ()){
        
        var scheduleds:[PushNotification] = []
        
        if #available(iOS 10.0, *) {
            
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { notifications in
                
                for notification in notifications {
                    let jsonData:String? = notification.content.userInfo[Definitions.NOTIFICATION_JSON] as? String
                    let pushNotification:PushNotification? = NotificationBuilder.jsonToPushNotification(jsonData: jsonData)
                    if(pushNotification != nil){
                        scheduleds.append(pushNotification!)
                    }
                }
                
                completion(scheduleds)
            })
            
        } else {
            completion(scheduleds)
        }
    }

    public static func saveScheduled(received:NotificationReceived) {
        
    }

    public static func getScheduledByKey(id:Int, completion: @escaping (PushNotification?) -> ()) {
        
        listScheduled(completion: { scheduleds in
            for notification in scheduleds {
                if notification.content?.id == id {
                    completion(notification)
                }
            }
            completion(nil)
        })
    }

    public static func cancelAllScheduled() {
    }

    public static func cancelScheduled(id:Int) {
    }
    
}
