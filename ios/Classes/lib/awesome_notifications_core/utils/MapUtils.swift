//
//  MapUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class MapUtils<T: Any> {
    
    public static func isNullOrEmptyKey(map: [String : Any?], key: String) -> Bool {

        if(map.isEmpty) { return true }

        let value:Any? = map[key] ?? nil

        if(value == nil) { return true }

        if (value is String){
            if((value as! String).isEmpty) { return true }
        }
        else if (value is [String : Any?]){
            if((value as! [String : Any?]).isEmpty) { return true }
        }

        return false
    }

    public static func getValueOrDefault(reference: String, arguments: [String : Any?]?) -> T? {
        let value:Any? = arguments?[reference] ?? nil
        let defaultValue:T? = Definitions.initialValues[reference] as? T
        
        if(value == nil) { return defaultValue }
        
        if(T.self == Int.self){
            return IntUtils.convertToInt(value: value) as? T
        }
        
        if(T.self == Float.self){
            return FloatUtils.convertToFloat(value: value) as? T
        }

        if(T.self == Double.self){
            return DoubleUtils.convertToDouble(value: value) as? T
        }
        
        if(value is T) { return value as? T }
        
        if (value as AnyObject).isEmpty ?? false {
            return defaultValue
        }
        
        return defaultValue
    }
}
