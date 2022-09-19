//
//  AudioUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

@available(iOS 10.0, *)
open class AudioUtils: MediaUtils {
    
    let TAG = "AudioUtils"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static var instance:AudioUtils?
    public static var shared:AudioUtils {
        get {
            AudioUtils.instance = AudioUtils.instance ?? AudioUtils()
            return AudioUtils.instance!
        }
    }
    public override init(){}
    
    // ********************************************************
        
    public func getSoundFromSource(SoundPath:String?) -> UNNotificationSound? {
        
        if(StringUtils.shared.isNullOrEmpty(SoundPath)){ return nil }
        
        switch(getMediaSourceType(mediaPath: SoundPath)){
                
            case .Resource:
                return getSoundFromResource(SoundPath ?? "")
                
            case .Asset:
                return getSoundFromAsset(SoundPath ?? "")
                
            case .File:
                return getSoundFromFile(SoundPath ?? "")
                
            case .Network:
                return getSoundFromUrl(SoundPath ?? "")
                
            case .Unknown:
                return nil
        }
    }
    
    open func cleanMediaPath(_ mediaPath:String?) -> String? {
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
    
    open func getSoundFromUrl(_ SoundUri:String) -> UNNotificationSound? {
        let SoundUri:String? = cleanMediaPath(mediaPath: SoundUri)
        
        if !StringUtils.shared.isNullOrEmpty(SoundUri) {

            //do {
                return UNNotificationSound.default
                
            //} catch let error {
            //    Logger.e("AudioUtils", error)
            //}
        }

        return nil
    }
    
    open func getSoundFromFile(_ mediaPath:String) -> UNNotificationSound? {
        let mediaPath:String? = cleanMediaPath(mediaPath)
        
        if(StringUtils.shared.isNullOrEmpty(mediaPath)){ return nil }
        
        return getSoundFromFile(fromRealPath: mediaPath!)
    }
    
    open func getSoundFromFile(fromRealPath mediaPath:String) -> UNNotificationSound? {
        if FileManager.default.fileExists(atPath: mediaPath) {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: mediaPath))
        }
        
        return UNNotificationSound.default
    }
    
    open func getSoundFromAsset(_ mediaPath:String) -> UNNotificationSound? {
        return nil
    }
    
    open func getSoundFromResource(_ mediaPath:String) -> UNNotificationSound? {
        var mediaPath:String? = cleanMediaPath(mediaPath)
        
        //do {
            if mediaPath!.replaceRegex("^.*\\/([^\\/]+)$", replaceWith: "$1") {
                var topPath:String? = Bundle.main.url(forResource: mediaPath!, withExtension: "aiff")?.absoluteString
                
                if ((topPath?.replaceRegex("^.*\\/([^\\/]+)$", replaceWith: "$1")) != nil){
                    return UNNotificationSound(named: UNNotificationSoundName(rawValue: topPath!))
                }
                return UNNotificationSound.default
            }
            return nil
          /*
        } catch let error {
            Logger.e("AudioUtils", error)
            return nil
        }*/
    }
    
    public func isValidSound(_ mediaPath:String?) -> Bool {
        
        if(mediaPath != nil){
            

            if (matchMediaType(regex: Definitions.MEDIA_VALID_NETWORK, mediaPath: mediaPath, filterEmpty: false)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }

            if (matchMediaType(regex: Definitions.MEDIA_VALID_FILE, mediaPath: mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }

            if (matchMediaType(regex: Definitions.MEDIA_VALID_RESOURCE, mediaPath: mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }

            if (matchMediaType(regex: Definitions.MEDIA_VALID_ASSET, mediaPath: mediaPath)) {
                // TODO MISSING IMPLEMENTATION
                return true
            }
            
        }
        
        return false
    }
    
    /*
     public func isValidSound(_ mediaPath:String? ) -> Bool {
         
         if(!StringUtils.shared.isNullOrEmpty(mediaPath)){
             
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
