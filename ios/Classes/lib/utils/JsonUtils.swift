//
//  JsonUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class JsonUtils {
       
    public static func toJson(_ data:[String:Any?]? ) -> String? {
        
        if data == nil { return nil }
        
        do {
            let jsonData = try! JSONSerialization.data(withJSONObject: data!, options: [])
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            
            if StringUtils.isNullOrEmpty(jsonString) { return nil }
            return jsonString
        }
        catch {
            Log.d("JsonUtils", error.localizedDescription)
        }
        
        return nil
    }
    
    public static func fromJson(_ text:String? ) -> [String:Any?]? {
                
        if StringUtils.isNullOrEmpty(text) { return nil }
        
        do {
            if let data = text!.data(using: String.Encoding.utf8) {
                let decodedData:[String:Any?]? = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                return decodedData
            }
        }
        catch {
            Log.d("JsonUtils", error.localizedDescription)
        }
        
        return nil
        
    }
    
}
