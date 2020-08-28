enum NotificationSource : String, CaseIterable, AbstractEnum {
    
    static let Local = "Local"
    static let Schedule = "Schedule"
    static let Firebase = "Firebase"
    static let OneSignal = "OneSignal"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
}
