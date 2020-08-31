
import UIKit
import UserNotifications

public class NotificationBuilder {
    /*var notificationCenter

    init(){
         = UNUserNotificationCenter.current()
    }
    */
    public static func requestPermissions() -> Bool {
        /*
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        */

        return true
    }
/*
    public func createNotification(pushNotification: PushNotification) -> UNNotification? {

        if(!isAllowedNotification){ return nil }

        let content = UNMutableNotificationContent()

        setNotificationContent(pushNotification: pushNotification, content: content)
        setNotificationActions(pushNotification: pushNotification, content: content)

	    let request = UNNotificationRequest(identifier: pushNotification.content.id.toString(), content: content)
	
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }

    }

    private func isAllowedNotification() -> Bool {
        
        if #available(iOS 10.0, *) {
            
            guard let settings = UIApplication.shared.currentUserNotificationSettings
              else {
                return false
            }
            
            return UIApplication.shared.isRegisteredForRemoteNotifications
              && !settings.types.isEmpty
            
        } else {
            // Fallback on earlier versions
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                return true
            } else {
                return false
            }
        }
    }

    @available(iOS 10.0, *)
    private func setNotificationContent(pushNotification: PushNotification, content: UNMutableNotificationContent)  {

        content.title = pushNotification.content!.title ?? ""
        content.body  = pushNotification.content!.body ?? ""
    }

    @available(iOS 10.0, *)
    private func setNotificationActions(pushNotification: PushNotification, content: UNMutableNotificationContent)  {

        if(pushNotification.actionButtons == nil){ return }

        let snoozeAction = UNNotificationAction(identifier: "Snooze", title: "Snooze", options: [])
        let deleteAction = UNNotificationAction(identifier: "Delete", title: "Delete", options: [.destructive])

        let category = UNNotificationCategory(identifier: userActions, actions: [snoozeAction, deleteAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([category])
    }
    */
}
