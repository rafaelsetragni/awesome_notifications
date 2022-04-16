//
//  BackgroundService.swift
//  awesome_notifications
//
//  Created by CardaDev on 02/02/22.
//

import Foundation

class BackgroundService {
    
    static let TAG = "BackgroundService"
    
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
        Logger.d(BackgroundService.TAG, "A new Dart background service has started")
        
        let backgroundCallback:Int64 = DefaultsManager.shared.backgroundCallback
        let actionCallback:Int64 = DefaultsManager.shared.actionCallback
        
        if backgroundCallback == 0 {
            Logger.d(BackgroundService.TAG,
                  "A background message could not be handled in Dart because there is no valid background handler register")
            completionHandler(false)
            return
        }
        
        if actionCallback == 0 {
            Logger.d(BackgroundService.TAG,
                  "A background message could not be handled in Dart because there is no valid action callback handler register")
            completionHandler(false)
            return
        }
        
        if Thread.isMainThread {
            mainThreadServiceExecution(
                SilentBackgroundAction: silentAction,
                backgroundCallback: backgroundCallback,
                actionCallback: actionCallback,
                withCompletionHandler: completionHandler)
        }
        else {
            backgroundThreadServiceExecution(
                SilentBackgroundAction: silentAction,
                backgroundCallback: backgroundCallback,
                actionCallback: actionCallback,
                withCompletionHandler: completionHandler)
        }
    }
    
    func mainThreadServiceExecution(
        SilentBackgroundAction silentAction: ActionReceived,
        backgroundCallback:Int64,
        actionCallback:Int64,
        withCompletionHandler completionHandler: @escaping (Bool) -> ()
    ){
        let start = DispatchTime.now()
        let silentActionRequest:SilentActionRequest =
                SilentActionRequest(
                    actionReceived: silentAction,
                    handler: { success in
                        
                        let end = DispatchTime.now()
                        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                        let timeInterval:Double = Double(nanoTime) / 1_000_000
                        Logger.d(BackgroundService.TAG, "Background action finished in \(timeInterval.rounded())ms")
                        
                        completionHandler(success)
                    })
        
        DartBackgroundExecutor
            .shared
            .runBackgroundProcess(
                silentActionRequest: silentActionRequest,
                dartCallbackHandle: backgroundCallback,
                silentCallbackHandle: actionCallback)
        
    }
    
    func backgroundThreadServiceExecution(
        SilentBackgroundAction silentAction: ActionReceived,
        backgroundCallback:Int64,
        actionCallback:Int64,
        withCompletionHandler completionHandler: @escaping (Bool) -> ()
    ){
        let start = DispatchTime.now()
        let group = DispatchGroup()
        
        group.enter()
        let silentActionRequest:SilentActionRequest =
                SilentActionRequest(
                    actionReceived: silentAction,
                    handler: { success in
                        group.leave()
                    })
        
        let workItem:DispatchWorkItem = DispatchWorkItem {
            DispatchQueue.global(qos: .background).async {
                DartBackgroundExecutor
                    .shared
                    .runBackgroundProcess(
                        silentActionRequest: silentActionRequest,
                        dartCallbackHandle: backgroundCallback,
                        silentCallbackHandle: actionCallback)
            }
            
        }
        workItem.perform()
        
        if group.wait(timeout: DispatchTime.now() + .seconds(10)) == .timedOut {
            Logger.e(BackgroundService.TAG, "Background action service reached timeout limit")
            workItem.cancel()
            completionHandler(false)
        }
        else {
            completionHandler(true)
        }
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval:Double = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
        Logger.d(BackgroundService.TAG, "Background action finished in \(timeInterval.rounded())ms")
    }
    
}
