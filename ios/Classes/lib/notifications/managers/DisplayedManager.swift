//
//  DisplayedManager.swift
//  awesome_notifications
//
//  Displayed by Rafael Setragni on 15/09/20.
//

import Foundation

public class DisplayedManager {
    
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_DISPLAYED)
    
    public static func removeDisplayed(id:Int) -> Bool {
        return shared.remove(referenceKey: String(id));
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

    public static func saveDisplayed(received:NotificationReceived) {
        shared.set(received.toMap(), referenceKey: String(describing: received.id))
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
        shared.remove(referenceKey: String(id))
    }
    
}
