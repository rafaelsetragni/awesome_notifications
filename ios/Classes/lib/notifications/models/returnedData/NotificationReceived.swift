//
//  NotificationReceived.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 05/09/20.
//

import Foundation

public class NotificationReceived : NotificationContentModel {
    
    init(_ contentModel:NotificationContentModel?){
        super.init()
        
        if(contentModel == nil){ return }
        
        self.id = contentModel!.id
        self.channelKey = contentModel!.channelKey
        self.title = contentModel!.title
        self.body = contentModel!.body
        self.summary = contentModel!.summary
        self.showWhen = contentModel!.showWhen
        self.actionButtons = contentModel!.actionButtons
        self.payload = contentModel!.payload
        self.largeIcon = contentModel!.largeIcon
        self.bigPicture = contentModel!.bigPicture
        self.hideLargeIconOnExpand = contentModel!.hideLargeIconOnExpand
        self.autoDismissible = contentModel!.autoDismissible
        self.color = contentModel!.color
        self.progress = contentModel!.progress
        self.ticker = contentModel!.ticker
        self.locked = contentModel!.locked
        
        self.displayOnForeground = contentModel!.displayOnForeground
        self.displayOnBackground = contentModel!.displayOnBackground

        self.notificationLayout = contentModel!.notificationLayout

        self.displayedLifeCycle = contentModel!.displayedLifeCycle
        self.displayedDate = contentModel!.displayedDate

        self.createdSource = contentModel!.createdSource
        self.createdLifeCycle = contentModel!.createdLifeCycle
        self.createdDate = contentModel!.createdDate
    }
    
}
