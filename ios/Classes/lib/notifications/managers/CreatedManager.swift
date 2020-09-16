//
//  CreatedManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 15/09/20.
//

import Foundation

public class CreatedManager {
    
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_CREATED)
    
    public static func removeCreated(id:Int) -> Bool {
        return shared.remove(referenceKey: String(id));
    }

    public static func listCreated() -> [NotificationReceived] {
        var returnedList:[NotificationReceived] = []
        let dataList = shared.getAllObjects()
        
        for data in dataList {
            let received:NotificationReceived = NotificationReceived(nil).fromMap(arguments: data) as! NotificationReceived
            returnedList.append(received)
        }
        
        return returnedList
    }

    public static func saveCreated(received:NotificationReceived) {
        shared.set(received.toMap(), referenceKey: String(describing: received.id))
    }

    public static func getCreatedByKey(id:Int) -> NotificationReceived? {
        return NotificationReceived(nil).fromMap(arguments: shared.get(referenceKey: String(id))) as? NotificationReceived
    }

    public static func cancelAllCreated() {
        let receivedList = shared.getAllObjects();
        
        for received:[String:Any?] in receivedList {
            cancelCreated(id: received["id"] as! Int);
        }
    }

    public static func cancelCreated(id:Int) {
        shared.remove(referenceKey: String(id))
    }
    
}
