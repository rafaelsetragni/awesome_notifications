//
//  BadgeManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 17/11/21.
//

import Foundation

public class BadgeManager {
    
    private static var badgeAmount:NSNumber = 0

    public static func getGlobalBadgeCounter() -> Int {
        if !SwiftUtils.isRunningOnExtension() && Thread.isMainThread {
            BadgeManager.badgeAmount = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber)
        }
        else{
            let userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
            let badgeCount:Int = userDefaults!.integer(forKey: Definitions.BADGE_COUNT)
            BadgeManager.badgeAmount = NSNumber(value: badgeCount)
        }
        return BadgeManager.badgeAmount.intValue
    }

    public static func setGlobalBadgeCounter(_ count:Int) {
        BadgeManager.badgeAmount = NSNumber(value: count)
        
        if !SwiftUtils.isRunningOnExtension() && Thread.isMainThread {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
        else{
            BadgeManager.badgeAmount = NSNumber(value: count)
        }
        
        let userDefaults = UserDefaults(suiteName: Definitions.USER_DEFAULT_TAG)
        userDefaults!.set(count, forKey: Definitions.BADGE_COUNT)
    }

    public static func resetGlobalBadgeCounter() {
        setGlobalBadgeCounter(0)
    }

    public static func incrementGlobalBadgeCounter() -> Int {
        let count:Int = BadgeManager.getGlobalBadgeCounter() + 1
        BadgeManager.setGlobalBadgeCounter(count)
        return count
    }

    public static func decrementGlobalBadgeCounter() -> Int {
        let count:Int = max(BadgeManager.getGlobalBadgeCounter() - 1, 0)
        BadgeManager.setGlobalBadgeCounter(count)
        return count
    }

}
