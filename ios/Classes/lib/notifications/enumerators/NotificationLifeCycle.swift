public enum NotificationLifeCycle : String, CaseIterable, AbstractEnum {
    
    case Foreground = "Foreground"
    case Background = "Background"
    case AppKilled = "AppKilled"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
}
