//
//  UNTriggerExtension.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 21/10/20.
//

import Foundation
/*
@available(iOS 10.0, *)
open class UNCrontabNotificationTrigger : UNCalendarNotificationTrigger {
    
    private var fireDate:Date?
    private var crontabRule:String?
    private var fireList:[Date]?
    
    public init?(fireDate:Date?, crontabRule: String){
        super.init(coder: NSCoder)
        
        self.fireDate = fireDate
        self.crontabRule = crontabRule
    }
    
    public convenience init(fireList:[Date]){
        self.fireList = fireList
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func nextTriggerDate() -> Date? {
        
        var nextValidDate:Date? = Date()
        let cron:CronUtils = CronUtils()
        
        do {

            nextValidDate = cron.getNextCalendar(
                initialDateTime: fireDate?.toString(),
                crontabRule: crontabRule
            )

            if(nextValidDate != nil){
                return nextValidDate
            }
            else {

                if !(fireList?.isEmpty ?? true) {

                    for nextFireDate in fireList! {

                        let closestDate:Date? = cron.getNextCalendar(
                            initialDateTime: nextFireDate.toString(),
                            crontabRule: nil
                        )

                        // The list is probaly disordered
                        if closestDate != nil {
                            if nextValidDate == nil {
                                nextValidDate = closestDate
                            }
                            else {
                                if closestDate!.compare(nextValidDate!) == ComparisonResult.orderedAscending {
                                    nextValidDate = closestDate
                                }
                            }
                        }
                    }

                    if nextValidDate != nil {
                        return nextValidDate
                    }
                }
            }
        }
        return nil
    }
    
}*/
