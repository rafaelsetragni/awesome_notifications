//
//  DisplayedManager.swift
//  awesome_notifications
//
//  Displayed by Rafael Setragni on 15/09/20.
//

import Foundation

public class DisplayedManager {
    
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_DISPLAYED)
    static let pendingShared:SharedManager = SharedManager(tag: "PendingDisplayed")
    
    static var pendingDisplay:[String:String] = pendingShared.get(referenceKey: "pending") as? [String:String] ?? [:]
    
    public static func removeDisplayed(id:Int) -> Bool {
        let referenceKey = String(id)
        for (epoch, scheduledId) in pendingDisplay {
            if (scheduledId == referenceKey) {
                pendingDisplay.removeValue(forKey: epoch)
            }
        }
        updatePendingList()
        return shared.remove(referenceKey: referenceKey)
    }

    public static func listDisplayed() -> [NotificationReceived] {
        var returnedList:[NotificationReceived] = []
        let dataList = shared.getAllObjects()
        
        for data in dataList {
            let received:NotificationReceived = NotificationReceived(nil).fromMap(arguments: data) as! NotificationReceived
            returnedList.append(received)
        }
        
        return returnedList
    }
    
    public static func listPendingDisplayed(referenceDate:Date) -> [NotificationReceived] {
        var returnedList:[NotificationReceived] = []
        let referenceEpoch = referenceDate.timeIntervalSince1970.description
        
        for (epoch, id) in pendingDisplay {
            if epoch <= referenceEpoch {
                let notification = getDisplayedByKey(id: Int(id)!)
                if notification != nil{
                    returnedList.append(notification!)
                }
            }
        }
        
        return returnedList
    }

    public static func saveDisplayed(received:NotificationReceived) {
        let referenceKey = String(received.id!)
        let epoch:String = ( received.displayedDate?.toDate() ?? Date() ).secondsSince1970.description
        
        pendingDisplay[epoch] = referenceKey
        shared.set(received.toMap(), referenceKey:referenceKey)
        updatePendingList()
    }
    
    public static func updatePendingList(){
        pendingShared.set(pendingDisplay, referenceKey:"pending")
    }

    public static func getDisplayedByKey(id:Int) -> NotificationReceived? {
        return NotificationReceived(nil).fromMap(arguments: shared.get(referenceKey: String(id))) as? NotificationReceived
    }

    public static func cancelAllDisplayed() {
        let receivedList = shared.getAllObjects();
        
        for received:[String:Any?] in receivedList {
            cancelDisplayed(id: received["id"] as! Int);
        }
    }

    public static func cancelDisplayed(id:Int) {
        _ = shared.remove(referenceKey: String(id))
    }
    
}
