//
//  DoubleUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class DoubleUtils {

    public static func isNullOrEmpty(_ value:Double?) -> Bool {
        return value == nil
    }
    
    // Note: sometimes Json parser converts Integer into Double values
    public static func extractDouble(_ value: Any?, defaultValue: AnyObject) -> Double {
        if(value == nil){
            return convertToDouble(value: defaultValue) ?? 0.0;
        }
        return convertToDouble(value: value) ?? 0.0;
    }

    public static func convertToDouble(value: Any?) -> Double? {
    
        var DoubleValue:Double? = nil
        
        if(value != nil) {

            if (value is Double) {
                DoubleValue = value as? Double
            } else
            if (value is Int) {
                DoubleValue = Double(value as? Int ?? 0)
            } else
            if (value is Float) {
                DoubleValue = Double(value as? Float ?? 0.0)
            } else
            if (value is String){
                DoubleValue = Double(value as? String ?? "") ?? 0.0
            }
        }
        return DoubleValue;
    }
}

