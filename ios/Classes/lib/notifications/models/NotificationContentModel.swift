//
//  NotificationContentModel.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 28/08/20.
//

import Foundation

class NotificationContentModel : AbstractModel {

    var id: Int?
    var channelKey: String?
    var title: String?
    var body: String?
    var summary: String?
    var showWhen: Bool?
    
    var actionButtons:[NotificationButtonModel]?
    var payload:[String:String?]?
    
    var playSound: Bool?
    var customSound: String?
    var largeIcon: String?
    var locked: Bool?
    var bigPicture: String?
    var hideLargeIconOnExpand: Bool?
    var autoCancel: Bool?
    var color: Int64?
    var backgroundColor: Int64?
    var progress: Int?
    var ticker: String?

    var privacy: NotificationPrivacy?
    var privateMessage: String?

    var notificationLayout: NotificationLayout?

    var createdSource: NotificationSource?
    var createdLifeCycle: NotificationLifeCycle?
    var displayedLifeCycle: NotificationLifeCycle?
    var createdDate: String?
    var displayedDate: String?
    
    func fromMap(arguments: [String : AnyObject?]) -> AbstractModel {
        <#code#>
    }
    
    func toMap() -> [String : AnyObject?] {
        <#code#>
    }
    
    func validate() throws {
        <#code#>
    }
    
}
