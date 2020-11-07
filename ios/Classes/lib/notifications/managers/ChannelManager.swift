//
//  ChannelManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 11/09/20.
//

import Foundation

public class ChannelManager {
    
    static let shared:SharedManager = SharedManager(tag: "NotificationChannels")
    
    public static func removeChannel( channelKey:String ) -> Bool {
        return shared.remove(referenceKey: channelKey)
    }
    
    public static func listChannels() -> [NotificationChannelModel] {
        var returnedList:[NotificationChannelModel] = []
        let dataList = shared.getAllObjects()
        
        for data in dataList {
            let channel:NotificationChannelModel = NotificationChannelModel().fromMap(arguments: data) as! NotificationChannelModel
            returnedList.append(channel)
        }
        
        return returnedList
    }
    
    public static func saveChannel(channel:NotificationChannelModel){
        shared.set(channel.toMap(), referenceKey: channel.channelKey!)
    }
    
    public static func getChannelByKey( channelKey:String ) -> NotificationChannelModel? {
        guard let data:[String:Any?] = shared.get(referenceKey: channelKey) else {
          return nil
        }
        return NotificationChannelModel().fromMap(arguments: data) as? NotificationChannelModel
    }
    
    public static func isNotificationChannelActive( channelKey:String ) -> Bool {
        return shared.get(referenceKey: channelKey) != nil
    }
    
}
