//
//  StringUtils.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class StringUtils {
    
    let TAG = "StringUtils"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:StringUtils?
    public static var shared:StringUtils {
        get {
            StringUtils.instance = StringUtils.instance ?? StringUtils()
            return StringUtils.instance!
        }
    }
    init(){}
    
    // ************** SINGLETON PATTERN ***********************

    public func isNullOrEmpty(_ value:String?, considerWhiteSpaceAsEmpty:Bool = true) -> Bool {
        return considerWhiteSpaceAsEmpty ?
            value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true :
            value?.isEmpty ?? true
    }
    
    public func random(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
}
