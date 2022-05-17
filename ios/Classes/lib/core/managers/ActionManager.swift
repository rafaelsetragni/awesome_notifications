//
//  ActionManager.swift
//  awesome_notifications
//
//  Created by CardaDev on 31/01/22.
//

import Foundation

public class ActionManager {
    static let TAG = "ActionManager"
    static var recovered:Bool  = false
    
    // Cache is necessary due user preferences are not aways ready for return data
    // if the respective value is request too fast.
    static var actionCache:[Int:ActionReceived] = [:]
    
    public static func removeAction(id:Int) -> Bool {
        return actionCache.removeValue(forKey: id) != nil
    }

    public static func recoverActions() -> [ActionReceived] {
        Logger.i(TAG, "action recovered")
        recovered = true
        return Array(actionCache.values)
    }

    public static func saveAction(received:ActionReceived) {
        actionCache[received.id!] = received
    }

    public static func getActionByKey(id:Int) -> ActionReceived? {
        return actionCache[id]
    }

    public static func removeAllActions() {
        actionCache.removeAll()
    }

    public static func removeAction(id:Int) {
        actionCache.removeValue(forKey: id)
    }
    
}
