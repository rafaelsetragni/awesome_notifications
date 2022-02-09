//
//  FlutterBitmapUtils.swift
//  awesome_notifications
//
//  Created by CardaDev on 03/02/22.
//

import Foundation

@available(iOS 10.0, *)
public class FlutterBitmapUtils : BitmapUtils {
    
    let registrar:FlutterPluginRegistrar
    
    public init(registrar:FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }
    
    public static func extendCapabilities(usingFlutterRegistrar registrar:FlutterPluginRegistrar){
        BitmapUtils.instance = FlutterBitmapUtils(registrar: registrar)
    }
    
    override func getBitmapFromAsset(_ mediaPath:String) -> UIImage? {
        
        let mediaPath:String? = cleanMediaPath(mediaPath)

        if(StringUtils.isNullOrEmpty(mediaPath)){ return nil }
                    
        let key = registrar.lookupKey(forAsset: mediaPath!)
        let topPath = Bundle.main.path(forResource: key, ofType: nil)!
        
        return getBitmapFromFile(fromRealPath: topPath)
    }
}
