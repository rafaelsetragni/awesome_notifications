//
//  ScheduleManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 23/09/20.
//

import Foundation

public class ScheduleManager {
    
    static let shared:SharedManager = SharedManager(tag: "NotificationSchedule")
    static let pendingShared:SharedManager = SharedManager(tag: "PendingSchedules")
    
    static var pendingSchedules:[String:String] = pendingShared.get(referenceKey: "pending") as? [String:String] ?? [:]
    
    public static func removeSchedule( id:Int ) -> Bool {
        let referenceKey = String(id)
        pendingSchedules.removeValue(forKey: referenceKey)
        updatePendingList()
        return shared.remove(referenceKey: referenceKey)
    }
    
    public static func listSchedules() -> [PushNotification] {
        var returnedList:[PushNotification] = []
        let dataList = shared.getAllObjects()
        
        for data in dataList {
            let channel:PushNotification = PushNotification().fromMap(arguments: data) as! PushNotification
            returnedList.append(channel)
        }
        
        return returnedList
    }
    
    public static func listPendingSchedules(referenceDate:Date) -> [PushNotification] {
        var returnedList:[PushNotification] = []
        let referenceEpoch = referenceDate.timeIntervalSince1970.description
        
        for (epoch, id) in pendingSchedules {
            if epoch <= referenceEpoch {
                let pushNotification = getScheduleByKey(id: Int(id)!)
                if pushNotification != nil{
                    returnedList.append(pushNotification!)
                }
            }
        }
        
        return returnedList
    }
    
    public static func saveSchedule(notification:PushNotification, nextDate:Date){
        let referenceKey =  String(notification.content!.id!)
        let epoch =  nextDate.secondsSince1970.description
        
        pendingSchedules[epoch] = referenceKey
        shared.set(notification.toMap(), referenceKey:referenceKey)
        updatePendingList()
    }
    
    public static func updatePendingList(){
        pendingShared.set(pendingSchedules, referenceKey:"pending")
    }
    
    public static func getEarliestDate() -> Date? {
        var smallest:String?
        
        for (epoch, _) in pendingSchedules {

            if smallest == nil || smallest! > epoch {
                 smallest = epoch
            }
        }
        
        if(smallest == nil){ return nil }
        
        let seconds:Int64 = Int64(smallest!)!
        let smallestDate:Date? = Date(seconds: seconds)
        
        return smallestDate
    }
    
    public static func getScheduleByKey( id:Int ) -> PushNotification? {
        return PushNotification().fromMap(arguments: shared.get(referenceKey: String(id))) as? PushNotification
    }
    
    public static func isNotificationScheduleActive( channelKey:String ) -> Bool {
        return shared.get(referenceKey: channelKey) != nil
    }
    
}
