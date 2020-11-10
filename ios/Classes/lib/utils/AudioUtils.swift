//
//  AudioUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

@available(iOS 10.0, *)
public class AudioUtils : MediaUtils {
        
        public static func getSoundFromSource(SoundPath:String?) -> UNNotificationSound? {
            
            if(StringUtils.isNullOrEmpty(SoundPath)){ return nil }
            
            switch(MediaUtils.getMediaSourceType(mediaPath: SoundPath)){
                    
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
        
        private static func getSoundFromUrl(_ SoundUri:String) -> UNNotificationSound? {
            let SoundUri:String? = MediaUtils.cleanMediaPath(mediaPath: SoundUri)
            
            if !StringUtils.isNullOrEmpty(SoundUri) {

                //do {
                    return UNNotificationSound.default
                    
                //} catch let error {
                //    print("error \(error)")
                //}
            }

            return nil
        }
        
        private static func getSoundFromFile(_ mediaPath:String) -> UNNotificationSound? {
            let mediaPath:String? = AudioUtils.cleanMediaPath(mediaPath)
            
            if(StringUtils.isNullOrEmpty(mediaPath)){ return nil }
            
            //do {
                
                if FileManager.default.fileExists(atPath: mediaPath!) {
                    return UNNotificationSound(named: UNNotificationSoundName(rawValue: mediaPath!))
                }
                
                return UNNotificationSound.default
             /*
            } catch let error {
                print("error \(error)")
                return nil
            }*/
        }
        
        private static func getSoundFromAsset(_ mediaPath:String) -> UNNotificationSound? {
            let mediaPath:String? = AudioUtils.cleanMediaPath(mediaPath)

            if(StringUtils.isNullOrEmpty(mediaPath)){ return nil }
            
            //do {
                
                let key = SwiftAwesomeNotificationsPlugin.registrar?.lookupKey(forAsset: mediaPath!)
                let topPath = Bundle.main.path(forResource: key, ofType: nil)!
                
                return getSoundFromFile(topPath)
               /*
            } catch let error {
                print("error \(error)")
                return nil
            }*/
        }
        
        private static func getSoundFromResource(_ mediaPath:String) -> UNNotificationSound? {
            var mediaPath:String? = AudioUtils.cleanMediaPath(mediaPath)
            
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
                print("error \(error)")
                return nil
            }*/
        }
        
        public static func isValidSound(_ mediaPath:String?) -> Bool {
            
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
         public static func isValidSound(_ mediaPath:String? ) -> Bool {
             
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
