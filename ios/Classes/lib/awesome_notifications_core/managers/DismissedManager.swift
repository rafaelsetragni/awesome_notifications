//
//  DismissedManager.swift
//  awesome_notifications
//
//  Dismissed by CardaDev on 31/01/22.
//

import Foundation

public class DismissedManager {
    
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_DISMISSED)
    
    public static func removeDismissed(id:Int) -> Bool {
        return shared.remove(referenceKey: String(id));
    }

    public static func listDismissed() -> [ActionReceived] {
        var returnedList:[ActionReceived] = []
        let dataList = shared.getAllObjects()
        
        for data in dataList {
            let received:ActionReceived = ActionReceived(nil).fromMap(arguments: data) as! ActionReceived
            returnedList.append(received)
        }
        
        return returnedList
    }

    public static func saveDismissed(received:NotificationReceived) {
        shared.set(received.toMap(), referenceKey: String(received.id!))
    }

    public static func getDismissedByKey(id:Int) -> ActionReceived? {
        guard let data:[String:Any?] = shared.get(referenceKey: String(id)) else {
          return nil
        }
        return ActionReceived(nil).fromMap(arguments: data) as? ActionReceived
    }

    public static func removeAllDismissed() {
        shared.removeAll()
    }

    public static func removeDismissed(id:Int) {
        _ = shared.remove(referenceKey: String(id))
    }
    
}
