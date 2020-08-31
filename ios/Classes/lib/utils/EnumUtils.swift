//
//  EnumUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 31/08/20.
//

import Foundation


class EnumUtils<T: CaseIterable> {

    static func fromString(_ value: String?) -> T {
        return T.allCases.first{ "\($0)" == (value ?? "") } ?? T.allCases.first!
    }
    
    public static func getEnumOrDefault(reference: String, arguments: [String : Any?]?) -> T {
        let value:Any? = arguments?[reference] ?? nil
        let defaultValue:T = fromString(Definitions.initialValues[reference] as? String)

        if(value == nil) { return defaultValue }
        return value as! T
    }
}
