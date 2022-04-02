//
//  BackgroundService.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class BackgroundService {
    
    private let TAG = "BackgroundService"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:BackgroundService?
    public static var shared:BackgroundService {
        get {
            BackgroundService.instance =
                BackgroundService.instance ?? BackgroundService()
            return BackgroundService.instance!
        }
    }
    private init(){}
    
    // ********************************************************
    
    
    public func enqueue(
        SilentBackgroundAction silentAction: ActionReceived,
        withCompletionHandler completionHandler: @escaping (Bool) -> ()
    ){
        Logger.d(TAG, "A new Dart background service has started")
        
        let silentActionRequest:SilentActionRequest =
                SilentActionRequest(
                    actionReceived: silentAction,
                    handler: completionHandler)
        
        let backgroundCallback:Int64 = DefaultsManager.shared.backgroundCallback
        let actionCallback:Int64 = DefaultsManager.shared.actionCallback
        
        if backgroundCallback == 0 {
            Logger.d(TAG,
                  "A background message could not be handled in Dart because there is no valid background handler register")
            completionHandler(false)
            return
        }
        
        if actionCallback == 0 {
            Logger.d(TAG,
                  "A background message could not be handled in Dart because there is no valid action callback handler register")
            completionHandler(false)
            return
        }
        
        DartBackgroundExecutor
            .shared
            .runBackgroundProcess(
                silentActionRequest: silentActionRequest,
                dartCallbackHandle: backgroundCallback,
                silentCallbackHandle: actionCallback)
    }
    
}
