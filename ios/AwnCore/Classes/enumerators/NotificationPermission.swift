public enum NotificationPermission : String, CaseIterable {
    
    case Alert = "Alert"
    case Sound = "Sound"
    case Badge = "Badge"
    case Vibration = "Vibration"
    case Light = "Light"
    case CriticalAlert = "CriticalAlert"
    case OverrideDnD = "OverrideDnD"
    case Provisional = "Provisional"
    case PreciseAlarms = "PreciseAlarms"
    case FullScreenIntent = "FullScreenIntent"
    case Car = "Car"
        
    static func fromString(_ label: String) -> NotificationPermission? {
        return self.allCases.first{ "\($0)" == label }
    }
}
