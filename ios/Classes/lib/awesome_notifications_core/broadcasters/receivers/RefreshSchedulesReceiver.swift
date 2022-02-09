//
//  RefreshSchedulesReceiver.swift
//  awesome_notifications
//
//  Created by CardaDev on 03/02/22.
//

import Foundation

class RefreshSchedulesReceiver {
    
    static let TAG = "RefreshSchedulesReceiver"
    
    public func refreshSchedules(){
        let referenceDate = Date()
        
        let lostSchedules = ScheduleManager.listPendingSchedules(referenceDate: referenceDate)
        for notificationModel in lostSchedules {
            
            do {
                let hasNextValidDate:Bool = (notificationModel.schedule?.hasNextValidDate() ?? false)
                if  notificationModel.schedule?.createdDate == nil || !hasNextValidDate {
                    throw AwesomeNotificationsException.notificationExpired
                }
                
                try NotificationSenderAndScheduler.send(
                        createdSource: notificationModel.content!.createdSource!,
                        notificationModel: notificationModel,
                        completion: { sent, content, error in
                        },
                        appLifeCycle: LifeCycleManager
                                        .shared
                                        .currentLifeCycle)
                
            } catch {
                let _ = ScheduleManager.removeSchedule(id: notificationModel.content!.id!)
            }
        }
        
        clearDeactivatedSchedules();
    }
    
    public func clearDeactivatedSchedules(){
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { activeSchedules in
            
            if activeSchedules.count > 0 {
                let schedules = ScheduleManager.listSchedules()
                
                if(!ListUtils.isNullOrEmpty(schedules)){
                    for notificationModel in schedules {
                        var founded = false
                        for activeSchedule in activeSchedules {
                            if activeSchedule.identifier != String(notificationModel.content!.id!) {
                                founded = true
                                break;
                            }
                        }
                        if(!founded){
                            _ = ScheduleManager.cancelScheduled(id: notificationModel.content!.id!)
                        }
                    }
                }
            } else {
                _ = ScheduleManager.cancelAllSchedules();
            }
        })
    }
    
}
