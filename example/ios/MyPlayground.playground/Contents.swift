
import Foundation
import UserNotifications

var date = Date()

var newComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
print(newComponents.debugDescription)



