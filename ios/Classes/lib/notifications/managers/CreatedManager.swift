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
        shared.set(received.toMap(), referenceKey: String(received.id!))
    }

    public static func getCreatedByKey(id:Int) -> NotificationReceived? {
        guard let data:[String:Any?] = shared.get(referenceKey: String(id)) else {
          return nil
        }
        return NotificationReceived(nil).fromMap(arguments: data) as? NotificationReceived
    }

    public static func cancelAllCreated() {
        shared.removeAll()
    }

    public static func cancelCreated(id:Int) {
        _ = shared.remove(referenceKey: String(id))
    }
    
}
