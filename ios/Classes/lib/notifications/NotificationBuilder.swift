import UserNotifications

public class NotificationBuilder {

    let notificationCenter = UNUserNotificationCenter.current()

    public static func requestPermissions() -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
                return false
            }
        }

        return true
    }

    public func createNotification(pushNotification: PushNotification){

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
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // Notifications not allowed
            }
        }
    }

    private func setNotificationContent(pushNotification: PushNotification, content: UNMutableNotificationContent)  {

        content.title = pushNotification.content.title
        content.body  = pushNotification.content.body

        return intent;
    }

    private func setNotificationActions(pushNotification: PushNotification, content: UNMutableNotificationContent)  {

        if(pushNotification.actionButtons == nil){ return }

        for(Noti)
        let snoozeAction = UNNotificationAction(identifier: "Snooze", title: "Snooze", options: [])
        let deleteAction = UNNotificationAction(identifier: "Delete", title: "Delete", options: [.destructive])

        let category = UNNotificationCategory(identifier: userActions, actions: [snoozeAction, deleteAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([category])
    }
    
}