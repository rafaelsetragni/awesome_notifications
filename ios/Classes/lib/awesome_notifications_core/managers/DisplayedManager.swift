//
//  DisplayedManager.swift
//  awesome_notifications
//
//  Displayed by Rafael Setragni on 15/09/20.
//

import Foundation

public class DisplayedManager {
    
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_DISPLAYED)
    static let pendingShared:SharedManager = SharedManager(tag: Definitions.SHARED_SCHEDULED_DISPLAYED)
    
    static var pendingSchedulesDisplayed:[String:[String:Any]] =
        pendingShared.get(referenceKey: Definitions.SHARED_SCHEDULED_DISPLAYED_REFERENCE) as? [String:[String:Any]] ?? [:]
    
    public static func removeDisplayed(id:Int) -> Bool {
        return shared.remove(referenceKey: String(id))
    }
    
    public static func saveDisplayed(received:NotificationReceived) {
        let referenceKey = String(received.id!)
        let dataMap = received.toMap()
        
        shared.set(dataMap, referenceKey:referenceKey)
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
    
    public static func getDisplayedByKey(id:Int) -> NotificationReceived? {
        guard let data:[String:Any?] = shared.get(referenceKey: String(id)) else {
          return nil
        }
        return NotificationReceived(nil).fromMap(arguments: data) as? NotificationReceived
    }
    
    public static func updatePendingList(){
        pendingShared.set(pendingSchedulesDisplayed, referenceKey: Definitions.SHARED_SCHEDULED_DISPLAYED_REFERENCE)
    }
    
    public static func saveScheduledToDisplay(received:NotificationReceived) {
        let referenceKey = String(received.id!)
        let epoch:String = ( received.displayedDate?.toDate(fromTimeZone: "UTC") ?? Date() ).secondsSince1970.description
        let dataMap = received.toMap()
        
        if(pendingSchedulesDisplayed[epoch] == nil){
            pendingSchedulesDisplayed[epoch] = [:]
        }
        
        pendingSchedulesDisplayed[epoch]![referenceKey] = dataMap
        updatePendingList()
    }
    
    public static func removeScheduledToDisplay(id:Int) -> Bool {
        let referenceKey:String = String(id)
        var removed = false
        
        for (epoch, alreadyDisplayed) in pendingSchedulesDisplayed {
            var listToRemove:[String] = []
            
            for (pendingReferenceKey, _) in alreadyDisplayed {
                if pendingReferenceKey == referenceKey {
                    listToRemove.append(pendingReferenceKey)
                }
            }
            
            for (pendingReferenceKey) in listToRemove {
                removed = true
                pendingSchedulesDisplayed[epoch]?.removeValue(forKey: pendingReferenceKey)
            }
        }
        
        return removed
    }
    
    public static func reloadLostSchedulesDisplayed(referenceDate:Date){
        let referenceEpoch = referenceDate.timeIntervalSince1970.description
    
        for (epoch, alreadyDisplayed) in pendingSchedulesDisplayed {
            if epoch <= referenceEpoch {
                for (referenceKey, dataMap) in alreadyDisplayed {
                    if let dataMap = dataMap as? [String:Any] {
                        shared.set(dataMap, referenceKey:referenceKey)
                    }
                }
                pendingSchedulesDisplayed.removeValue(forKey: epoch)
            }
        }
        
        updatePendingList()
    }

    public static func cancelAllDisplayed() {
        shared.removeAll()
        pendingSchedulesDisplayed.removeAll()
        updatePendingList()
    }

    public static func cancelDisplayed(id:Int) {
        _ = removeDisplayed(id: id)
        _ = removeScheduledToDisplay(id: id)
    }
    
}
