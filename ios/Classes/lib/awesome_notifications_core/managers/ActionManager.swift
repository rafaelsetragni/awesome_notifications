//
//  ActionManager.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class ActionManager {
    
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_ACTIONS)
    
    public static func removeAction(id:Int) -> Bool {
        return shared.remove(referenceKey: String(id));
    }

    public static func listActions() -> [ActionReceived] {
        var returnedList:[ActionReceived] = []
        let dataList = shared.getAllObjects()
        
        for data in dataList {
            let received:ActionReceived = ActionReceived(nil).fromMap(arguments: data) as! ActionReceived
            returnedList.append(received)
        }
        
        return returnedList
    }

    public static func saveAction(received:NotificationReceived) {
        shared.set(received.toMap(), referenceKey: String(received.id!))
    }

    public static func getActionByKey(id:Int) -> ActionReceived? {
        guard let data:[String:Any?] = shared.get(referenceKey: String(id)) else {
          return nil
        }
        return ActionReceived(nil).fromMap(arguments: data) as? ActionReceived
    }

    public static func removeAllActions() {
        shared.removeAll()
    }

    public static func removeAction(id:Int) {
        _ = shared.remove(referenceKey: String(id))
    }
    
}
