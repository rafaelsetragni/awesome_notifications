//
//  ListUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

class ListUtils {

    public static func isNullOrEmpty(_ list: [AnyObject]?) -> Bool {
        return list?.isEmpty ?? true
    }
}
