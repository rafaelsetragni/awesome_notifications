//
//  ActionManager.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class ActionManager {
    
    // Cache is necessary due user preferences are not aways ready for return data
    // if the respective value is request too fast.
    static let shared:SharedManager = SharedManager(tag: Definitions.SHARED_ACTIONS)
    static var actionCache:[Int:ActionReceived] = [:]
    
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

    public static func saveAction(received:ActionReceived) {
        actionCache[received.id!] = received
        shared.set(received.toMap(), referenceKey: String(received.id!))
    }

    public static func getActionByKey(id:Int) -> ActionReceived? {
        if let received:ActionReceived = actionCache[id] {
            return received
        }
        guard let data:[String:Any?] = shared.get(referenceKey: String(id)) else {
          return nil
        }
        return ActionReceived(nil).fromMap(arguments: data) as? ActionReceived
    }

    public static func removeAllActions() {
        actionCache.removeAll()
        shared.removeAll()
    }

    public static func removeAction(id:Int) {
        actionCache.removeValue(forKey: id)
        _ = shared.remove(referenceKey: String(id))
    }
    
}
