//
//  BooleanUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 28/08/20.
//

import Foundation

class BooleanUtils {
    
    public static func getValue(value: Any?, defaultValue: Bool?) -> Bool {
        return value as! Bool? ?? defaultValue ?? false
    }
    
}
