//
//  NotificationAttatchment.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 29/08/20.
//

import Foundation

@available(iOS 10.0, *)
extension UNNotificationAttachment {
    
    static func create(imageFileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {

            let fileManager = FileManager.default
            let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
            let fileURLPath      = NSURL(fileURLWithPath: NSTemporaryDirectory())
            let tmpSubFolderURL  = fileURLPath.appendingPathComponent(tmpSubFolderName, isDirectory: true)

            do {
                try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
                let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
                try data.write(to: fileURL!, options: [])
                let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL!, options: options)
                return imageAttachment
            } catch let error {
                print("error \(error)")
            }

        return nil
    }
}
