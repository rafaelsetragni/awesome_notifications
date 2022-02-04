//
//  FlutterAudioUtils.swift
//  awesome_notifications
//
//  Created by CardaDev on 03/02/22.
//

import Foundation

@available(iOS 10.0, *)
public class FlutterAudioUtils : AudioUtils {
        
    let registrar:FlutterPluginRegistrar
    
    public override init(registrar:FlutterPluginRegistrar) {
        self.registrar = registrar
    }
    
    func getSoundFromAsset(_ mediaPath:String) -> UNNotificationSound? {
        return nil
        let mediaPath:String? = cleanMediaPath(mediaPath)

        if(StringUtils.isNullOrEmpty(mediaPath)){ return nil }
        
        //do {
            
            let key = registrar.lookupKey(forAsset: mediaPath!)
            let topPath = Bundle.main.path(forResource: key, ofType: nil)!
            
            return getSoundFromFile(topPath)
           /*
        } catch let error {
            print("error \(error)")
            return nil
        }*/
    }
}
