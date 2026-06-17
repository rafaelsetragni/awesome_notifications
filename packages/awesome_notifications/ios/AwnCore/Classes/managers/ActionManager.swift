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
    static var initialAction:ActionReceived?
    static var removeInitialActionFromCache:Bool = false
    
    public static func removeAction(id:Int) -> Bool {
        return actionCache.removeValue(forKey: id) != nil
    }

    public static func recoverActions() -> [ActionReceived] {
        if recovered { return [] }
        recovered = true
        return Array(actionCache.values)
    }

    public static func saveAction(received:ActionReceived) {
        if received.actionLifeCycle == .AppKilled {
            initialAction = received
            if removeInitialActionFromCache { return }
        }
        actionCache[received.id!] = received
    }

    public static func getActionByKey(id:Int) -> ActionReceived? {
        return actionCache[id]
    }
    
    public static func removeAllActions() {
        actionCache.removeAll()
    }
    
    public static func getInitialAction(removeFromEvents:Bool) -> ActionReceived? {
        if initialAction == nil { return nil }
        if removeFromEvents {
            removeInitialActionFromCache = true
            _ = removeAction(id: initialAction!.id!)
        }
        return initialAction
    }

    //public static func removeAction(id:Int) {
    //    actionCache.removeValue(forKey: id)
    //}
    
}
