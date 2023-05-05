//
//  FlutterAudioUtils.swift
//  awesome_notifications
//
//  Created by CardaDev on 03/02/22.
//

import Flutter
import Foundation
import IosAwnCore

@available(iOS 10.0, *)
public class FlutterAudioUtils : AudioUtils {
        
    let registrar:FlutterPluginRegistrar?
    
    public init(registrar:FlutterPluginRegistrar?) {
        self.registrar = registrar
        super.init()
    }
    
    public static func extendCapabilities(usingFlutterRegistrar registrar:FlutterPluginRegistrar?){
        AudioUtils.instance = FlutterAudioUtils(registrar:registrar)
    }
    
    open override func getSoundFromAsset(_ mediaPath:String) -> UNNotificationSound? {
        
        let mediaPath:String? = cleanMediaPath(mediaPath)

        if(StringUtils.shared.isNullOrEmpty(mediaPath)){ return nil }
                
        var topPath:String?
        if registrar != nil {
            let key = registrar!.lookupKey(forAsset: mediaPath!)
            topPath = Bundle.main.path(forResource: key, ofType: nil)
        }
        
        if SwiftUtils.isRunningOnExtension() && topPath?.isEmpty ?? true {
            topPath = SwiftUtils.getFlutterAssetPath(forAsset: mediaPath!)
        }
        
        return topPath == nil ? nil : getSoundFromFile(fromRealPath: topPath!)
    }
}
