public enum NotificationPermission : String, CaseIterable {
    
    case Alert = "Alert"
    case Sound = "Sound"
    case Badge = "Badge"
    case CriticalAlert = "CriticalAlert"
    case Provisional = "Provisional"
    case Car = "Car"
        
    static func fromString(_ label: String) -> NotificationPermission? {
        return self.allCases.first{ "\($0)" == label }
    }
}
