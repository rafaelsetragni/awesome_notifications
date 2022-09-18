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

        let tmpSubFolderName: String = ProcessInfo.processInfo.globallyUniqueString
        let fileURLPath: String = NSTemporaryDirectory()
        let tmpSubFolderURL: String = URL(fileURLWithPath: fileURLPath).appendingPathComponent(tmpSubFolderName).absoluteString

        if ((try? FileManager.default.createDirectory(atPath: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)) != nil) {
            let imageFileIdentifier = UUID().uuidString
            let fileURL = URL(fileURLWithPath: tmpSubFolderURL).appendingPathComponent(imageFileIdentifier)
            data.write(to: fileURL, atomically: true)
            let attachment = try? UNNotificationAttachment(identifier: imageFileIdentifier, url: fileURL, options: options)
            return attachment!
        }
        return nil
    }
}
