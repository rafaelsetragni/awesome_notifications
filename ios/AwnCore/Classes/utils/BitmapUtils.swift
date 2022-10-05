//
//  BitmapUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//
import Foundation

open class BitmapUtils : MediaUtils {
    
    let TAG = "BitmapUtils"
    
    // ************** SINGLETON PATTERN ***********************
    
    public static var instance:BitmapUtils?
    public static var shared:BitmapUtils {
        get {
            BitmapUtils.instance = BitmapUtils.instance ?? BitmapUtils()
            return BitmapUtils.instance!
        }
    }
    public override init(){}
    
    // ********************************************************
    
    public func getBitmapFromSource(bitmapPath:String?, roundedBitpmap:Bool) -> UIImage? {
        
        if(StringUtils.shared.isNullOrEmpty(bitmapPath)){ return nil }
        
        var resultedImage:UIImage? = nil
        switch(getMediaSourceType(mediaPath: bitmapPath)){
                
            case .Resource:
            resultedImage = getBitmapFromResource(bitmapPath ?? "")
                
            case .Asset:
            resultedImage = getBitmapFromAsset(bitmapPath ?? "")
                
            case .File:
            resultedImage = getBitmapFromFile(bitmapPath ?? "")
                
            case .Network:
            resultedImage = getBitmapFromUrl(bitmapPath ?? "")
                
            case .Unknown:
            resultedImage = nil
        }
        
        if(resultedImage != nil && roundedBitpmap){
            resultedImage = roundUiImage(resultedImage!)
        }
        
        return resultedImage
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
    
    open func getBitmapFromUrl(_ bitmapUri:String) -> UIImage? {
        let bitmapUri:String? = BitmapUtils.shared.cleanMediaPath(bitmapUri)
        
        if !StringUtils.shared.isNullOrEmpty(bitmapUri), let url = URL(string: bitmapUri!) {

            do {
                
                let imageData = try Data(contentsOf: url)
                
                // This is necessary to protect the target executions
                // from EXC_RESOURCE_RESOURCE_TYPE_MEMORY fatal exception
                
                if SwiftUtils.isRunningOnExtension() && imageData.count > 1048576 {
                    throw ExceptionFactory
                        .shared
                        .createNewAwesomeException(
                            className: TAG,
                            code: ExceptionCode.CODE_INVALID_IMAGE,
                            message: "Notification image '\( String(describing: bitmapUri))' exceeds 1Mb",
                            detailedCode: ExceptionCode.DETAILED_INVALID_ARGUMENTS+".image.sizeLimit")
                }
                
                return UIImage(data: imageData)
                
            } catch let error {
                Logger.e("BitmapUtils", error.localizedDescription)
            }
        }
        
        return nil
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.9)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let newImage = newImage{
            return newImage
        }else{
            return nil
        }
    }
    
    func getBitmapFromFile(_ mediaPath:String) -> UIImage? {
        let mediaPath:String? = cleanMediaPath(mediaPath)
        
        if(StringUtils.shared.isNullOrEmpty(mediaPath)){ return nil }
        
        return getBitmapFromFile(fromRealPath: mediaPath!)
    }
    
    open func getBitmapFromFile(fromRealPath realPath:String) -> UIImage? {
        
        do {
            
            if FileManager.default.fileExists(atPath: realPath) {
                let url = URL.init(fileURLWithPath: realPath)
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            }
            
        } catch let error {
            Logger.e("BitmapUtils", error.localizedDescription)
        }
        
        return nil
    }
    
    open func getBitmapFromAsset(_ mediaPath:String) -> UIImage? {
        return nil
    }
    
    open func getBitmapFromResource(_ mediaPath:String) -> UIImage? {
        var mediaPath:String? = cleanMediaPath(mediaPath)
        
        if mediaPath!.replaceRegex("^.*\\/([^\\/]+)$", replaceWith: "$1") {
            return UIImage(named: mediaPath!)
        }
        return nil
    }
    
    open func roundUiImage(_ image:UIImage) -> UIImage? {
        let rect = CGRect(origin: .zero, size: image.size)
        let format = image.imageRendererFormat
        format.opaque = false
        return UIGraphicsImageRenderer(size: image.size, format: format).image{ _ in
            UIBezierPath(ovalIn: rect).addClip()
            image.draw(in: rect)
        }
    }
    
    open func isValidBitmap(_ mediaPath:String?) -> Bool {
        
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
     func isValidBitmap(_ mediaPath:String? ) -> Bool {
         
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
