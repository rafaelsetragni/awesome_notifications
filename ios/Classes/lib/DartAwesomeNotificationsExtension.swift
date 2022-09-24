//
//  DartAwesomeNotificationsExtension.swift
//  awesome_notifications
//
//  Created by CardaDev on 29/08/22.
//

import Flutter
import Foundation
import IosAwnCore

public class DartAwesomeNotificationsExtension: AwesomeNotificationsExtension {
    
    public static var registrar:FlutterPluginRegistrar?
    
    public static func setRegistrar(flutterEngine:FlutterEngine? = nil){
        if registrar == nil {
//            var finalFlutterEngine = flutterEngine
//            if (finalFlutterEngine == nil){
//                finalFlutterEngine = FlutterEngine(name: "dartAwesomeServiceExtension", project: nil)
//                finalFlutterEngine!.run(withEntrypoint: nil)
//            }
//
//            registrar = finalFlutterEngine?.registrar(forPlugin: "AwesomeNotificationsFcm");
        }
    }
    
    public static func initialize() {
        if AwesomeNotifications.awesomeExtensions != nil {
            return
        }
        AwesomeNotifications.awesomeExtensions = DartAwesomeNotificationsExtension()
    }
    
    var initialized:Bool = false
    public func loadExternalExtensions() {
        if initialized {
            return
        }
        
        AwesomeNotifications.initialize()
        
        if DartAwesomeNotificationsExtension.registrar != nil {
            FlutterAudioUtils.extendCapabilities(
                usingFlutterRegistrar: DartAwesomeNotificationsExtension.registrar!)
            
            FlutterBitmapUtils.extendCapabilities(
                usingFlutterRegistrar: DartAwesomeNotificationsExtension.registrar!)
            
            DartBackgroundExecutor.extendCapabilities(
                usingFlutterRegistrar: DartAwesomeNotificationsExtension.registrar!)
        }
        
        initialized = true
    }
}
