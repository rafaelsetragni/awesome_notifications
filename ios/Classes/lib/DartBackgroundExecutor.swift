//
//  DartBackgroundService.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 04/06/21.
//
#if !ACTION_EXTENSION
import UIKit
import Foundation
import Flutter
import IosAwnCore

public class DartBackgroundExecutor: BackgroundExecutor {
    private let TAG = "DartBackgroundExecutor"
    
    public let silentDataQueue:SynchronizedArray = SynchronizedArray<SilentActionRequest>()
        
    private var backgroundEngine: FlutterEngine?
    private var backgroundChannel: FlutterMethodChannel?
    
    static var registrar: FlutterPluginRegistrar?
    
    private var _isRunning = false
    public var isRunning:Bool {
        get { return _isRunning }
    }
    public var isNotRunning: Bool {
        get { return !_isRunning }
    }
    
    private var actionReceived:ActionReceived?
    
    // ************** Awesome Extensions ***********************00
    
    public required init(){}
    
    public static func extendCapabilities(usingFlutterRegistrar registrar:FlutterPluginRegistrar){
        self.registrar = registrar
        AwesomeNotifications.backgroundClassType = DartBackgroundExecutor.self
    }
    
    // ************** IOS EVENTS LISTENERS ************************
        
    var dartCallbackHandle:Int64 = 0
    var silentCallbackHandle:Int64 = 0
    
    public func runBackgroundProcess(
        silentActionRequest:SilentActionRequest,
        dartCallbackHandle:Int64,
        silentCallbackHandle:Int64
    ){
        addSilentActionRequest(silentActionRequest)
       
        if(!self._isRunning){
            self._isRunning = true
            
            self.silentCallbackHandle = silentCallbackHandle
            self.dartCallbackHandle = dartCallbackHandle
            
            runBackgroundThread(
                silentCallbackHandle: silentCallbackHandle,
                dartCallbackHandle: dartCallbackHandle)
        }
    }
    
    public func addSilentActionRequest(_ silentActionRequest:SilentActionRequest){
        silentDataQueue.append(silentActionRequest)
    }
    
    public func onMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        
        switch(call.method){
            
        case Definitions.CHANNEL_METHOD_PUSH_NEXT:
                dischargeNextSilentExecution()
                result(true)
                break
            
            default:
                result(
                    FlutterError.init(
                        code: TAG,
                        message: "\(call.method) not implemented",
                        details: call.method
                    )
                )
                result(false)
                break
        }
    }
    
    func runBackgroundThread(
        silentCallbackHandle:Int64,
        dartCallbackHandle:Int64
    ) {
        
        guard let dartCallbackInfo = FlutterCallbackCache.lookupCallbackInformation(dartCallbackHandle) else {
            Logger.e(TAG, "There is no valid callback info to handle dart channels.")
            closeBackgroundIsolate()
            return
        }
        
        guard FlutterCallbackCache.lookupCallbackInformation(silentCallbackHandle) != nil else {
            Logger.e(TAG, "There is no valid callback info to handle silent data.")
            closeBackgroundIsolate()
            return
        }
        
        if(self.backgroundEngine != nil){
            Logger.d(TAG, "Background isolate already started.")
            closeBackgroundIsolate()
            return
        }
        
        // Flutter engine still doesn't support running in background thread
        if Thread.isMainThread {
            createNewFlutterEngine(dartCallbackInfo: dartCallbackInfo)
        }
        else {
            DispatchQueue.main.async(execute: {
                self.createNewFlutterEngine(dartCallbackInfo: dartCallbackInfo)
            })
        }
    }
    
    func createNewFlutterEngine(
        dartCallbackInfo:FlutterCallbackInformation
    ){
        do {
            
            self.backgroundEngine = FlutterEngine(
                name: "AwesomeNotificationsBgEngine",
                project: nil,
                allowHeadlessExecution: true
            )
            
            if self.backgroundEngine == nil {
                Logger.e(self.TAG, "Flutter background engine is not available.")
                self.closeBackgroundIsolate()
            }
            else {
                self.backgroundEngine!.run(
                    withEntrypoint: dartCallbackInfo.callbackName,
                    libraryURI: dartCallbackInfo.callbackLibraryPath)
                
                SwiftAwesomeNotificationsPlugin
                    .flutterRegistrantCallback?(self.backgroundEngine!)
                
                DartAwesomeNotificationsExtension.setRegistrar(flutterEngine: backgroundEngine)
                DartAwesomeNotificationsExtension.initialize()
                try AwesomeNotifications.loadExtensions()
                
                self.initializeReverseMethodChannel(
                    backgroundEngine: self.backgroundEngine!)
            }
            
        } catch {
            Logger.e(TAG, error.localizedDescription)
        }
    }
    
    func initializeReverseMethodChannel(backgroundEngine: FlutterEngine){
        
        self.backgroundChannel = FlutterMethodChannel(
            name: Definitions.DART_REVERSE_CHANNEL,
            binaryMessenger: backgroundEngine.binaryMessenger
        )
        
        self.backgroundChannel!.setMethodCallHandler(onMethodCall)
    }
    
    func closeBackgroundIsolate() {
        _isRunning = false
        
        self.backgroundEngine?.destroyContext()
        self.backgroundEngine = nil
        
        self.backgroundChannel = nil
        Logger.i(TAG, "FlutterEngine instance terminated.")
    }
    
    func dischargeNextSilentExecution(){
        if let silentDataRequest:SilentActionRequest = silentDataQueue.first {
            silentDataQueue.remove(at: 0)
            self.executeDartCallbackInBackgroundIsolate(silentDataRequest)
        }
    }

    func finishDartBackgroundExecution(){
        if (silentDataQueue.count == 0) {
            Logger.i(TAG, "All silent actions fetched.")
            self.closeBackgroundIsolate()
        }
        else {
            Logger.i(TAG, "Remaining " + String(silentDataQueue.count) + " silents to finish")
            self.dischargeNextSilentExecution()
        }
    }
    
    func executeDartCallbackInBackgroundIsolate(_ silentDataRequest:SilentActionRequest){
        
        if self.backgroundEngine == nil {
            Logger.i(TAG, "A background message could not be handle since" +
                    "dart callback handler has not been registered")
        }
        
        var silentData:[String : Any?] = silentDataRequest.actionReceived.toMap()
        silentData[Definitions.ACTION_HANDLE] = self.silentCallbackHandle
        
        backgroundChannel?.invokeMethod(
            Definitions.CHANNEL_METHOD_SILENT_CALLBACK,
            arguments: silentData,
            result: { flutterResult in
                silentDataRequest.handler(true)
                self.finishDartBackgroundExecution()
            }
        )
    }
}
#endif
