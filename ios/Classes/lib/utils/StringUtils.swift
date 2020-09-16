//
//  StringUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class StringUtils {

    public static func isNullOrEmpty(_ value:String?) -> Bool {
        return value?.isEmpty ?? true
    }
}
