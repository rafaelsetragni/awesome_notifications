//
//  BitmapUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class BitmapUtils : MediaUtils {
    
    public static func getBitmapFromSource(bitmapPath:String?) -> UIImage? {
        
        if(StringUtils.isNullOrEmpty(bitmapPath)){ return nil }
        
        switch(MediaUtils.getMediaSourceType(mediaPath: bitmapPath)){
                
            case .Resource:
                return getBitmapFromResource(bitmapPath ?? "")
                
            case .Asset:
                return getBitmapFromAsset(bitmapPath ?? "")
                
            case .File:
                return getBitmapFromFile(bitmapPath ?? "")
                
            case .Network:
                return getBitmapFromUrl(bitmapPath ?? "")
                
            case .Unknown:
                return nil
        }
    }
    
    private static func cleanMediaPath(_ mediaPath:String?) -> String? {
         if(mediaPath != nil){
             var mediaPath = mediaPath
             
            if(mediaPath!.matches("^https?:\\/\\/")){
                 return mediaPath
             }
             else
             if(mediaPath!.matches("^(asset:\\/\\/)(.*)")){
                 if mediaPath!.replaceRegex("^(asset:\\/\\/)(.*)", replaceWith: "$2") {
                     return mediaPath
                 }
             }
             else
             if(mediaPath!.matches("^(file:\\/\\/)(.*)")){
                 if mediaPath!.replaceRegex("^(file:\\/\\/)(.*)", replaceWith: "$2") {
                     return mediaPath
                 }
             }
             else
             if(mediaPath!.matches("^(resource:\\/\\/)(.*)")){
                 if mediaPath!.replaceRegex("^(resource:\\/\\/)(.*)", replaceWith: "$2") {
                     return mediaPath
                 }
             }
             
         }
         return nil
    }
    
    public static func getBitmapFromUrl(_ bitmapUri:String) -> UIImage? {
        let bitmapUri:String? = BitmapUtils.cleanMediaPath(bitmapUri)
        
        if !StringUtils.isNullOrEmpty(bitmapUri), let url = URL(string: bitmapUri!) {

            do {
                
                let imageData = try Data(contentsOf: url)
                return UIImage(data: imageData)
                
            } catch let error {
                print("error \(error)")
            }
        }

        return nil
    }
    
    public static func getBitmapFromFile(_ mediaPath:String) -> UIImage? {
        let mediaPath:String? = BitmapUtils.cleanMediaPath(mediaPath)
        
        if(StringUtils.isNullOrEmpty(mediaPath)){ return nil }
        
        do {
            
            if FileManager.default.fileExists(atPath: mediaPath!) {
                let url = URL.init(fileURLWithPath: mediaPath!) 
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            }
            
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
    
    public static func getBitmapFromAsset(_ mediaPath:String) -> UIImage? {
        let mediaPath:String? = BitmapUtils.cleanMediaPath(mediaPath)

        if(StringUtils.isNullOrEmpty(mediaPath)){ return nil }
        
        do {
            
            let key = SwiftAwesomeNotificationsPlugin.registrar?.lookupKey(forAsset: mediaPath!)
            let topPath = Bundle.main.path(forResource: key, ofType: nil)!
            let image: UIImage = UIImage(contentsOfFile: topPath)!
            
            return image
            
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
    
    public static func getBitmapFromResource(_ mediaPath:String) -> UIImage? {
        var mediaPath:String? = BitmapUtils.cleanMediaPath(mediaPath)
        
        do {
            if mediaPath!.replaceRegex("^.*\\/([^\\/]+)$", replaceWith: "$1") {
                return UIImage(named: mediaPath!)
            }
        } catch let error {
            print("error \(error)")
        }


        return nil
    }
    
    public static func isValidBitmap(_ mediaPath:String?) -> Bool {
        
        if(mediaPath != nil){
            

            if (MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_NETWORK, mediaPath: mediaPath, filterEmpty: false)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }

            if (MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_FILE, mediaPath: mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }

            if (MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_RESOURCE, mediaPath: mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }

            if (MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_ASSET, mediaPath: mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }
            
        }
        
        return false
    }
    
    /*
     public static func isValidBitmap(_ mediaPath:String? ) -> Bool {
         
         if(!StringUtils.isNullOrEmpty(mediaPath)){
             
             if(MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_NETWORK, mediaPath: mediaPath)){
                 return true
             }
             
             if(MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_FILE, mediaPath: mediaPath)){
                 return true
             }
             
             if(MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_ASSET, mediaPath: mediaPath)){
                 return true
             }
             
             if(MediaUtils.matchMediaType(regex: Definitions.MEDIA_VALID_RESOURCE, mediaPath: mediaPath)){
                 return true
             }
             
         }
         
         return false
     }
    */
}
