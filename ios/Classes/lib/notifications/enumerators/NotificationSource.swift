enum NotificationSource : String, CaseIterable, AbstractEnum {
    
    case Local = "Local"
    case Schedule = "Schedule"
    case Firebase = "Firebase"
    case OneSignal = "OneSignal"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
}
