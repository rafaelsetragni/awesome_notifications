//
//  BitmapUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class BitmapUtils : MediaUtils {
    /*
    public static func getBitmapFromSource(bitmapPath:String) -> Any? {
        return nil
    }
    
    @available(iOS 10.0, *)
    public static func getBitmapFromSource(bitmapPath:String?) -> UNNotificationAttachment? {
        
        if(StringUtils.isNullOrEmpty(bitmapPath)){ return nil }
        
        switch(MediaUtils.getMediaSourceType(mediaPath: bitmapPath)){
                
            case .Resource:
                return getBitmapFromAsset(bitmapPath ?? "")
                
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
    
    @available(iOS 10.0, *)
    public static func getBitmapFromUrl(_ mediaPath:String) -> UNNotificationAttachment? {
        
        guard let imageData = NSData(contentsOf:NSURL(string: mediaPath)! as URL) else { return nil }
        guard let attachment = UNNotificationAttachment.create(imageFileIdentifier: "image.gif", data: imageData, options: nil) else {
            return nil
        }
        
        return attachment
    }
    
    @available(iOS 10.0, *)
    public static func getBitmapFromFile(_ mediaPath:String) -> UNNotificationAttachment? {
        
        // TODO missing implementation
        return nil
    }
    
    @available(iOS 10.0, *)
    public static func getBitmapFromAsset(_ mediaPath:String) -> UNNotificationAttachment? {
        
        // TODO missing implementation
        return nil
    }
    
    @available(iOS 10.0, *)
    public static func getBitmapFromResource(_ mediaPath:String) -> UNNotificationAttachment? {
        
        // TODO missing implementation
        return nil
    }
    
    */
    public static func isValidBitmap(_ mediaPath:String?) -> Bool {
        /*
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
            
        }*/
        
        return false
    }
}
