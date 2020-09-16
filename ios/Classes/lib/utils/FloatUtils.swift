//
//  FloatUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class FloatUtils {

    public static func isNullOrEmpty(_ value:Float?) -> Bool {
        return value == nil
    }
    
    // Note: sometimes Json parser converts Integer into Double values
    public static func extractFloat(_ value: Any?, defaultValue: AnyObject) -> Float {
        if(value == nil){
            return convertToFloat(value: defaultValue) ?? 0.0;
        }
        return convertToFloat(value: value) ?? 0.0;
    }

    public static func convertToFloat(value: Any?) -> Float? {
    
        var floatValue:Float? = nil
        
        if(value != nil) {

            if (value is Float) {
                floatValue = value as? Float
            } else
            if (value is Int) {
                floatValue = Float(value as? Int ?? 0)
            } else
            if (value is Double) {
                floatValue = Float(value as? Double ?? 0.0)
            } else
            if (value is String){
                floatValue = Float(value as? String ?? "") ?? 0.0
            }
        }
        return floatValue;
    }
}
